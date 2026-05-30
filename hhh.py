#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HızlıSetup Global Eye v1
Güvenli/Pasif OSINT Harita Paneli

Özellikler:
- Termux, Linux, macOS, Windows üzerinde Python 3 ile çalışır.
- Dışa saldırı, port tarama veya güvenlik açığı taraması yapmaz.
- Açık veri kaynaklarını okur:
  - USGS Depremler
  - Open Notify ISS canlı konum
  - GDELT haberleri
- Kendi alan adın için pasif DNS/HTTPS/SSL sağlık kontrolü yapar.

Çalıştırma:
    python hizlisetup_global_eye.py

Termux kurulum:
    pkg update -y
    pkg install python -y
    python hizlisetup_global_eye.py
"""

from __future__ import annotations

import datetime as _dt
import json
import random
import socket
import ssl
import sys
import time
import traceback
import urllib.error
import urllib.parse
import urllib.request
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any, Dict, List, Optional, Tuple


APP_NAME = "HızlıSetup Global Eye"
APP_VERSION = "1.0"
DEFAULT_DOMAIN = "www.hızlısetup.com"
USER_AGENT = "HizliSetupGlobalEye/1.0 passive-osint-dashboard"
REQUEST_TIMEOUT = 12

USGS_ALL_DAY = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson"
OPEN_NOTIFY_ISS = "http://api.open-notify.org/iss-now.json"
GDELT_DOC = "https://api.gdeltproject.org/api/v2/doc/doc"


def now_iso() -> str:
    return _dt.datetime.now(_dt.timezone.utc).isoformat(timespec="seconds")


def json_response(handler: BaseHTTPRequestHandler, data: Any, status: int = 200) -> None:
    payload = json.dumps(data, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Cache-Control", "no-store")
    handler.send_header("Content-Length", str(len(payload)))
    handler.end_headers()
    handler.wfile.write(payload)


def html_response(handler: BaseHTTPRequestHandler, html: str, status: int = 200) -> None:
    payload = html.encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "text/html; charset=utf-8")
    handler.send_header("Cache-Control", "no-store")
    handler.send_header("Content-Length", str(len(payload)))
    handler.end_headers()
    handler.wfile.write(payload)


def fetch_json(
    url: str,
    params: Optional[Dict[str, str]] = None,
    timeout: int = REQUEST_TIMEOUT
) -> Dict[str, Any]:
    if params:
        query = urllib.parse.urlencode(params)
        sep = "&" if "?" in url else "?"
        url = f"{url}{sep}{query}"

    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": USER_AGENT,
            "Accept": "application/json"
        }
    )

    with urllib.request.urlopen(req, timeout=timeout) as resp:
        raw = resp.read(4 * 1024 * 1024)

    return json.loads(raw.decode("utf-8", errors="replace"))


def normalize_target(target: str) -> Tuple[str, str]:
    cleaned = (target or DEFAULT_DOMAIN).strip()
    cleaned = cleaned.replace("https://", "").replace("http://", "").split("/")[0].strip()

    if not cleaned:
        cleaned = DEFAULT_DOMAIN

    try:
        idna = cleaned.encode("idna").decode("ascii")
    except Exception:
        idna = cleaned

    return cleaned, idna


def resolve_ips(host: str) -> List[str]:
    ips: List[str] = []

    try:
        infos = socket.getaddrinfo(host, None)

        for info in infos:
            ip = info[4][0]
            if ip not in ips:
                ips.append(ip)

    except Exception:
        pass

    return ips


def https_check(host: str) -> Dict[str, Any]:
    result: Dict[str, Any] = {
        "ok": False,
        "status": None,
        "elapsed_ms": None,
        "error": None
    }

    url = f"https://{host}/"
    start = time.time()

    try:
        req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})

        with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as resp:
            result["status"] = getattr(resp, "status", None)
            result["final_url"] = resp.geturl()
            result["server"] = resp.headers.get("server")
            result["content_type"] = resp.headers.get("content-type")
            result["ok"] = True

    except Exception as exc:
        result["error"] = str(exc)

    finally:
        result["elapsed_ms"] = int((time.time() - start) * 1000)

    return result


def ssl_info(host: str) -> Dict[str, Any]:
    info: Dict[str, Any] = {
        "ok": False,
        "error": None
    }

    try:
        ctx = ssl.create_default_context()

        with socket.create_connection((host, 443), timeout=REQUEST_TIMEOUT) as sock:
            with ctx.wrap_socket(sock, server_hostname=host) as ssock:
                cert = ssock.getpeercert()

        not_after = cert.get("notAfter")
        expires = None
        days_left = None

        if not_after:
            expires_dt = _dt.datetime.strptime(
                not_after,
                "%b %d %H:%M:%S %Y %Z"
            ).replace(tzinfo=_dt.timezone.utc)

            expires = expires_dt.isoformat(timespec="seconds")
            days_left = (expires_dt - _dt.datetime.now(_dt.timezone.utc)).days

        subject = dict(x[0] for x in cert.get("subject", []) if x)
        issuer = dict(x[0] for x in cert.get("issuer", []) if x)

        info.update({
            "ok": True,
            "subject_cn": subject.get("commonName"),
            "issuer_cn": issuer.get("commonName"),
            "expires": expires,
            "days_left": days_left
        })

    except Exception as exc:
        info["error"] = str(exc)

    return info


def get_earthquakes() -> Dict[str, Any]:
    data = fetch_json(USGS_ALL_DAY)
    features = data.get("features", [])[:300]
    events = []

    for f in features:
        props = f.get("properties", {}) or {}
        geom = f.get("geometry", {}) or {}
        coords = geom.get("coordinates") or []

        if len(coords) < 2:
            continue

        events.append({
            "id": f.get("id"),
            "type": "earthquake",
            "title": props.get("title") or props.get("place") or "Deprem",
            "place": props.get("place"),
            "mag": props.get("mag"),
            "time": props.get("time"),
            "url": props.get("url"),
            "lon": coords[0],
            "lat": coords[1],
            "depth_km": coords[2] if len(coords) > 2 else None
        })

    return {
        "ok": True,
        "updated": now_iso(),
        "count": len(events),
        "events": events
    }


def get_iss() -> Dict[str, Any]:
    data = fetch_json(OPEN_NOTIFY_ISS)
    pos = data.get("iss_position", {}) or {}

    lat = float(pos.get("latitude"))
    lon = float(pos.get("longitude"))

    return {
        "ok": data.get("message") == "success",
        "updated": now_iso(),
        "timestamp": data.get("timestamp"),
        "lat": lat,
        "lon": lon,
        "title": "ISS - Uluslararası Uzay İstasyonu"
    }


def get_news() -> Dict[str, Any]:
    query = (
        '(earthquake OR flood OR wildfire OR "cyber attack" OR security '
        'OR conflict OR emergency OR disaster OR deprem OR yangın OR sel)'
    )

    params = {
        "query": query,
        "mode": "ArtList",
        "format": "json",
        "maxrecords": "30",
        "sort": "HybridRel"
    }

    data = fetch_json(GDELT_DOC, params=params)
    articles = []

    for item in (data.get("articles") or [])[:30]:
        articles.append({
            "title": item.get("title"),
            "url": item.get("url"),
            "domain": item.get("domain"),
            "sourcecountry": item.get("sourcecountry"),
            "language": item.get("language"),
            "seendate": item.get("seendate"),
            "image": item.get("socialimage")
        })

    return {
        "ok": True,
        "updated": now_iso(),
        "count": len(articles),
        "articles": articles
    }


def domain_report(target: str) -> Dict[str, Any]:
    display_host, idna_host = normalize_target(target)
    ips = resolve_ips(idna_host)

    return {
        "ok": True,
        "updated": now_iso(),
        "target": display_host,
        "idna": idna_host,
        "ips": ips,
        "https": https_check(idna_host),
        "ssl": ssl_info(idna_host),
        "note": "Bu modül pasif sağlık kontrolüdür; port/vuln taraması yapmaz."
    }


INDEX_HTML = r'''<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>HızlıSetup Global Eye</title>

<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />

<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>

<style>
:root {
  --bg: #07111f;
  --panel: #0d1b2f;
  --panel2: #10243d;
  --muted: #8fb0d1;
  --text: #eef7ff;
  --blue: #2f8cff;
  --cyan: #36d8ff;
  --red: #ff4d6d;
  --yellow: #ffd166;
  --green: #3ddc97;
  --line: rgba(255,255,255,.12);
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  background: radial-gradient(circle at 20% 0%, #123960, #07111f 44%, #030914);
  font-family: Arial, Helvetica, sans-serif;
  color: var(--text);
  overflow: hidden;
}

.app {
  display: grid;
  grid-template-columns: 360px 1fr;
  height: 100vh;
  width: 100vw;
}

.sidebar {
  background: linear-gradient(180deg, rgba(13,27,47,.98), rgba(6,14,26,.98));
  border-right: 1px solid var(--line);
  padding: 14px;
  overflow: auto;
  box-shadow: 14px 0 40px rgba(0,0,0,.25);
  z-index: 5;
}

.brand {
  display: flex;
  gap: 12px;
  align-items: center;
  margin: 4px 0 14px;
}

.logo {
  width: 46px;
  height: 46px;
  border-radius: 14px;
  background: linear-gradient(135deg, var(--blue), var(--cyan));
  display: grid;
  place-items: center;
  font-weight: 900;
  color: #03101f;
  box-shadow: 0 10px 28px rgba(47,140,255,.35);
}

.brand h1 {
  font-size: 20px;
  margin: 0;
}

.brand p {
  margin: 4px 0 0;
  color: var(--muted);
  font-size: 12px;
}

.card {
  background: rgba(16,36,61,.78);
  border: 1px solid var(--line);
  border-radius: 18px;
  padding: 12px;
  margin: 12px 0;
  backdrop-filter: blur(10px);
}

.card h2 {
  font-size: 14px;
  margin: 0 0 10px;
  letter-spacing: .2px;
}

.grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}

.stat {
  border: 1px solid var(--line);
  border-radius: 14px;
  padding: 10px;
  background: rgba(255,255,255,.045);
}

.stat b {
  display: block;
  font-size: 22px;
}

.stat span {
  font-size: 11px;
  color: var(--muted);
}

.btn {
  width: 100%;
  border: 1px solid var(--line);
  background: rgba(47,140,255,.15);
  color: var(--text);
  border-radius: 14px;
  padding: 10px 12px;
  margin: 5px 0;
  cursor: pointer;
  text-align: left;
  font-weight: 700;
}

.btn:hover {
  background: rgba(47,140,255,.28);
}

.btn.small {
  font-size: 12px;
  text-align: center;
  padding: 9px;
}

.btn.active {
  border-color: rgba(54,216,255,.75);
  box-shadow: 0 0 0 2px rgba(54,216,255,.13) inset;
}

.danger {
  background: rgba(255,77,109,.14);
}

.inputrow {
  display: flex;
  gap: 8px;
}

input {
  width: 100%;
  background: #06101d;
  color: var(--text);
  border: 1px solid var(--line);
  border-radius: 12px;
  padding: 10px;
  outline: none;
}

.list {
  display: flex;
  flex-direction: column;
  gap: 9px;
  max-height: 280px;
  overflow: auto;
}

.item {
  border: 1px solid var(--line);
  background: rgba(255,255,255,.045);
  border-radius: 14px;
  padding: 10px;
}

.item a {
  color: #9bdcff;
  text-decoration: none;
  font-weight: 700;
}

.item small {
  display: block;
  color: var(--muted);
  margin-top: 6px;
  line-height: 1.35;
}

.mono {
  font-family: ui-monospace, Consolas, monospace;
  font-size: 12px;
  white-space: pre-wrap;
  word-break: break-word;
  color: #cde8ff;
}

.mapwrap {
  position: relative;
}

.topbar {
  position: absolute;
  top: 12px;
  left: 12px;
  right: 12px;
  z-index: 4;
  display: flex;
  gap: 8px;
  align-items: center;
  pointer-events: none;
}

.pill {
  pointer-events: auto;
  background: rgba(7,17,31,.78);
  border: 1px solid var(--line);
  border-radius: 999px;
  padding: 9px 12px;
  color: #d9efff;
  box-shadow: 0 12px 30px rgba(0,0,0,.25);
  backdrop-filter: blur(10px);
  font-size: 13px;
}

.pill strong {
  color: #fff;
}

.map {
  height: 100vh;
  width: 100%;
}

.leaflet-popup-content-wrapper,
.leaflet-popup-tip {
  background: #081526;
  color: #eef7ff;
}

.leaflet-container a {
  color: #7bdcff;
}

.legend {
  position: absolute;
  right: 12px;
  bottom: 20px;
  z-index: 4;
  background: rgba(7,17,31,.82);
  border: 1px solid var(--line);
  border-radius: 16px;
  padding: 10px 12px;
  font-size: 12px;
  backdrop-filter: blur(10px);
}

.dot {
  display: inline-block;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  margin-right: 6px;
}

.eq {
  background: var(--red);
}

.iss {
  background: var(--cyan);
}

.night {
  background: #1b2544;
}

.warn {
  font-size: 12px;
  color: #ffdca1;
  line-height: 1.45;
}

.footer {
  font-size: 11px;
  color: var(--muted);
  line-height: 1.45;
  margin: 12px 0 5px;
}

@media(max-width: 840px) {
  body {
    overflow: auto;
  }

  .app {
    grid-template-columns: 1fr;
    height: auto;
  }

  .sidebar {
    height: auto;
    max-height: none;
  }

  .map {
    height: 68vh;
  }

  .topbar {
    top: 8px;
    left: 8px;
    right: 8px;
    flex-wrap: wrap;
  }

  .pill {
    font-size: 12px;
    padding: 8px 10px;
  }

  .legend {
    bottom: 10px;
    right: 8px;
  }

  .list {
    max-height: 220px;
  }
}
</style>
</head>

<body>
<div class="app">

  <aside class="sidebar">

    <div class="brand">
      <div class="logo">HS</div>
      <div>
        <h1>HızlıSetup Global Eye</h1>
        <p>Pasif OSINT • Harita • Haber • Deprem • ISS</p>
      </div>
    </div>

    <div class="card">
      <h2>Canlı Özet</h2>
      <div class="grid">
        <div class="stat">
          <b id="eqCount">-</b>
          <span>Deprem / 24s</span>
        </div>
        <div class="stat">
          <b id="newsCount">-</b>
          <span>Haber</span>
        </div>
        <div class="stat">
          <b id="issLat">-</b>
          <span>ISS Enlem</span>
        </div>
        <div class="stat">
          <b id="issLon">-</b>
          <span>ISS Boylam</span>
        </div>
      </div>
    </div>

    <div class="card">
      <h2>Katmanlar</h2>
      <button id="btnEq" class="btn active" onclick="toggleLayer('eq')">🌍 Depremler</button>
      <button id="btnIss" class="btn active" onclick="toggleLayer('iss')">🛰️ ISS Konumu</button>
      <button id="btnNight" class="btn active" onclick="toggleLayer('night')">🌗 Gündüz / Gece Yaklaşık</button>
      <button class="btn" onclick="refreshAll()">🔄 Verileri Yenile</button>
    </div>

    <div class="card">
      <h2>Domain Sağlık Kontrolü</h2>
      <div class="inputrow">
        <input id="domainInput" value="www.hızlısetup.com" />
        <button class="btn small" onclick="checkDomain()">Kontrol</button>
      </div>
      <div id="domainResult" class="mono" style="margin-top:10px">Hazır.</div>
    </div>

    <div class="card">
      <h2>Son Açık Kaynak Haberleri</h2>
      <div id="newsList" class="list">
        <div class="item">
          <small>Yükleniyor...</small>
        </div>
      </div>
    </div>

    <div class="card danger">
      <h2>Güvenli Kullanım</h2>
      <div class="warn">
        Bu sürüm saldırı, port tarama, zafiyet tarama veya veri sızıntısı arama yapmaz.
        Sadece açık kaynak veri okur ve kendi domainin için pasif kontrol yapar.
      </div>
    </div>

    <div class="footer">
      v1.0 • Yerel panel cihazında çalışır. Harita ve veri kaynakları için internet gerekir.
    </div>

  </aside>

  <main class="mapwrap">
    <div class="topbar">
      <div class="pill"><strong>Durum:</strong> <span id="status">Başlatılıyor</span></div>
      <div class="pill"><strong>UTC:</strong> <span id="utcClock">-</span></div>
      <div class="pill"><strong>Merkez:</strong> Dünya görünümü</div>
    </div>

    <div id="map" class="map"></div>

    <div class="legend">
      <div><span class="dot eq"></span>Deprem</div>
      <div><span class="dot iss"></span>ISS</div>
      <div><span class="dot night"></span>Yaklaşık gece alanı</div>
    </div>
  </main>

</div>

<script>
const map = L.map('map', {
  worldCopyJump: true,
  zoomControl: true
}).setView([20, 0], 2.5);

L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  maxZoom: 18,
  attribution: '&copy; OpenStreetMap'
}).addTo(map);

let eqLayer = L.layerGroup().addTo(map);
let issLayer = L.layerGroup().addTo(map);
let nightLayer = L.layerGroup().addTo(map);

let layers = {
  eq: true,
  iss: true,
  night: true
};

let issMarker = null;

function setStatus(s) {
  document.getElementById('status').textContent = s;
}

function fmt(n, d = 2) {
  return Number(n).toFixed(d);
}

function utcTick() {
  document.getElementById('utcClock').textContent =
    new Date().toISOString().replace('T', ' ').slice(0, 19);
}

setInterval(utcTick, 1000);
utcTick();

function escapeHtml(s) {
  return String(s ?? '').replace(/[&<>'"]/g, function(c) {
    return {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      "'": '&#039;',
      '"': '&quot;'
    }[c];
  });
}

function popupHtml(title, rows, url) {
  let h = `<b>${escapeHtml(title || 'Olay')}</b>`;

  rows.forEach(function(r) {
    h += `<br><small>${escapeHtml(r)}</small>`;
  });

  if (url) {
    h += `<br><a target="_blank" href="${url}">Kaynağı aç</a>`;
  }

  return h;
}

async function jget(url) {
  const r = await fetch(url, {
    cache: 'no-store'
  });

  if (!r.ok) {
    throw new Error('HTTP ' + r.status);
  }

  return await r.json();
}

async function loadEarthquakes() {
  try {
    const data = await jget('/api/earthquakes');

    eqLayer.clearLayers();

    data.events.forEach(function(e) {
      const mag = Number(e.mag || 0);
      const radius = Math.max(5, Math.min(26, 5 + mag * 4));

      const color =
        mag >= 5 ? '#ff4d6d' :
        mag >= 3 ? '#ffd166' :
        '#3ddc97';

      const marker = L.circleMarker([e.lat, e.lon], {
        radius: radius,
        color: color,
        fillColor: color,
        fillOpacity: .62,
        weight: 1
      });

      marker.bindPopup(
        popupHtml(
          e.title,
          [
            `Büyüklük: ${e.mag ?? '-'}`,
            `Derinlik: ${e.depth_km ?? '-'} km`,
            e.place || ''
          ],
          e.url
        )
      );

      marker.addTo(eqLayer);
    });

    document.getElementById('eqCount').textContent = data.count;

  } catch (err) {
    console.error(err);
    setStatus('Deprem verisi alınamadı');
  }
}

async function loadISS() {
  try {
    const data = await jget('/api/iss');

    issLayer.clearLayers();

    const icon = L.divIcon({
      className: '',
      html: '<div style="width:24px;height:24px;border-radius:50%;background:#36d8ff;border:3px solid white;box-shadow:0 0 24px #36d8ff"></div>',
      iconSize: [24, 24],
      iconAnchor: [12, 12]
    });

    issMarker = L.marker([data.lat, data.lon], {
      icon: icon
    }).bindPopup(
      popupHtml(
        data.title,
        [
          `Lat: ${fmt(data.lat, 4)}`,
          `Lon: ${fmt(data.lon, 4)}`,
          `Zaman: ${data.timestamp || '-'}`
        ]
      )
    );

    issMarker.addTo(issLayer);

    document.getElementById('issLat').textContent = fmt(data.lat, 2);
    document.getElementById('issLon').textContent = fmt(data.lon, 2);

  } catch (err) {
    console.error(err);
    setStatus('ISS verisi alınamadı');
  }
}

async function loadNews() {
  try {
    const data = await jget('/api/news');

    document.getElementById('newsCount').textContent = data.count;

    const box = document.getElementById('newsList');
    box.innerHTML = '';

    data.articles.forEach(function(a) {
      const div = document.createElement('div');
      div.className = 'item';

      const title = escapeHtml(a.title || 'Başlıksız haber');
      const url = a.url || '#';

      div.innerHTML =
        `<a target="_blank" href="${url}">${title}</a>` +
        `<small>${escapeHtml(a.domain || '')} • ${escapeHtml(a.sourcecountry || '')} • ${escapeHtml(a.seendate || '')}</small>`;

      box.appendChild(div);
    });

    if (!data.articles.length) {
      box.innerHTML = '<div class="item"><small>Haber bulunamadı.</small></div>';
    }

  } catch (err) {
    console.error(err);
    document.getElementById('newsList').innerHTML =
      '<div class="item"><small>Haber verisi alınamadı.</small></div>';
  }
}

function drawNight() {
  nightLayer.clearLayers();

  const now = new Date();
  const utcHours = now.getUTCHours() + now.getUTCMinutes() / 60;

  const sunLon = 180 - utcHours * 15;
  const nightCenter = ((sunLon + 180 + 540) % 360) - 180;

  let west = nightCenter - 90;
  let east = nightCenter + 90;

  const polys = [];

  function rect(w, e) {
    return [
      [-85, w],
      [85, w],
      [85, e],
      [-85, e]
    ];
  }

  if (west < -180) {
    polys.push(rect(west + 360, 180));
    polys.push(rect(-180, east));
  } else if (east > 180) {
    polys.push(rect(west, 180));
    polys.push(rect(-180, east - 360));
  } else {
    polys.push(rect(west, east));
  }

  polys.forEach(function(p) {
    L.polygon(p, {
      color: '#1b2544',
      weight: 0,
      fillColor: '#1b2544',
      fillOpacity: .28,
      interactive: false
    }).addTo(nightLayer);
  });
}

setInterval(function() {
  if (layers.night) {
    drawNight();
  }
}, 60000);

function toggleLayer(name) {
  layers[name] = !layers[name];

  const obj =
    name === 'eq' ? eqLayer :
    name === 'iss' ? issLayer :
    nightLayer;

  const btn =
    document.getElementById('btn' + name.charAt(0).toUpperCase() + name.slice(1));

  if (layers[name]) {
    obj.addTo(map);
    btn.classList.add('active');

    if (name === 'night') {
      drawNight();
    }

  } else {
    map.removeLayer(obj);
    btn.classList.remove('active');
  }
}

async function checkDomain() {
  const target = document.getElementById('domainInput').value;
  const out = document.getElementById('domainResult');

  out.textContent = 'Kontrol ediliyor...';

  try {
    const data = await jget('/api/domain?target=' + encodeURIComponent(target));
    out.textContent = JSON.stringify(data, null, 2);
  } catch (err) {
    out.textContent = 'Hata: ' + err.message;
  }
}

async function refreshAll() {
  setStatus('Veriler yenileniyor...');

  await Promise.allSettled([
    loadEarthquakes(),
    loadISS(),
    loadNews()
  ]);

  if (layers.night) {
    drawNight();
  }

  setStatus('Hazır');
}

refreshAll();

setInterval(loadISS, 10000);
setInterval(loadEarthquakes, 5 * 60 * 1000);
setInterval(loadNews, 10 * 60 * 1000);

checkDomain();
</script>
</body>
</html>'''


class Handler(BaseHTTPRequestHandler):
    server_version = f"HizliSetupGlobalEye/{APP_VERSION}"

    def log_message(self, fmt: str, *args: Any) -> None:
        sys.stdout.write("[%s] %s\n" % (self.log_date_time_string(), fmt % args))

    def do_GET(self) -> None:
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        qs = urllib.parse.parse_qs(parsed.query)

        try:
            if path == "/" or path == "/index.html":
                html_response(self, INDEX_HTML)

            elif path == "/api/status":
                json_response(self, {
                    "ok": True,
                    "app": APP_NAME,
                    "version": APP_VERSION,
                    "time": now_iso()
                })

            elif path == "/api/earthquakes":
                json_response(self, get_earthquakes())

            elif path == "/api/iss":
                json_response(self, get_iss())

            elif path == "/api/news":
                json_response(self, get_news())

            elif path == "/api/domain":
                target = (qs.get("target") or [DEFAULT_DOMAIN])[0]
                json_response(self, domain_report(target))

            else:
                json_response(self, {
                    "ok": False,
                    "error": "Not found"
                }, 404)

        except urllib.error.HTTPError as exc:
            json_response(self, {
                "ok": False,
                "error": f"HTTPError: {exc.code} {exc.reason}",
                "path": path
            }, 502)

        except Exception as exc:
            json_response(self, {
                "ok": False,
                "error": str(exc),
                "trace": traceback.format_exc(limit=2)
            }, 500)


def find_port() -> int:
    for _ in range(50):
        port = random.randint(41000, 62000)

        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            try:
                s.bind(("127.0.0.1", port))
                return port
            except OSError:
                continue

    return 8080


def main() -> None:
    port = find_port()
    server = ThreadingHTTPServer(("0.0.0.0", port), Handler)

    local_url = f"http://127.0.0.1:{port}"
    lan_url = f"http://0.0.0.0:{port}"

    print("\n" + "=" * 64)
    print(f" {APP_NAME} v{APP_VERSION}")
    print(" Güvenli/Pasif OSINT harita paneli başlatıldı")
    print(f" Yerel adres : {local_url}")
    print(f" Ağ adresi   : {lan_url}")
    print(" Durdurmak için CTRL + C")
    print("=" * 64 + "\n")

    try:
        try:
            webbrowser.open(local_url)
        except Exception:
            pass

        server.serve_forever()

    except KeyboardInterrupt:
        print("\nPanel kapatılıyor...")

    finally:
        server.server_close()


if __name__ == "__main__":
    main()