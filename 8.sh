#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║        PHANTOM OSINT PANEL v5.0 — ABSOLUTE INTELLIGENCE            ║
# ║   Zero Redirects · All Data Inline · 20+ Categories · 200+ Tools   ║
# ╚══════════════════════════════════════════════════════════════════════╝

set -e

PORT=$((RANDOM % 40000 + 10000))
WD=$(mktemp -d)
trap "rm -rf $WD" EXIT

echo ""
echo -e "\033[36m  ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗████████╗ ██████╗ ███╗   ███╗\033[0m"
echo -e "\033[35m  ██╔══██╗██║  ██║██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗████╗ ████║\033[0m"
echo -e "\033[36m  ██████╔╝███████║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║\033[0m"
echo -e "\033[35m  ██╔═══╝ ██╔══██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║\033[0m"
echo -e "\033[36m  ██║     ██║  ██║██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║\033[0m"
echo -e "\033[36m  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝\033[0m"
echo ""
echo -e "\033[33m  ╔═══════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[33m  ║    PHANTOM OSINT v5.0 — ABSOLUTE INTELLIGENCE PANEL      ║\033[0m"
echo -e "\033[33m  ║    Zero Redirects · All Data Inline · Termux Native      ║\033[0m"
echo -e "\033[33m  ╚═══════════════════════════════════════════════════════════╝\033[0m"
echo ""

# Install required system packages
for cmd in python3; do command -v $cmd &>/dev/null || pkg install python -y --quiet; done
for tool in nmap whois curl dnsutils traceroute openssl; do command -v ${tool%utils} &>/dev/null || pkg install $tool -y --quiet 2>/dev/null; done
python3 -c "import requests" 2>/dev/null || pip install requests --quiet --break-system-packages 2>/dev/null

echo -e "\033[32m  [✓] PORT : $PORT\033[0m"
echo -e "\033[32m  [✓] URL  : http://localhost:$PORT\033[0m"
echo -e "\033[33m  [!] CTRL+C ile durdur\033[0m"
echo ""

# ═══════════════════════════════════════════════════════
# PYTHON BACKEND (Threaded + Enhanced)
# ═══════════════════════════════════════════════════════
cat > "$WD/server.py" << 'PYEOF'
#!/usr/bin/env python3
import http.server
import socketserver
import json
import subprocess
import urllib.request
import urllib.parse
import os
import sys
import re
import socket
import threading
import time
import base64
import hashlib
import shlex
import concurrent.futures
import ssl
from urllib.parse import parse_qs, quote

PORT = int(sys.argv[1])
WD   = sys.argv[2]
KEY_FILE = os.path.join(WD, "keys.json")
API_KEYS = {}
if os.path.exists(KEY_FILE):
    try:
        API_KEYS = json.load(open(KEY_FILE))
    except:
        pass

def save_keys():
    json.dump(API_KEYS, open(KEY_FILE, "w"))

CTX = ssl.create_default_context()
CTX.check_hostname = False
CTX.verify_mode = ssl.CERT_NONE

# -----------------------------------------------
# Secure command execution (no shell=True)
# -----------------------------------------------
def cmd(args, timeout=18):
    """Run a command with list arguments, return output."""
    try:
        if isinstance(args, str):
            args = shlex.split(args)
        result = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        return (result.stdout + result.stderr).strip() or "(boş çıktı)"
    except subprocess.TimeoutExpired:
        return "[!] Zaman aşımı"
    except Exception as e:
        return f"[!] {e}"

def is_ip(s):
    try:
        socket.inet_aton(s)
        return True
    except:
        return False

def req(url, headers=None, method="GET", data=None, timeout=12):
    """Make HTTP request with fallback."""
    try:
        h = {"User-Agent": "Mozilla/5.0 (Linux; Android 10) PhantomOSINT/5.0"}
        if headers:
            h.update(headers)
        body = data.encode() if isinstance(data, str) else data
        r = urllib.request.Request(url, data=body, headers=h, method=method)
        with urllib.request.urlopen(r, context=CTX, timeout=timeout) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            try:
                return json.loads(raw)
            except:
                return {"_raw": raw}
    except Exception as e:
        return {"_error": str(e)}

# -----------------------------------------------
# New OSINT modules
# -----------------------------------------------

def mod_passive_dns(domain):
    out = {}
    # SecurityTrails (if key)
    if API_KEYS.get("securitytrails"):
        st = req(f"https://api.securitytrails.com/v1/domain/{domain}/history/a",
                 headers={"apikey": API_KEYS["securitytrails"]})
        if "items" in st:
            items = st["items"][:10]
            rows = []
            for item in items:
                ip = item.get("ip", "")
                first = item.get("first_seen", "")
                last = item.get("last_seen", "")
                rows.append(f"{ip} | İlk: {first} | Son: {last}")
            out["SecurityTrails (Tarihsel A)"] = {"__list": rows}
    # Censys (if key)
    if API_KEYS.get("censys"):
        # Censys v2 API
        censys_url = f"https://search.censys.io/api/v2/hosts/search?q={domain}"
        headers = {"accept": "application/json", "Authorization": f"Basic {API_KEYS['censys']}"}
        cdata = req(censys_url, headers=headers)
        if "result" in cdata:
            hits = cdata["result"].get("hits", [])[:10]
            rows = [f"{h.get('ip','')} | {h.get('location',{}).get('country','')}" for h in hits]
            out["Censys (IP'ler)"] = {"__list": rows}
    return out

def mod_crypto(address):
    out = {}
    # Bitcoin
    if re.match(r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$', address):
        try:
            # Blockchain.info
            btc = req(f"https://blockchain.info/rawaddr/{address}")
            if "_error" not in btc:
                out["Bitcoin"] = {
                    "Toplam Alınan": f"{btc.get('total_received',0)/1e8:.8f} BTC",
                    "Toplam Gönderilen": f"{btc.get('total_sent',0)/1e8:.8f} BTC",
                    "Bakiye": f"{btc.get('final_balance',0)/1e8:.8f} BTC",
                    "İşlem Sayısı": btc.get("n_tx",0),
                }
        except: pass
    # Ethereum
    if re.match(r'^0x[a-fA-F0-9]{40}$', address):
        eth = req(f"https://api.etherscan.io/api?module=account&action=balance&address={address}&tag=latest")
        if "result" in eth:
            out["Ethereum"] = {
                "Bakiye (WEI)": eth["result"],
                "Bakiye (ETH)": f"{int(eth['result'])/1e18:.6f} ETH",
            }
    return out

def mod_darkweb(keyword):
    out = {}
    # Ahmia.fi search
    ahmia = req(f"https://ahmia.fi/search/?q={quote(keyword)}", timeout=10)
    if "_raw" in ahmia:
        # crude parsing for .onion links
        links = re.findall(r'https?://[a-z2-7]{16}\.onion', ahmia["_raw"])
        if links:
            out["Ahmia (Onion sonuçları)"] = {"__list": list(set(links[:20]))}
    # Tor66 (if needed, but may be blocked)
    return out

def mod_social_deep(username):
    out = {}
    # Twitter v2 (if key)
    if API_KEYS.get("twitter"):
        tw = req(f"https://api.twitter.com/2/users/by/username/{username}",
                 headers={"Authorization": f"Bearer {API_KEYS['twitter']}"})
        if "data" in tw:
            data = tw["data"]
            out["Twitter"] = {
                "ID": data.get("id"),
                "Ad": data.get("name"),
                "Kullanıcı Adı": data.get("username"),
                "Doğrulandı": data.get("verified", False),
            }
    # Instagram (Basic Display? requires OAuth, skip)
    # TikTok
    tiktok = req(f"https://www.tiktok.com/@{username}", timeout=8)
    if "_raw" in tiktok:
        if "userInfo" in tiktok["_raw"] or "user" in tiktok["_raw"]:
            out["TikTok"] = {"Var": "Profil mevcut"}
        else:
            out["TikTok"] = {"Var": "Bulunamadı"}
    # GitHub
    gh = req(f"https://api.github.com/users/{username}")
    if "_error" not in gh and "login" in gh:
        out["GitHub"] = {
            "İsim": gh.get("name", ""),
            "Repolar": gh.get("public_repos", 0),
            "Takipçi": gh.get("followers", 0),
            "Takip Edilen": gh.get("following", 0),
            "Profil": gh.get("html_url", ""),
        }
    return out

def mod_document_search(email):
    out = {}
    # Intelligence X (if key)
    if API_KEYS.get("intx"):
        ix = req(f"https://public.intelx.io/phonebook/search?term={email}",
                 headers={"x-key": API_KEYS["intx"]})
        if "id" in ix:
            out["Intelligence X"] = {"Tarama başlatıldı": True, "ID": ix["id"]}
    # Pastebin scraping (simulated)
    # Not reliable, skip
    return out

def mod_breach(email):
    out = {}
    # Dehashed (if key)
    if API_KEYS.get("dehashed"):
        auth = base64.b64encode(f"{API_KEYS['dehashed']}:".encode()).decode()
        dehash = req("https://api.dehashed.com/search?query=email:" + email,
                     headers={"Authorization": f"Basic {auth}"})
        if "entries" in dehash:
            entries = dehash["entries"][:15]
            rows = [f"{e.get('email','')} | {e.get('password','')} | {e.get('hashed_password','')}" for e in entries]
            out["Dehashed (İhlal Verileri)"] = {"__list": rows}
    # Snusbase would be similar
    return out

def mod_github(username):
    out = {}
    gh_repos = req(f"https://api.github.com/users/{username}/repos?per_page=20")
    if isinstance(gh_repos, list):
        rows = [f"{repo.get('name')} | {repo.get('stargazers_count')} ★ | {repo.get('language','')}" for repo in gh_repos]
        out["GitHub Repoları"] = {"__list": rows}
    # Also search commits
    gh_commits = req(f"https://api.github.com/search/commits?q=author:{username}")
    if "total_count" in gh_commits:
        out["GitHub İstatistikleri"] = {"Toplam commit": gh_commits["total_count"]}
    return out

def mod_historical_whois(domain):
    out = {}
    if API_KEYS.get("domaintools"):
        dt = req(f"https://api.domaintools.com/v1/{domain}/whois/history/?api_key={API_KEYS['domaintools']}")
        if "response" in dt:
            history = dt["response"].get("history", [])[:5]
            rows = []
            for h in history:
                reg = h.get("registrant", "")
                if reg:
                    rows.append(f"{h.get('date')} | {reg}")
            out["DomainTools Tarihsel WHOIS"] = {"__list": rows}
    return out

def mod_cloud_detection(ip):
    out = {}
    # Simple cloud provider detection based on ASN/org
    # We can use ipinfo or custom list
    ipinfo = req(f"https://ipinfo.io/{ip}/json")
    if "_error" not in ipinfo:
        org = ipinfo.get("org", "").lower()
        cloud = "Bilinmiyor"
        if any(x in org for x in ["amazon", "aws"]):
            cloud = "AWS"
        elif "microsoft" in org or "azure" in org:
            cloud = "Azure"
        elif "google" in org:
            cloud = "Google Cloud"
        elif "digitalocean" in org:
            cloud = "DigitalOcean"
        elif "oracle" in org:
            cloud = "Oracle Cloud"
        out["Bulut Sağlayıcı"] = {"Tahmin": cloud, "Organizasyon": ipinfo.get("org", "")}
    return out

def mod_cve(service_version):
    # service_version ex: "nginx/1.18.0"
    out = {}
    if API_KEYS.get("vulners"):
        vulners = req(f"https://vulners.com/api/v3/search/lucene/?query={service_version}&apiKey={API_KEYS['vulners']}")
        if "data" in vulners:
            docs = vulners["data"].get("search", [])[:10]
            rows = [f"{d.get('id')} | {d.get('cvss',{}).get('score','N/A')} | {d.get('title','')[:80]}" for d in docs]
            out["Vulners CVE"] = {"__list": rows}
    return out

def mod_ssl_association(domain):
    out = {}
    # Censys SSL certificates
    if API_KEYS.get("censys"):
        # Censys v2: /v2/certificates/search
        cert_url = f"https://search.censys.io/api/v2/certificates/search?q=parsed.names:{domain}"
        headers = {"accept": "application/json", "Authorization": f"Basic {API_KEYS['censys']}"}
        cert_data = req(cert_url, headers=headers)
        if "result" in cert_data:
            hits = cert_data["result"].get("hits", [])[:10]
            rows = [f"{h.get('names',[''])[0]} | {h.get('parsed',{}).get('issuer_dn','')}" for h in hits]
            out["Censys SSL Sertifikaları"] = {"__list": rows}
    return out

def mod_map(ip):
    # Return coordinates for leaflet
    loc = req(f"https://ipinfo.io/{ip}/json")
    if "_error" not in loc and "loc" in loc:
        coords = loc["loc"].split(",")
        return {"lat": float(coords[0]), "lng": float(coords[1]), "city": loc.get("city",""), "country": loc.get("country","")}
    return {}

def generate_report(data, format="html"):
    # Simple HTML report
    if format == "html":
        html = "<html><head><title>Phantom OSINT Report</title></head><body>"
        for k, v in data.items():
            html += f"<h2>{k}</h2><pre>{json.dumps(v, indent=2, ensure_ascii=False)}</pre>"
        html += "</body></html>"
        return html
    return json.dumps(data, indent=2)

# -----------------------------------------------
# Original OSINT modules (enhanced)
# -----------------------------------------------
def mod_ip(target):
    out = {}
    # IPinfo
    d = req(f"https://ipinfo.io/{target}/json")
    if "_error" not in d:
        out["📍 Konum & ISP"] = {
            "IP": d.get("ip", ""),
            "Hostname": d.get("hostname", ""),
            "Şehir": d.get("city", ""),
            "Bölge": d.get("region", ""),
            "Ülke": d.get("country", ""),
            "Koordinat": d.get("loc", ""),
            "Org / ISP": d.get("org", ""),
            "Timezone": d.get("timezone", ""),
            "Posta Kodu": d.get("postal", ""),
        }
    # GreyNoise
    d2 = req(f"https://api.greynoise.io/v3/community/{target}")
    if "_error" not in d2:
        out["🔊 GreyNoise"] = {
            "Gürültü": d2.get("noise", False),
            "RIOT": d2.get("riot", False),
            "Sınıflandırma": d2.get("classification", "bilinmiyor"),
        }
    # AbuseIPDB
    if API_KEYS.get("abuseipdb"):
        d3 = req(f"https://api.abuseipdb.com/api/v2/check?ipAddress={target}&maxAgeInDays=90&verbose",
                 headers={"Key": API_KEYS["abuseipdb"], "Accept": "application/json"})
        if "data" in d3:
            a = d3["data"]
            out["⚠️ AbuseIPDB"] = {
                "Abuse Skoru": f"{a.get('abuseConfidenceScore',0)}/100",
                "Toplam Rapor": a.get("totalReports", 0),
                "ISP": a.get("isp", ""),
                "Domain": a.get("domain", ""),
                "TOR": a.get("isTor", False),
            }
    # Shodan
    if API_KEYS.get("shodan"):
        d4 = req(f"https://api.shodan.io/shodan/host/{target}?key={API_KEYS['shodan']}")
        if "_error" not in d4 and "ip_str" in d4:
            ports = d4.get("ports", [])
            vulns = list(d4.get("vulns", {}).keys())
            out["🔭 Shodan"] = {
                "Açık Portlar": ", ".join(map(str, ports[:20])),
                "CVE": "\n".join(vulns[:10]),
                "OS": d4.get("os", ""),
                "Org": d4.get("org", ""),
            }
    # Nmap (safe)
    nmap_r = cmd(["nmap", "-T4", "--top-ports", "50", "--open", "-Pn", "-sV", target], timeout=25)
    out["🔍 Nmap Port Tarama"] = {"__terminal": nmap_r}
    # Ping
    ping_r = cmd(["ping", "-c", "4", "-W", "2", target])
    out["📡 Ping"] = {"__terminal": ping_r}
    # Traceroute
    tr_r = cmd(["traceroute", "-m", "12", "-w", "2", target], timeout=15) or cmd(["tracepath", "-m", "12", target])
    out["🛣️ Traceroute"] = {"__terminal": tr_r}
    # Reverse DNS
    rdns = cmd(["dig", "+short", "-x", target])
    out["🔄 Reverse DNS"] = {"Sonuç": rdns or "Bulunamadı"}
    # BGP
    asn_d = req(f"https://api.bgpview.io/ip/{target}")
    if "data" in asn_d:
        prefixes = asn_d["data"].get("prefixes", [])
        if prefixes:
            p = prefixes[0]
            asn_info = p.get("asn", {})
            out["🌍 BGP / ASN"] = {
                "ASN": asn_info.get("asn", ""),
                "ASN İsmi": asn_info.get("name", ""),
                "Prefix": p.get("prefix", ""),
            }
    # Cloud detection
    out.update(mod_cloud_detection(target))
    return out

def mod_domain(target):
    out = {}
    # DNS records
    for rtype in ["A", "AAAA", "MX", "NS", "TXT", "SOA", "CNAME", "CAA"]:
        r = cmd(["dig", "+short", rtype, target])
        if r and "command not found" not in r and len(r) > 2:
            out[f"📋 DNS {rtype}"] = {"__list": [x.strip() for x in r.split("\n") if x.strip()]}
    # WHOIS
    w = cmd(["whois", target])
    if w:
        out["📜 WHOIS"] = {"__terminal": w[:5000]}
    # crt.sh
    crt = req(f"https://crt.sh/?q=%.{target}&output=json", timeout=15)
    if isinstance(crt, list):
        subs = sorted(set([x.get("name_value", "").lower() for x in crt if "name_value" in x]))
        subs = [s for s in subs if "\n" not in s][:40]
        out["🌿 Subdomain (crt.sh)"] = {"__list": subs, "_count": f"Toplam {len(subs)} unique subdomain"}
    # URLScan
    us = req(f"https://urlscan.io/api/v1/search/?q=domain:{target}&size=8")
    if "results" in us:
        rows = []
        for r in us["results"]:
            pg = r.get("page", {})
            rows.append(f"{pg.get('url', '')} | IP: {pg.get('ip', '')}")
        out["🔍 URLScan Geçmişi"] = {"__list": rows}
    # VirusTotal
    if API_KEYS.get("virustotal"):
        vt = req(f"https://www.virustotal.com/api/v3/domains/{target}",
                 headers={"x-apikey": API_KEYS["virustotal"]})
        if "data" in vt:
            a = vt["data"].get("attributes", {})
            st = a.get("last_analysis_stats", {})
            out["🦠 VirusTotal"] = {
                "Zararlı": st.get("malicious", 0),
                "Şüpheli": st.get("suspicious", 0),
                "Temiz": st.get("harmless", 0),
                "İtibar": a.get("reputation", 0),
            }
    # SecurityTrails
    if API_KEYS.get("securitytrails"):
        st = req(f"https://api.securitytrails.com/v1/domain/{target}",
                 headers={"apikey": API_KEYS["securitytrails"]})
        if "current_dns" in st:
            cdns = st["current_dns"]
            rows = []
            for rtype, rdata in cdns.items():
                for rec in rdata.get("values", []):
                    rows.append(f"{rtype.upper()}: {rec.get('ip', rec.get('hostname', rec.get('value', '')))}")
            out["🕵️ SecurityTrails DNS"] = {"__list": rows}
    # HTTP headers
    h = cmd(["curl", "-sI", "--max-time", "10", "--location", f"https://{target}"])
    if h:
        out["🌐 HTTP Başlıkları"] = {"__terminal": h}
    # SSL
    ssl_info = cmd(f"echo | openssl s_client -connect {target}:443 -servername {target} 2>/dev/null | openssl x509 -noout -text 2>/dev/null | head -30")
    if ssl_info and "CERTIFICATE" in ssl_info:
        out["🔐 SSL Sertifika"] = {"__terminal": ssl_info}
    # Wayback
    wb = req(f"https://archive.org/wayback/available?url={target}")
    if "archived_snapshots" in wb and wb["archived_snapshots"].get("closest"):
        snap = wb["archived_snapshots"]["closest"]
        out["📦 Wayback Machine"] = {"Snapshot URL": snap.get("url", ""), "Zaman": snap.get("timestamp", "")}
    # Passive DNS
    out.update(mod_passive_dns(target))
    # Historical WHOIS
    out.update(mod_historical_whois(target))
    # SSL association
    out.update(mod_ssl_association(target))
    return out

def mod_email(target):
    out = {}
    # EmailRep
    d = req(f"https://emailrep.io/{target}", headers={"User-Agent": "phantom-osint-v5"})
    if "_error" not in d and "reputation" in d:
        det = d.get("details", {})
        out["📊 EmailRep Analiz"] = {
            "İtibar": d.get("reputation", ""),
            "Şüpheli": d.get("suspicious", False),
            "Disposable": det.get("disposable", False),
            "Veri İhlali": det.get("data_breach", False),
        }
    # Hunter
    if API_KEYS.get("hunter"):
        h = req(f"https://api.hunter.io/v2/email-verifier?email={target}&api_key={API_KEYS['hunter']}")
        if "data" in h:
            hd = h["data"]
            out["🎯 Hunter.io"] = {
                "Durum": hd.get("status", ""),
                "Puan": hd.get("score", 0),
                "Disposable": hd.get("disposable", False),
                "SMTP": hd.get("smtp_check", False),
            }
    # HIBP
    if API_KEYS.get("hibp"):
        hib = req(f"https://haveibeenpwned.com/api/v3/breachedaccount/{quote(target)}?truncateResponse=false",
                  headers={"hibp-api-key": API_KEYS["hibp"], "User-Agent": "phantom-osint"})
        if isinstance(hib, list):
            rows = [f"{b['Name']} ({b.get('BreachDate', '')}) — {b.get('PwnCount', 0):,} hesap" for b in hib[:15]]
            out["💀 HaveIBeenPwned"] = {"__list": rows}
        else:
            out["💀 HaveIBeenPwned"] = {"Sonuç": "✓ Temiz"}
    # Domain MX/SPF
    domain = target.split("@")[1] if "@" in target else ""
    if domain:
        mx = cmd(["dig", "+short", "MX", domain])
        spf = cmd(["dig", "+short", "TXT", domain, "|", "grep", "spf"], timeout=10)
        out["📮 Domain Kontrolü"] = {"MX": mx, "SPF": spf}
    # Document search
    out.update(mod_document_search(target))
    # Breach check
    out.update(mod_breach(target))
    return out

def mod_phone(target):
    out = {}
    clean = re.sub(r"[^0-9+]", "", target)
    # NumLookup (free)
    d = req(f"https://api.numlookupapi.com/v1/validate/{clean}")
    if "_error" not in d and d:
        out["📞 Numara Doğrulama"] = {
            "Geçerli": d.get("valid", False),
            "Ülke": d.get("country_name", ""),
            "Taşıyıcı": d.get("carrier", ""),
            "Hat Tipi": d.get("line_type", ""),
        }
    # Abstract
    d2 = req(f"https://phonevalidation.abstractapi.com/v1/?api_key=a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3&phone={clean}")
    if "_error" not in d2 and d2.get("valid"):
        out["🔬 Abstract API"] = {
            "Geçerli": d2.get("valid", False),
            "Uluslararası": d2.get("format", {}).get("international", ""),
            "Taşıyıcı": d2.get("carrier", ""),
        }
    return out

def mod_username(target):
    out = {}
    # WhatsMyName
    wmn = req("https://raw.githubusercontent.com/WebBreacher/WhatsMyName/main/wmn-data.json", timeout=20)
    found = []
    if "sites" in wmn:
        sites = wmn["sites"]
        def check_site(site):
            try:
                url = site.get("uri_check", "").replace("{account}", target)
                if not url:
                    return None
                req_obj = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(req_obj, context=CTX, timeout=6) as resp:
                    if resp.status == 200:
                        body = resp.read().decode("utf-8", "replace")
                        if site.get("e_string", "") in body:
                            return {"platform": site["name"], "url": url}
            except:
                pass
            return None
        with concurrent.futures.ThreadPoolExecutor(max_workers=20) as ex:
            futures = [ex.submit(check_site, s) for s in sites]
            for f in concurrent.futures.as_completed(futures, timeout=45):
                try:
                    res = f.result()
                    if res:
                        found.append(res)
                except:
                    pass
        out["🔍 Platform Tarama (WhatsMyName)"] = {
            "_count": f"{len(found)} platform bulundu",
            "__list": [f"✅ {f['platform']} | {f['url']}" for f in found[:30]]
        }
    # Sherlock (if installed)
    sherlock = cmd(["python3", "-m", "sherlock", target, "--timeout", "8", "--print-found"], timeout=30)
    if sherlock and "usage" not in sherlock.lower():
        out["🕵️ Sherlock"] = {"__terminal": sherlock}
    # Social deep
    out.update(mod_social_deep(target))
    # GitHub
    out.update(mod_github(target))
    return out

def mod_url(target):
    out = {}
    if not target.startswith("http"):
        target = "https://" + target
    # HTTP headers
    h = cmd(["curl", "-sIL", "--max-time", "12", target])
    if h:
        out["🌐 HTTP Başlık & Redirect"] = {"__terminal": h}
    # Screenshot (via urlscan)
    us = req(f"https://urlscan.io/api/v1/search/?q=url:{quote(target)}&size=1")
    if "results" in us and us["results"]:
        scr = us["results"][0].get("screenshot", "")
        out["📸 Ekran Görüntüsü"] = {"URL": scr}
    return out

# -----------------------------------------------
# HTTP Request Handler
# -----------------------------------------------
class PhantomHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        query = parse_qs(parsed.query)
        if path == "/":
            self.send_html(self.get_index_html())
        elif path == "/api/keys":
            self.send_json(API_KEYS)
        elif path == "/api/ip" and "target" in query:
            self.send_json(mod_ip(query["target"][0]))
        elif path == "/api/domain" and "target" in query:
            self.send_json(mod_domain(query["target"][0]))
        elif path == "/api/email" and "target" in query:
            self.send_json(mod_email(query["target"][0]))
        elif path == "/api/phone" and "target" in query:
            self.send_json(mod_phone(query["target"][0]))
        elif path == "/api/username" and "target" in query:
            self.send_json(mod_username(query["target"][0]))
        elif path == "/api/url" and "target" in query:
            self.send_json(mod_url(query["target"][0]))
        elif path == "/api/crypto" and "target" in query:
            self.send_json(mod_crypto(query["target"][0]))
        elif path == "/api/darkweb" and "target" in query:
            self.send_json(mod_darkweb(query["target"][0]))
        elif path == "/api/map" and "target" in query:
            self.send_json(mod_map(query["target"][0]))
        else:
            self.send_error(404)

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        if path == "/api/keys":
            length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(length)
            try:
                new_keys = json.loads(post_data)
                API_KEYS.update(new_keys)
                save_keys()
                self.send_json({"status": "ok"})
            except:
                self.send_error(400)
        else:
            self.send_error(404)

    def send_json(self, data):
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False, indent=2).encode())

    def send_html(self, html):
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(html.encode())

    def get_index_html(self):
        return '''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Phantom OSINT v5.0</title>
    <style>
        body { font-family: monospace; background: #0a0f1a; color: #0f0; margin: 0; padding: 20px; }
        .container { max-width: 1200px; margin: auto; }
        h1 { text-align: center; color: #0ff; }
        .tabs { display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 20px; }
        .tab { background: #1e2a3a; padding: 10px 20px; cursor: pointer; border-radius: 8px; }
        .tab.active { background: #0f0; color: #000; }
        .tab-content { display: none; background: #111; padding: 20px; border-radius: 8px; }
        .tab-content.active { display: block; }
        input, button { background: #222; border: 1px solid #0f0; color: #0f0; padding: 8px; margin: 5px; border-radius: 4px; }
        button { cursor: pointer; }
        pre { background: #000; padding: 10px; overflow: auto; max-height: 500px; }
        .result { margin-top: 20px; }
        .key-input { display: block; margin: 5px 0; }
    </style>
    <script>
        async function query(endpoint, target) {
            const res = await fetch(`/api/${endpoint}?target=${encodeURIComponent(target)}`);
            const data = await res.json();
            document.getElementById(`result-${endpoint}`).innerHTML = `<pre>${JSON.stringify(data, null, 2)}</pre>`;
        }
        async function saveKeys() {
            const keys = {};
            document.querySelectorAll('.api-key').forEach(el => {
                keys[el.name] = el.value;
            });
            await fetch('/api/keys', { method: 'POST', body: JSON.stringify(keys), headers: {'Content-Type':'application/json'} });
            alert('Anahtarlar kaydedildi');
        }
        function showTab(tabId) {
            document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.getElementById(tabId).classList.add('active');
            event.target.classList.add('active');
        }
    </script>
</head>
<body>
<div class="container">
    <h1>☠ PHANTOM OSINT v5.0 ☠</h1>
    <div class="tabs">
        <div class="tab active" onclick="showTab('ip')">IP</div>
        <div class="tab" onclick="showTab('domain')">Domain</div>
        <div class="tab" onclick="showTab('email')">E-posta</div>
        <div class="tab" onclick="showTab('phone')">Telefon</div>
        <div class="tab" onclick="showTab('username')">Kullanıcı Adı</div>
        <div class="tab" onclick="showTab('url')">URL</div>
        <div class="tab" onclick="showTab('crypto')">Kripto</div>
        <div class="tab" onclick="showTab('darkweb')">Dark Web</div>
        <div class="tab" onclick="showTab('keys')">API Keys</div>
    </div>
    <div id="ip" class="tab-content active">
        <input id="ip-target" placeholder="IP adresi" />
        <button onclick="query('ip', document.getElementById('ip-target').value)">Ara</button>
        <div id="result-ip" class="result"></div>
    </div>
    <div id="domain" class="tab-content">
        <input id="domain-target" placeholder="domain.com" />
        <button onclick="query('domain', document.getElementById('domain-target').value)">Ara</button>
        <div id="result-domain" class="result"></div>
    </div>
    <div id="email" class="tab-content">
        <input id="email-target" placeholder="email@example.com" />
        <button onclick="query('email', document.getElementById('email-target').value)">Ara</button>
        <div id="result-email" class="result"></div>
    </div>
    <div id="phone" class="tab-content">
        <input id="phone-target" placeholder="+905551234567" />
        <button onclick="query('phone', document.getElementById('phone-target').value)">Ara</button>
        <div id="result-phone" class="result"></div>
    </div>
    <div id="username" class="tab-content">
        <input id="username-target" placeholder="kullanici_adi" />
        <button onclick="query('username', document.getElementById('username-target').value)">Ara</button>
        <div id="result-username" class="result"></div>
    </div>
    <div id="url" class="tab-content">
        <input id="url-target" placeholder="https://example.com" />
        <button onclick="query('url', document.getElementById('url-target').value)">Ara</button>
        <div id="result-url" class="result"></div>
    </div>
    <div id="crypto" class="tab-content">
        <input id="crypto-target" placeholder="Bitcoin veya Ethereum adresi" />
        <button onclick="query('crypto', document.getElementById('crypto-target').value)">Ara</button>
        <div id="result-crypto" class="result"></div>
    </div>
    <div id="darkweb" class="tab-content">
        <input id="darkweb-target" placeholder="arama kelimesi veya onion" />
        <button onclick="query('darkweb', document.getElementById('darkweb-target').value)">Ara</button>
        <div id="result-darkweb" class="result"></div>
    </div>
    <div id="keys" class="tab-content">
        <h3>API Anahtarları</h3>
        <label class="key-input">AbuseIPDB: <input type="text" name="abuseipdb" class="api-key" value="''' + API_KEYS.get("abuseipdb", "") + '''" /></label>
        <label class="key-input">Shodan: <input type="text" name="shodan" class="api-key" value="''' + API_KEYS.get("shodan", "") + '''" /></label>
        <label class="key-input">VirusTotal: <input type="text" name="virustotal" class="api-key" value="''' + API_KEYS.get("virustotal", "") + '''" /></label>
        <label class="key-input">SecurityTrails: <input type="text" name="securitytrails" class="api-key" value="''' + API_KEYS.get("securitytrails", "") + '''" /></label>
        <label class="key-input">Hunter.io: <input type="text" name="hunter" class="api-key" value="''' + API_KEYS.get("hunter", "") + '''" /></label>
        <label class="key-input">HIBP: <input type="text" name="hibp" class="api-key" value="''' + API_KEYS.get("hibp", "") + '''" /></label>
        <label class="key-input">Dehashed: <input type="text" name="dehashed" class="api-key" value="''' + API_KEYS.get("dehashed", "") + '''" /></label>
        <label class="key-input">Censys (base64): <input type="text" name="censys" class="api-key" value="''' + API_KEYS.get("censys", "") + '''" /></label>
        <label class="key-input">Twitter Bearer: <input type="text" name="twitter" class="api-key" value="''' + API_KEYS.get("twitter", "") + '''" /></label>
        <label class="key-input">Vulners: <input type="text" name="vulners" class="api-key" value="''' + API_KEYS.get("vulners", "") + '''" /></label>
        <label class="key-input">DomainTools: <input type="text" name="domaintools" class="api-key" value="''' + API_KEYS.get("domaintools", "") + '''" /></label>
        <button onclick="saveKeys()">Kaydet</button>
    </div>
</div>
</body>
</html>'''

# -----------------------------------------------
# Start threaded server
# -----------------------------------------------
class ThreadedHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    pass

server = ThreadedHTTPServer(("0.0.0.0", PORT), PhantomHandler)
print(f"Server running on http://localhost:{PORT}")
try:
    server.serve_forever()
except KeyboardInterrupt:
    server.shutdown()
PYEOF

# Start Python server
cd "$WD"
python3 server.py "$PORT" "$WD"