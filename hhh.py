#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Termux Uyumlu Güvenli OSINT Paneli
Tek dosya Python web panelidir.

Kapsam:
- Domain / IP RDAP sorgusu
- DNS kayıtları
- HTTP header analizi
- SSL sertifika özeti
- crt.sh üzerinden pasif subdomain keşfi
- robots.txt ve sitemap.xml kontrolü
- Public IP bilgisi
- URL yönlendirme zinciri
- E-posta header analizi
- IOC çıkarıcı
- Hash türü tahmini

Çalıştır:
    python osint_panel.py

Aynı Wi-Fi ağında açmak için:
    python osint_panel.py --public
"""

import argparse
import base64
import email
import hashlib
import html
import ipaddress
import json
import random
import re
import socket
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


APP_NAME = "Termux OSINT Panel"
VERSION = "1.0-safe"


# ---------------------------------------------------------
# Yardımcı fonksiyonlar
# ---------------------------------------------------------

def now():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def clean_text(value, limit=5000):
    if value is None:
        return ""
    value = str(value).strip()
    if len(value) > limit:
        value = value[:limit]
    return value


def json_response(handler, data, status=200):
    body = json.dumps(data, ensure_ascii=False, indent=2).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


def html_response(handler, content, status=200):
    body = content.encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "text/html; charset=utf-8")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


def fetch_url(url, timeout=12, headers=None, max_bytes=2_000_000):
    headers = headers or {}
    default_headers = {
        "User-Agent": f"{APP_NAME}/{VERSION} Python-Termux",
        "Accept": "*/*",
    }
    default_headers.update(headers)

    req = urllib.request.Request(url, headers=default_headers)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read(max_bytes)
            return {
                "ok": True,
                "url": resp.geturl(),
                "status": getattr(resp, "status", None),
                "headers": dict(resp.headers),
                "text": raw.decode("utf-8", errors="replace"),
                "bytes": len(raw),
            }
    except urllib.error.HTTPError as e:
        try:
            raw = e.read(max_bytes)
            text = raw.decode("utf-8", errors="replace")
        except Exception:
            text = ""
        return {
            "ok": False,
            "url": url,
            "status": e.code,
            "headers": dict(e.headers),
            "text": text,
            "error": str(e),
        }
    except Exception as e:
        return {
            "ok": False,
            "url": url,
            "status": None,
            "headers": {},
            "text": "",
            "error": str(e),
        }


def normalize_domain(value):
    value = clean_text(value, 300).lower()
    value = value.replace("http://", "").replace("https://", "")
    value = value.split("/")[0]
    value = value.split("?")[0]
    value = value.split("#")[0]
    value = value.strip(". ")
    if ":" in value and not is_ip(value):
        value = value.split(":")[0]
    return value


def normalize_url(value):
    value = clean_text(value, 1000)
    if not value.startswith(("http://", "https://")):
        value = "https://" + value
    return value


def is_ip(value):
    try:
        ipaddress.ip_address(value)
        return True
    except Exception:
        return False


def is_domain(value):
    value = normalize_domain(value)
    if len(value) < 3 or len(value) > 253:
        return False
    pattern = r"^(?=.{3,253}$)([a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$"
    return re.match(pattern, value) is not None


def pretty_json(obj):
    return json.dumps(obj, ensure_ascii=False, indent=2)


def safe_error(message):
    return {"error": str(message)}


# ---------------------------------------------------------
# OSINT Modülleri
# ---------------------------------------------------------

def module_rdap(target):
    target = normalize_domain(target)

    if not target:
        return safe_error("Hedef boş.")

    if is_ip(target):
        url = f"https://rdap.org/ip/{urllib.parse.quote(target)}"
    elif is_domain(target):
        url = f"https://rdap.org/domain/{urllib.parse.quote(target)}"
    else:
        return safe_error("Geçerli domain veya IP gir.")

    result = fetch_url(url)
    if not result["ok"]:
        return {
            "source": url,
            "status": result.get("status"),
            "error": result.get("error") or "RDAP cevabı alınamadı.",
            "raw": result.get("text", "")[:2000],
        }

    try:
        data = json.loads(result["text"])
    except Exception:
        return {
            "source": url,
            "error": "RDAP cevabı JSON olarak çözülemedi.",
            "raw": result["text"][:2000],
        }

    summary = {
        "source": url,
        "objectClassName": data.get("objectClassName"),
        "handle": data.get("handle"),
        "ldhName": data.get("ldhName"),
        "name": data.get("name"),
        "status": data.get("status"),
        "events": data.get("events"),
        "nameservers": data.get("nameservers"),
        "links": data.get("links"),
        "notices": data.get("notices"),
    }

    return summary


def module_dns(target):
    domain = normalize_domain(target)
    if not is_domain(domain):
        return safe_error("DNS için geçerli domain gir.")

    output = {
        "domain": domain,
        "method": None,
        "records": {},
        "note": None,
    }

    try:
        import dns.resolver  # type: ignore
        output["method"] = "dnspython"

        resolver = dns.resolver.Resolver()
        resolver.lifetime = 8
        resolver.timeout = 4

        record_types = ["A", "AAAA", "MX", "NS", "TXT", "CNAME", "SOA", "CAA"]

        for rtype in record_types:
            try:
                answers = resolver.resolve(domain, rtype)
                values = []
                for item in answers:
                    values.append(str(item).strip())
                output["records"][rtype] = values
            except Exception as e:
                output["records"][rtype] = []

        return output

    except Exception:
        output["method"] = "socket"
        output["note"] = "Gelişmiş DNS kayıtları için Termux'ta şu komutu kullanabilirsin: pip install dnspython"

        try:
            ipv4 = socket.gethostbyname_ex(domain)
            output["records"]["A"] = ipv4[2]
        except Exception as e:
            output["records"]["A"] = []

        try:
            infos = socket.getaddrinfo(domain, None, socket.AF_INET6)
            ipv6s = sorted(set([i[4][0] for i in infos]))
            output["records"]["AAAA"] = ipv6s
        except Exception:
            output["records"]["AAAA"] = []

        return output


def module_http_headers(target):
    url = normalize_url(target)
    result = fetch_url(url, timeout=12)

    headers = result.get("headers", {})
    security_headers = {
        "strict-transport-security": headers.get("Strict-Transport-Security"),
        "content-security-policy": headers.get("Content-Security-Policy"),
        "x-frame-options": headers.get("X-Frame-Options"),
        "x-content-type-options": headers.get("X-Content-Type-Options"),
        "referrer-policy": headers.get("Referrer-Policy"),
        "permissions-policy": headers.get("Permissions-Policy"),
    }

    missing = [k for k, v in security_headers.items() if not v]

    return {
        "requested_url": url,
        "final_url": result.get("url"),
        "ok": result.get("ok"),
        "status": result.get("status"),
        "headers": headers,
        "security_headers": security_headers,
        "missing_security_headers": missing,
        "error": result.get("error"),
    }


def module_ssl(target):
    domain = normalize_domain(target)
    if not domain:
        return safe_error("SSL için domain gir.")

    if is_ip(domain):
        host = domain
    elif is_domain(domain):
        host = domain
    else:
        return safe_error("Geçerli domain veya IP gir.")

    port = 443
    ctx = ssl.create_default_context()

    try:
        with socket.create_connection((host, port), timeout=10) as sock:
            with ctx.wrap_socket(sock, server_hostname=host if not is_ip(host) else None) as ssock:
                cert = ssock.getpeercert()
                cipher = ssock.cipher()
                version = ssock.version()

        subject = dict(x[0] for x in cert.get("subject", []))
        issuer = dict(x[0] for x in cert.get("issuer", []))

        return {
            "host": host,
            "port": port,
            "tls_version": version,
            "cipher": cipher,
            "subject": subject,
            "issuer": issuer,
            "not_before": cert.get("notBefore"),
            "not_after": cert.get("notAfter"),
            "subject_alt_names": cert.get("subjectAltName"),
            "serial_number": cert.get("serialNumber"),
        }

    except Exception as e:
        return safe_error(e)


def module_crtsh(target):
    domain = normalize_domain(target)
    if not is_domain(domain):
        return safe_error("crt.sh için geçerli domain gir.")

    url = "https://crt.sh/?" + urllib.parse.urlencode({
        "q": f"%.{domain}",
        "output": "json",
    })

    result = fetch_url(url, timeout=20, headers={"Accept": "application/json"}, max_bytes=4_000_000)

    if not result["ok"]:
        return {
            "source": url,
            "error": result.get("error") or "crt.sh cevabı alınamadı.",
            "status": result.get("status"),
            "raw": result.get("text", "")[:1500],
        }

    try:
        data = json.loads(result["text"])
    except Exception:
        return {
            "source": url,
            "error": "crt.sh cevabı JSON çözülemedi. Bazen servis HTML/limit cevabı döndürebilir.",
            "raw": result["text"][:1500],
        }

    subdomains = set()
    for row in data:
        name = row.get("name_value", "")
        for item in str(name).splitlines():
            item = item.lower().strip()
            item = item.replace("*.", "")
            if item.endswith(domain):
                subdomains.add(item)

    return {
        "source": url,
        "domain": domain,
        "count": len(subdomains),
        "subdomains": sorted(subdomains)[:1000],
        "limited": len(subdomains) > 1000,
    }


def module_robots_sitemap(target):
    base = normalize_url(target)
    parsed = urllib.parse.urlparse(base)
    root = f"{parsed.scheme}://{parsed.netloc}"

    robots_url = root + "/robots.txt"
    sitemap_url = root + "/sitemap.xml"

    robots = fetch_url(robots_url, timeout=10, max_bytes=500_000)
    sitemap = fetch_url(sitemap_url, timeout=10, max_bytes=800_000)

    return {
        "root": root,
        "robots": {
            "url": robots_url,
            "ok": robots.get("ok"),
            "status": robots.get("status"),
            "content_preview": robots.get("text", "")[:5000],
            "error": robots.get("error"),
        },
        "sitemap": {
            "url": sitemap_url,
            "ok": sitemap.get("ok"),
            "status": sitemap.get("status"),
            "content_preview": sitemap.get("text", "")[:5000],
            "error": sitemap.get("error"),
        },
    }


def module_public_ip(target):
    target = normalize_domain(target)

    if target and not is_ip(target):
        try:
            target = socket.gethostbyname(target)
        except Exception:
            return safe_error("IP çözümlenemedi.")

    if not target:
        result = fetch_url("https://api.ipify.org?format=json", timeout=10)
        try:
            target = json.loads(result["text"]).get("ip")
        except Exception:
            return safe_error("Public IP alınamadı.")

    services = [
        f"https://ipapi.co/{urllib.parse.quote(target)}/json/",
        f"https://ipwho.is/{urllib.parse.quote(target)}",
    ]

    responses = []
    for url in services:
        r = fetch_url(url, timeout=12)
        item = {
            "source": url,
            "ok": r.get("ok"),
            "status": r.get("status"),
            "error": r.get("error"),
        }
        try:
            item["data"] = json.loads(r.get("text", "{}"))
        except Exception:
            item["raw"] = r.get("text", "")[:1500]
        responses.append(item)

    return {
        "ip": target,
        "results": responses,
    }


def module_redirects(target):
    url = normalize_url(target)
    chain = []

    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, req, fp, code, msg, headers, newurl):
            return None

    opener = urllib.request.build_opener(NoRedirect)

    current = url
    for _ in range(10):
        req = urllib.request.Request(current, headers={
            "User-Agent": f"{APP_NAME}/{VERSION}",
            "Accept": "*/*",
        })
        try:
            resp = opener.open(req, timeout=10)
            chain.append({
                "url": current,
                "status": getattr(resp, "status", None),
                "location": None,
            })
            break
        except urllib.error.HTTPError as e:
            location = e.headers.get("Location")
            chain.append({
                "url": current,
                "status": e.code,
                "location": location,
            })

            if e.code in [301, 302, 303, 307, 308] and location:
                current = urllib.parse.urljoin(current, location)
                continue
            break
        except Exception as e:
            chain.append({
                "url": current,
                "error": str(e),
            })
            break

    return {
        "start": url,
        "chain": chain,
        "final": chain[-1] if chain else None,
    }


def module_email_header(raw_header):
    raw_header = clean_text(raw_header, 20000)
    if not raw_header:
        return safe_error("E-posta header içeriği boş.")

    msg = email.message_from_string(raw_header)

    received = msg.get_all("Received", [])
    auth_results = msg.get_all("Authentication-Results", [])

    fields = {
        "From": msg.get("From"),
        "To": msg.get("To"),
        "Subject": msg.get("Subject"),
        "Date": msg.get("Date"),
        "Message-ID": msg.get("Message-ID"),
        "Return-Path": msg.get("Return-Path"),
        "Reply-To": msg.get("Reply-To"),
        "DKIM-Signature": "var" if msg.get("DKIM-Signature") else "yok",
        "SPF/Auth Results": auth_results,
        "Received Chain": received,
    }

    ips = sorted(set(re.findall(
        r"\b(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)\b",
        raw_header
    )))

    domains = sorted(set(re.findall(
        r"\b(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,63}\b",
        raw_header
    )))

    return {
        "parsed_fields": fields,
        "ips_found": ips,
        "domains_found": domains[:500],
        "received_count": len(received),
        "note": "Bu analiz yalnızca header metninden pasif çıkarım yapar.",
    }


def module_ioc_extract(text):
    text = clean_text(text, 50000)

    ipv4 = sorted(set(re.findall(
        r"\b(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)\b",
        text
    )))

    urls = sorted(set(re.findall(
        r"https?://[^\s\"'<>]+",
        text
    )))

    domains = sorted(set(re.findall(
        r"\b(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,63}\b",
        text
    )))

    emails = sorted(set(re.findall(
        r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,63}\b",
        text
    )))

    hashes = sorted(set(re.findall(
        r"\b[a-fA-F0-9]{32}\b|\b[a-fA-F0-9]{40}\b|\b[a-fA-F0-9]{64}\b",
        text
    )))

    return {
        "ipv4": ipv4,
        "urls": urls,
        "domains": domains[:1000],
        "emails": emails[:1000],
        "hashes": hashes,
        "counts": {
            "ipv4": len(ipv4),
            "urls": len(urls),
            "domains": len(domains),
            "emails": len(emails),
            "hashes": len(hashes),
        }
    }


def module_hash_identify(value):
    value = clean_text(value, 1000).strip()

    value = value.lower()
    value = re.sub(r"[^a-f0-9]", "", value)

    length = len(value)

    guesses = []
    if re.fullmatch(r"[a-f0-9]+", value or ""):
        if length == 32:
            guesses.append("MD5")
        elif length == 40:
            guesses.append("SHA1")
        elif length == 56:
            guesses.append("SHA224")
        elif length == 64:
            guesses.append("SHA256")
        elif length == 96:
            guesses.append("SHA384")
        elif length == 128:
            guesses.append("SHA512")

    return {
        "input_cleaned": value,
        "length": length,
        "possible_types": guesses or ["Bilinmiyor"],
        "note": "Bu modül hash kırmaz; yalnızca uzunluk ve karakter yapısına göre tür tahmini yapar.",
    }


def module_all_passive(target):
    target = clean_text(target, 1000)

    results = {
        "target": target,
        "generated_at": now(),
        "modules": {}
    }

    for name, func in [
        ("rdap", module_rdap),
        ("dns", module_dns),
        ("http_headers", module_http_headers),
        ("ssl", module_ssl),
        ("crtsh", module_crtsh),
        ("robots_sitemap", module_robots_sitemap),
        ("redirects", module_redirects),
        ("public_ip", module_public_ip),
    ]:
        try:
            results["modules"][name] = func(target)
        except Exception as e:
            results["modules"][name] = safe_error(e)

    return results


MODULES = {
    "all": module_all_passive,
    "rdap": module_rdap,
    "dns": module_dns,
    "http": module_http_headers,
    "ssl": module_ssl,
    "crtsh": module_crtsh,
    "robots": module_robots_sitemap,
    "ip": module_public_ip,
    "redirects": module_redirects,
    "email_header": module_email_header,
    "ioc": module_ioc_extract,
    "hash": module_hash_identify,
}


# ---------------------------------------------------------
# Web Arayüzü
# ---------------------------------------------------------

HTML_PAGE = r"""
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Termux OSINT Panel</title>
  <style>
    :root {
      --bg: #07111f;
      --card: rgba(255,255,255,.075);
      --card2: rgba(255,255,255,.11);
      --text: #eaf2ff;
      --muted: #9db2ca;
      --line: rgba(255,255,255,.14);
      --accent: #3b82f6;
      --accent2: #22c55e;
      --danger: #fb7185;
      --warn: #f59e0b;
      --shadow: 0 20px 55px rgba(0,0,0,.35);
      --radius: 22px;
      --mono: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
      --sans: Inter, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }

    * { box-sizing: border-box; }

    body {
      margin: 0;
      font-family: var(--sans);
      color: var(--text);
      background:
        radial-gradient(circle at top left, rgba(59,130,246,.38), transparent 32%),
        radial-gradient(circle at top right, rgba(34,197,94,.25), transparent 28%),
        linear-gradient(135deg, #06101f, #081527 42%, #050916);
      min-height: 100vh;
    }

    .wrap {
      width: min(1180px, calc(100% - 28px));
      margin: 0 auto;
      padding: 26px 0 40px;
    }

    .hero {
      display: grid;
      grid-template-columns: 1.25fr .75fr;
      gap: 18px;
      align-items: stretch;
      margin-bottom: 18px;
    }

    .hero-card, .panel, .result {
      background: linear-gradient(180deg, var(--card2), var(--card));
      border: 1px solid var(--line);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
      backdrop-filter: blur(14px);
    }

    .hero-card {
      padding: 26px;
      overflow: hidden;
      position: relative;
    }

    .hero-card::after {
      content: "";
      position: absolute;
      right: -80px;
      top: -80px;
      width: 230px;
      height: 230px;
      border-radius: 999px;
      background: rgba(59,130,246,.22);
      filter: blur(10px);
    }

    h1 {
      margin: 0;
      font-size: clamp(30px, 4vw, 54px);
      letter-spacing: -1.5px;
      line-height: 1;
    }

    .subtitle {
      margin: 14px 0 0;
      color: var(--muted);
      font-size: 16px;
      line-height: 1.6;
      max-width: 760px;
    }

    .badges {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      margin-top: 18px;
    }

    .badge {
      padding: 8px 11px;
      border: 1px solid var(--line);
      border-radius: 999px;
      background: rgba(255,255,255,.07);
      color: #cfe0f5;
      font-size: 13px;
    }

    .status {
      padding: 22px;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      min-height: 190px;
    }

    .status .big {
      font-size: 42px;
      font-weight: 800;
      letter-spacing: -1px;
    }

    .status .small {
      color: var(--muted);
      line-height: 1.5;
      margin-top: 8px;
    }

    .dot {
      width: 10px;
      height: 10px;
      background: var(--accent2);
      border-radius: 999px;
      display: inline-block;
      box-shadow: 0 0 18px var(--accent2);
      margin-right: 8px;
    }

    .grid {
      display: grid;
      grid-template-columns: 340px 1fr;
      gap: 18px;
    }

    .panel {
      padding: 18px;
    }

    label {
      display: block;
      color: #d9e8fb;
      font-size: 14px;
      margin-bottom: 8px;
      font-weight: 700;
    }

    input, textarea, select, button {
      width: 100%;
      border: 1px solid var(--line);
      border-radius: 16px;
      background: rgba(3, 9, 20, .62);
      color: var(--text);
      padding: 13px 14px;
      outline: none;
      font: inherit;
    }

    textarea {
      min-height: 170px;
      resize: vertical;
      font-family: var(--mono);
      font-size: 13px;
    }

    input:focus, textarea:focus, select:focus {
      border-color: rgba(59,130,246,.8);
      box-shadow: 0 0 0 4px rgba(59,130,246,.14);
    }

    .field {
      margin-bottom: 14px;
    }

    button {
      border: none;
      background: linear-gradient(135deg, var(--accent), #06b6d4);
      color: white;
      font-weight: 800;
      cursor: pointer;
      transition: transform .15s ease, filter .15s ease;
    }

    button:hover {
      transform: translateY(-1px);
      filter: brightness(1.05);
    }

    button.secondary {
      background: rgba(255,255,255,.08);
      border: 1px solid var(--line);
      color: var(--text);
    }

    .btn-row {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10px;
    }

    .modules {
      display: grid;
      gap: 8px;
      margin-top: 10px;
    }

    .module-tip {
      border: 1px solid var(--line);
      border-radius: 14px;
      padding: 10px;
      background: rgba(255,255,255,.055);
      color: var(--muted);
      font-size: 13px;
      line-height: 1.45;
    }

    .result {
      padding: 18px;
      min-height: 560px;
      overflow: hidden;
    }

    .result-head {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 14px;
      margin-bottom: 14px;
    }

    .result-title {
      font-size: 19px;
      font-weight: 850;
    }

    .tools {
      display: flex;
      gap: 8px;
    }

    .tools button {
      padding: 9px 12px;
      border-radius: 12px;
      font-size: 13px;
    }

    pre {
      margin: 0;
      padding: 16px;
      border-radius: 18px;
      background: rgba(0,0,0,.42);
      border: 1px solid rgba(255,255,255,.1);
      color: #d9f99d;
      overflow: auto;
      min-height: 480px;
      max-height: 70vh;
      font-family: var(--mono);
      font-size: 13px;
      line-height: 1.5;
      white-space: pre-wrap;
      word-break: break-word;
    }

    .notice {
      margin-top: 14px;
      border: 1px solid rgba(245,158,11,.35);
      background: rgba(245,158,11,.10);
      border-radius: 16px;
      padding: 12px;
      color: #fde68a;
      font-size: 13px;
      line-height: 1.45;
    }

    .footer {
      margin-top: 20px;
      color: var(--muted);
      font-size: 13px;
      text-align: center;
    }

    .hide {
      display: none;
    }

    @media (max-width: 880px) {
      .hero, .grid {
        grid-template-columns: 1fr;
      }

      .status {
        min-height: auto;
      }
    }
  </style>
</head>
<body>
  <main class="wrap">
    <section class="hero">
      <div class="hero-card">
        <h1>Termux OSINT Panel</h1>
        <p class="subtitle">
          Tek dosya Python paneli. Domain, IP, URL ve metinler üzerinde pasif / izinli OSINT analizi yapar.
          Saldırı, izinsiz tarama veya kişisel veri avcılığı için tasarlanmamıştır.
        </p>
        <div class="badges">
          <span class="badge">Python</span>
          <span class="badge">Termux</span>
          <span class="badge">Tek Dosya</span>
          <span class="badge">Rastgele Port</span>
          <span class="badge">Pasif OSINT</span>
        </div>
      </div>

      <div class="hero-card status">
        <div>
          <div><span class="dot"></span>Panel aktif</div>
          <div class="big" id="clock">--:--</div>
          <div class="small">
            Modüller: RDAP, DNS, HTTP, SSL, crt.sh, robots, sitemap, IP, IOC, header.
          </div>
        </div>
      </div>
    </section>

    <section class="grid">
      <aside class="panel">
        <div class="field">
          <label>Modül seç</label>
          <select id="module">
            <option value="all">Tüm Pasif Kontroller</option>
            <option value="rdap">RDAP Domain / IP</option>
            <option value="dns">DNS Kayıtları</option>
            <option value="http">HTTP Header Analizi</option>
            <option value="ssl">SSL Sertifika Analizi</option>
            <option value="crtsh">crt.sh Subdomain Keşfi</option>
            <option value="robots">robots.txt / sitemap.xml</option>
            <option value="ip">Public IP OSINT</option>
            <option value="redirects">URL Yönlendirme Zinciri</option>
            <option value="email_header">E-posta Header Analizi</option>
            <option value="ioc">IOC Çıkarıcı</option>
            <option value="hash">Hash Türü Tahmini</option>
          </select>
        </div>

        <div class="field" id="targetBox">
          <label>Hedef</label>
          <input id="target" placeholder="ornek.com, https://ornek.com veya 8.8.8.8">
        </div>

        <div class="field hide" id="textBox">
          <label>Metin / Header</label>
          <textarea id="textInput" placeholder="Analiz edilecek metni veya e-posta header bilgisini buraya yapıştır."></textarea>
        </div>

        <div class="btn-row">
          <button onclick="runModule()">Analiz Et</button>
          <button class="secondary" onclick="clearResult()">Temizle</button>
        </div>

        <div class="modules">
          <div class="module-tip">
            <b>İpucu:</b> “Tüm Pasif Kontroller” domain için en kapsamlı çıktıyı verir.
          </div>
          <div class="module-tip">
            <b>DNS notu:</b> MX/TXT/NS için <code>pip install dnspython</code> kurabilirsin.
          </div>
        </div>

        <div class="notice">
          Bu panel sadece kendi sistemlerin, kendi domainlerin veya izinli araştırmalar için kullanılmalıdır.
        </div>
      </aside>

      <section class="result">
        <div class="result-head">
          <div class="result-title">Sonuç</div>
          <div class="tools">
            <button class="secondary" onclick="copyResult()">Kopyala</button>
            <button class="secondary" onclick="downloadResult()">JSON İndir</button>
          </div>
        </div>
        <pre id="output">Hazır. Bir modül seçip analiz başlat.</pre>
      </section>
    </section>

    <div class="footer">
      Termux OSINT Panel · Güvenli / pasif analiz sürümü
    </div>
  </main>

  <script>
    const moduleSelect = document.getElementById("module");
    const targetBox = document.getElementById("targetBox");
    const textBox = document.getElementById("textBox");
    const output = document.getElementById("output");

    function updateClock() {
      const d = new Date();
      document.getElementById("clock").textContent =
        d.toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" });
    }

    setInterval(updateClock, 1000);
    updateClock();

    moduleSelect.addEventListener("change", () => {
      const mod = moduleSelect.value;
      if (["email_header", "ioc", "hash"].includes(mod)) {
        textBox.classList.remove("hide");
        targetBox.classList.add("hide");
      } else {
        textBox.classList.add("hide");
        targetBox.classList.remove("hide");
      }
    });

    async function runModule() {
      const mod = moduleSelect.value;
      let target = document.getElementById("target").value.trim();

      if (["email_header", "ioc", "hash"].includes(mod)) {
        target = document.getElementById("textInput").value;
      }

      if (!target) {
        output.textContent = "Lütfen hedef veya metin gir.";
        return;
      }

      output.textContent = "Analiz çalışıyor...";

      try {
        const res = await fetch("/api/run", {
          method: "POST",
          headers: {"Content-Type": "application/json"},
          body: JSON.stringify({
            module: mod,
            target: target
          })
        });

        const data = await res.json();
        output.textContent = JSON.stringify(data, null, 2);
      } catch (e) {
        output.textContent = "Hata: " + e;
      }
    }

    function clearResult() {
      output.textContent = "Temizlendi.";
    }

    async function copyResult() {
      try {
        await navigator.clipboard.writeText(output.textContent);
        alert("Sonuç kopyalandı.");
      } catch (e) {
        alert("Kopyalama başarısız.");
      }
    }

    function downloadResult() {
      const blob = new Blob([output.textContent], {type: "application/json"});
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = "osint-sonuc.json";
      a.click();
      URL.revokeObjectURL(url);
    }
  </script>
</body>
</html>
"""


# ---------------------------------------------------------
# HTTP Handler
# ---------------------------------------------------------

class AppHandler(BaseHTTPRequestHandler):
    server_version = f"{APP_NAME}/{VERSION}"

    def log_message(self, fmt, *args):
        sys.stdout.write("[%s] %s\n" % (now(), fmt % args))

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)

        if parsed.path == "/":
            html_response(self, HTML_PAGE)
            return

        if parsed.path == "/health":
            json_response(self, {
                "ok": True,
                "app": APP_NAME,
                "version": VERSION,
                "time": now(),
            })
            return

        html_response(self, "<h1>404</h1>", status=404)

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)

        if parsed.path != "/api/run":
            json_response(self, {"error": "Not found"}, status=404)
            return

        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length > 250_000:
                json_response(self, {"error": "Girdi çok büyük."}, status=413)
                return

            raw = self.rfile.read(length).decode("utf-8", errors="replace")
            data = json.loads(raw or "{}")

            mod = clean_text(data.get("module"), 50)
            target = clean_text(data.get("target"), 100000)

            if mod not in MODULES:
                json_response(self, {"error": "Bilinmeyen modül."}, status=400)
                return

            started = time.time()

            try:
                result = MODULES[mod](target)
            except Exception as e:
                result = safe_error(e)

            response = {
                "app": APP_NAME,
                "version": VERSION,
                "module": mod,
                "generated_at": now(),
                "duration_seconds": round(time.time() - started, 3),
                "result": result,
            }

            json_response(self, response)

        except Exception as e:
            json_response(self, {"error": str(e)}, status=500)


# ---------------------------------------------------------
# Başlatıcı
# ---------------------------------------------------------

def find_random_port(host):
    for _ in range(50):
        port = random.randint(25000, 65000)
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind((host, port))
                return port
        except OSError:
            continue
    return 8080


def main():
    parser = argparse.ArgumentParser(description="Termux OSINT Panel - Tek Dosya")
    parser.add_argument("--public", action="store_true", help="Aynı Wi-Fi ağından erişim için 0.0.0.0 üzerinde açar.")
    parser.add_argument("--port", type=int, default=0, help="Port belirt. Boşsa rastgele seçilir.")
    args = parser.parse_args()

    host = "0.0.0.0" if args.public else "127.0.0.1"
    port = args.port if args.port else find_random_port(host)

    server = ThreadingHTTPServer((host, port), AppHandler)

    local_url = f"http://127.0.0.1:{port}"

    print("")
    print("=" * 62)
    print(f"{APP_NAME} v{VERSION}")
    print("=" * 62)
    print(f"Panel adresi: {local_url}")

    if args.public:
        try:
            ip = socket.gethostbyname(socket.gethostname())
        except Exception:
            ip = "TELEFON_IP_ADRESIN"
        print(f"Aynı Wi-Fi için: http://{ip}:{port}")

    print("")
    print("Durdurmak için CTRL + C")
    print("=" * 62)
    print("")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nPanel kapatıldı.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()