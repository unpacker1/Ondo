#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import random
import socket
import ssl
import time
import urllib.parse
import urllib.request
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from datetime import datetime, timezone

APP = "HızlıSetup Global Eye"
DOMAIN = "www.hızlısetup.com"
TIMEOUT = 12

USGS = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson"
ISS = "http://api.open-notify.org/iss-now.json"
GDELT = "https://api.gdeltproject.org/api/v2/doc/doc"


def now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def fetch_json(url, params=None):
    if params:
        url += "?" + urllib.parse.urlencode(params)

    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "HizliSetupGlobalEye/1.0",
            "Accept": "application/json",
        },
    )

    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        return json.loads(r.read().decode("utf-8", "replace"))


def send_json(h, data, code=200):
    raw = json.dumps(data, ensure_ascii=False).encode("utf-8")
    h.send_response(code)
    h.send_header("Content-Type", "application/json; charset=utf-8")
    h.send_header("Cache-Control", "no-store")
    h.send_header("Content-Length", str(len(raw)))
    h.end_headers()
    h.wfile.write(raw)


def send_html(h, data):
    raw = data.encode("utf-8")
    h.send_response(200)
    h.send_header("Content-Type", "text/html; charset=utf-8")
    h.send_header("Cache-Control", "no-store")
    h.send_header("Content-Length", str(len(raw)))
    h.end_headers()
    h.wfile.write(raw)


def clean_host(host):
    host = (host or DOMAIN).strip()
    host = host.replace("https://", "").replace("http://", "")
    host = host.split("/")[0]

    try:
        idna = host.encode("idna").decode("ascii")
    except Exception:
        idna = host

    return host, idna


def domain_check(target):
    display, host = clean_host(target)
    ips = []

    try:
        for item in socket.getaddrinfo(host, None):
            ip = item[4][0]
            if ip not in ips:
                ips.append(ip)
    except Exception:
        pass

    https = {
        "ok": False,
        "error": None,
        "status": None,
        "ms": None
    }

    start = time.time()

    try:
        req = urllib.request.Request(
            "https://" + host + "/",
            headers={"User-Agent": "HizliSetupGlobalEye/1.0"},
        )

        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            https["ok"] = True
            https["status"] = getattr(r, "status", None)
            https["final_url"] = r.geturl()
            https["server"] = r.headers.get("server")

    except Exception as e:
        https["error"] = str(e)

    https["ms"] = int((time.time() - start) * 1000)

    ssl_info = {
        "ok": False,
        "error": None
    }

    try:
        ctx = ssl.create_default_context()

        with socket.create_connection((host, 443), timeout=TIMEOUT) as s:
            with ctx.wrap_socket(s, server_hostname=host) as ss:
                cert = ss.getpeercert()

        exp = cert.get("notAfter")
        issuer = dict(x[0] for x in cert.get("issuer", []) if x)
        subject = dict(x[0] for x in cert.get("subject", []) if x)

        ssl_info = {
            "ok": True,
            "subject": subject.get("commonName"),
            "issuer": issuer.get("commonName"),
            "expires": exp,
        }

    except Exception as e:
        ssl_info["error"] = str(e)

    return {
        "ok": True,
        "target": display,
        "idna": host,
        "ips": ips,
        "https": https,
        "ssl": ssl_info,
        "note": "Bu kontrol pasiftir. Port tarama veya saldırı yapmaz.",
        "updated": now(),
    }


def earthquakes():
    data = fetch_json(USGS)
    events = []

    for f in data.get("features", [])[:250]:
        p = f.get("properties", {})
        g = f.get("geometry", {})
        c = g.get("coordinates") or []

        if len(c) >= 2:
            events.append({
                "title": p.get("title") or "Deprem",
                "place": p.get("place"),
                "mag": p.get("mag"),
                "url": p.get("url"),
                "lon": c[0],
                "lat": c[1],
                "depth": c[2] if len(c) > 2 else None,
            })

    return {
        "ok": True,
        "count": len(events),
        "events": events,
        "updated": now()
    }


def iss():
    data = fetch_json(ISS)
    pos = data.get("iss_position", {})

    return {
        "ok": True,
        "title": "ISS - Uluslararası Uzay İstasyonu",
        "lat": float(pos.get("latitude")),
        "lon": float(pos.get("longitude")),
        "updated": now(),
    }


def news():
    params = {
        "query": "earthquake OR flood OR wildfire OR security OR emergency OR disaster OR deprem OR yangın OR sel",
        "mode": "ArtList",
        "format": "json",
        "maxrecords": "25",
        "sort": "HybridRel",
    }

    data = fetch_json(GDELT, params)
    out = []

    for a in data.get("articles", [])[:25]:
        out.append({
            "title": a.get("title"),
            "url": a.get("url"),
            "domain": a.get("domain"),
            "country": a.get("sourcecountry"),
            "date": a.get("seendate"),
        })

    return {
        "ok": True,
        "count": len(out),
        "articles": out,
        "updated": now()
    }


HTML = r"""
<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>HızlıSetup Global Eye</title>

<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>

<style>
*{box-sizing:border-box}
body{margin:0;background:#07111f;color:#eef7ff;font-family:Arial,Helvetica,sans-serif}
.app{display:grid;grid-template-columns:350px 1fr;height:100vh}
.side{background:#0d1b2f;padding:14px;overflow:auto;border-right:1px solid rgba(255,255,255,.12)}
h1{font-size:22px;margin:0 0 5px}
p{color:#9bb8d8;margin:0 0 12px}
.card{background:#10243d;border:1px solid rgba(255,255,255,.12);border-radius:16px;padding:12px;margin:12px 0}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.stat{background:rgba(255,255,255,.06);border-radius:14px;padding:10px}
.stat b{display:block;font-size:22px}
.stat span{font-size:12px;color:#9bb8d8}
button,input{width:100%;padding:10px;border-radius:12px;border:1px solid rgba(255,255,255,.14);background:#06101d;color:#fff;margin:4px 0}
button{cursor:pointer;background:#17416d;font-weight:bold}
button:hover{background:#20588f}
#map{height:100vh;width:100%}
.item{background:rgba(255,255,255,.06);border-radius:12px;padding:9px;margin:8px 0}
.item a{color:#80dcff;text-decoration:none;font-weight:bold}
.item small{display:block;color:#9bb8d8;margin-top:5px}
pre{white-space:pre-wrap;word-break:break-word;color:#d9efff;font-size:12px}
.warn{color:#ffdca1;font-size:13px;line-height:1.45}
@media(max-width:850px){.app{grid-template-columns:1fr;height:auto}.side{height:auto}#map{height:70vh}}
</style>
</head>

<body>
<div class="app">

<aside class="side">
<h1>🌐 HızlıSetup Global Eye</h1>
<p>Pasif OSINT harita paneli</p>

<div class="card">
<h3>Canlı Özet</h3>
<div class="grid">
<div class="stat"><b id="eqc">-</b><span>Deprem</span></div>
<div class="stat"><b id="newsc">-</b><span>Haber</span></div>
<div class="stat"><b id="isslat">-</b><span>ISS Lat</span></div>
<div class="stat"><b id="isslon">-</b><span>ISS Lon</span></div>
</div>
</div>

<div class="card">
<h3>Kontroller</h3>
<button onclick="refreshAll()">🔄 Verileri yenile</button>
<button onclick="map.setView([20,0],2.5)">🌍 Dünya görünümü</button>
</div>

<div class="card">
<h3>Domain Kontrolü</h3>
<input id="domain" value="www.hızlısetup.com">
<button onclick="checkDomain()">Kontrol et</button>
<pre id="domainOut">Hazır.</pre>
</div>

<div class="card">
<h3>Son Haberler</h3>
<div id="news">Yükleniyor...</div>
</div>

<div class="card">
<div class="warn">
Bu panel saldırı, zafiyet tarama veya izinsiz işlem yapmaz. Sadece açık veri kaynaklarını okur.
</div>
</div>
</aside>

<main>
<div id="map"></div>
</main>

</div>

<script>
const map=L.map("map").setView([20,0],2.5);

L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",{
maxZoom:18,
attribution:"OpenStreetMap"
}).addTo(map);

const eqLayer=L.layerGroup().addTo(map);
const issLayer=L.layerGroup().addTo(map);

async function getj(url){
const r=await fetch(url,{cache:"no-store"});
if(!r.ok)throw new Error("HTTP "+r.status);
return await r.json();
}

function esc(s){
return String(s??"").replace(/[&<>'"]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;","'":"&#039;",'"':"&quot;"}[c]));
}

async function loadEq(){
try{
const d=await getj("/api/earthquakes");
eqLayer.clearLayers();
document.getElementById("eqc").textContent=d.count;

d.events.forEach(e=>{
let mag=Number(e.mag||0);
let color=mag>=5?"#ff4d6d":mag>=3?"#ffd166":"#3ddc97";

let m=L.circleMarker([e.lat,e.lon],{
radius:Math.max(5,Math.min(24,5+mag*4)),
color:color,
fillColor:color,
fillOpacity:.65,
weight:1
}).addTo(eqLayer);

m.bindPopup(
`<b>${esc(e.title)}</b><br>
<small>Büyüklük: ${esc(e.mag)}</small><br>
<small>Derinlik: ${esc(e.depth)} km</small><br>
<a target="_blank" href="${e.url}">Kaynak</a>`
);
});
}catch(e){console.log(e)}
}

async function loadIss(){
try{
const d=await getj("/api/iss");
issLayer.clearLayers();

document.getElementById("isslat").textContent=d.lat.toFixed(2);
document.getElementById("isslon").textContent=d.lon.toFixed(2);

L.marker([d.lat,d.lon])
.addTo(issLayer)
.bindPopup(`<b>${esc(d.title)}</b><br>${d.lat.toFixed(4)}, ${d.lon.toFixed(4)}`);

}catch(e){console.log(e)}
}

async function loadNews(){
try{
const d=await getj("/api/news");
document.getElementById("newsc").textContent=d.count;

let html="";

d.articles.forEach(a=>{
html+=`<div class="item">
<a target="_blank" href="${a.url}">${esc(a.title)}</a>
<small>${esc(a.domain)} • ${esc(a.country)} • ${esc(a.date)}</small>
</div>`;
});

document.getElementById("news").innerHTML=html||"Haber bulunamadı.";

}catch(e){
document.getElementById("news").textContent="Haber alınamadı.";
}
}

async function checkDomain(){
let target=document.getElementById("domain").value;
let out=document.getElementById("domainOut");

out.textContent="Kontrol ediliyor...";

try{
let d=await getj("/api/domain?target="+encodeURIComponent(target));
out.textContent=JSON.stringify(d,null,2);
}catch(e){
out.textContent="Hata: "+e.message;
}
}

async function refreshAll(){
await Promise.allSettled([
loadEq(),
loadIss(),
loadNews()
]);
}

refreshAll();
checkDomain();

setInterval(loadIss,10000);
setInterval(loadEq,300000);
setInterval(loadNews,600000);
</script>

</body>
</html>
"""


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print("[%s] %s" % (self.log_date_time_string(), fmt % args))

    def do_GET(self):
        p = urllib.parse.urlparse(self.path)
        q = urllib.parse.parse_qs(p.query)

        try:
            if p.path in ["/", "/index.html"]:
                send_html(self, HTML)

            elif p.path == "/api/earthquakes":
                send_json(self, earthquakes())

            elif p.path == "/api/iss":
                send_json(self, iss())

            elif p.path == "/api/news":
                send_json(self, news())

            elif p.path == "/api/domain":
                target = (q.get("target") or [DOMAIN])[0]
                send_json(self, domain_check(target))

            else:
                send_json(self, {"ok": False, "error": "Bulunamadı"}, 404)

        except Exception as e:
            send_json(self, {"ok": False, "error": str(e)}, 500)


def find_port():
    for _ in range(50):
        port = random.randint(41000, 62000)

        try:
            s = socket.socket()
            s.bind(("127.0.0.1", port))
            s.close()
            return port

        except OSError:
            pass

    return 8080


def main():
    port = find_port()
    url = "http://127.0.0.1:%s" % port

    print("=" * 55)
    print(APP)
    print("Panel açıldı:", url)
    print("Durdurmak için: CTRL + C")
    print("=" * 55)

    try:
        webbrowser.open(url)
    except Exception:
        pass

    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()


if __name__ == "__main__":
    main()