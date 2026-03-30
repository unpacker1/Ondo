#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║        PHANTOM OSINT PANEL v4.0 — ABSOLUTE INTELLIGENCE            ║
# ║   Zero Redirects · All Data Inline · 15 Categories · 130+ Tools    ║
# ╚══════════════════════════════════════════════════════════════════════╝

PORT=$((RANDOM % 40000 + 10000))
WD=$(mktemp -d)

echo ""
echo -e "\033[36m  ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗████████╗ ██████╗ ███╗   ███╗\033[0m"
echo -e "\033[35m  ██╔══██╗██║  ██║██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗████╗ ████║\033[0m"
echo -e "\033[36m  ██████╔╝███████║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║\033[0m"
echo -e "\033[35m  ██╔═══╝ ██╔══██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║\033[0m"
echo -e "\033[36m  ██║     ██║  ██║██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║\033[0m"
echo -e "\033[36m  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝\033[0m"
echo ""
echo -e "\033[33m  ╔═══════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[33m  ║    PHANTOM OSINT v4.0 — ABSOLUTE INTELLIGENCE PANEL      ║\033[0m"
echo -e "\033[33m  ║    Zero Redirects · All Data Inline · Termux Native      ║\033[0m"
echo -e "\033[33m  ╚═══════════════════════════════════════════════════════════╝\033[0m"
echo ""

for cmd in python3; do command -v $cmd &>/dev/null || pkg install python -y --quiet; done
for tool in nmap whois curl dnsutils traceroute; do command -v ${tool%utils} &>/dev/null || pkg install $tool -y --quiet 2>/dev/null; done
python3 -c "import requests" 2>/dev/null || pip install requests --quiet --break-system-packages 2>/dev/null

echo -e "\033[32m  [✓] PORT : $PORT\033[0m"
echo -e "\033[32m  [✓] URL  : http://localhost:$PORT\033[0m"
echo -e "\033[33m  [!] CTRL+C ile durdur\033[0m"
echo ""

# ═══════════════════════════════════════════════════════
# PYTHON BACKEND
# ═══════════════════════════════════════════════════════
cat > "$WD/server.py" << 'PYEOF'
import http.server, json, subprocess, urllib.request, urllib.parse
import os, sys, ssl, re, socket, threading, time, base64, hashlib
from urllib.parse import parse_qs

PORT = int(sys.argv[1])
WD   = sys.argv[2]
KEY_FILE = os.path.join(WD, "keys.json")
API_KEYS = {}
if os.path.exists(KEY_FILE):
    try: API_KEYS = json.load(open(KEY_FILE))
    except: pass

def save_keys(): json.dump(API_KEYS, open(KEY_FILE,"w"))

CTX = ssl.create_default_context()
CTX.check_hostname = False
CTX.verify_mode = ssl.CERT_NONE

def req(url, headers=None, method="GET", data=None, timeout=12):
    try:
        h = {"User-Agent": "Mozilla/5.0 (Linux; Android 10) PhantomOSINT/4.0"}
        if headers: h.update(headers)
        body = data.encode() if isinstance(data, str) else data
        r = urllib.request.Request(url, data=body, headers=h, method=method)
        with urllib.request.urlopen(r, context=CTX, timeout=timeout) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            try: return json.loads(raw)
            except: return {"_raw": raw}
    except Exception as e:
        return {"_error": str(e)}

def cmd(c, timeout=18):
    try:
        r = subprocess.run(c, shell=True, capture_output=True, text=True, timeout=timeout)
        return (r.stdout + r.stderr).strip() or "(boş çıktı)"
    except subprocess.TimeoutExpired: return "[!] Zaman aşımı"
    except Exception as e: return f"[!] {e}"

def is_ip(s):
    try: socket.inet_aton(s); return True
    except: return False

# ───────────────────────────────────────────────
# OSINT MODULES
# ───────────────────────────────────────────────

def mod_ip(t):
    out = {}
    # 1. IPinfo
    d = req(f"https://ipinfo.io/{t}/json")
    if "_error" not in d:
        out["📍 Konum & ISP"] = {
            "IP": d.get("ip",""),
            "Hostname": d.get("hostname",""),
            "Şehir": d.get("city",""),
            "Bölge": d.get("region",""),
            "Ülke": d.get("country",""),
            "Koordinat": d.get("loc",""),
            "Org / ISP": d.get("org",""),
            "Timezone": d.get("timezone",""),
            "Posta Kodu": d.get("postal",""),
        }
    # 2. GreyNoise Community
    d2 = req(f"https://api.greynoise.io/v3/community/{t}")
    if "_error" not in d2:
        out["🔊 GreyNoise"] = {
            "Gürültü": d2.get("noise",False),
            "RIOT (iyi bilinen IP)": d2.get("riot",False),
            "Sınıflandırma": d2.get("classification","bilinmiyor"),
            "İsim": d2.get("name",""),
            "Mesaj": d2.get("message",""),
        }
    # 3. AbuseIPDB
    if API_KEYS.get("abuseipdb"):
        d3 = req(f"https://api.abuseipdb.com/api/v2/check?ipAddress={t}&maxAgeInDays=90&verbose",
                 headers={"Key": API_KEYS["abuseipdb"], "Accept":"application/json"})
        if "data" in d3:
            a = d3["data"]
            out["⚠️ AbuseIPDB"] = {
                "Abuse Skoru": f"{a.get('abuseConfidenceScore',0)}/100",
                "Toplam Rapor": a.get("totalReports",0),
                "ISP": a.get("isp",""),
                "Domain": a.get("domain",""),
                "Kullanım Tipi": a.get("usageType",""),
                "TOR Çıkışı": a.get("isTor",False),
                "Son Rapor": a.get("lastReportedAt",""),
                "Ülke": a.get("countryCode",""),
            }
    # 4. Shodan
    if API_KEYS.get("shodan"):
        d4 = req(f"https://api.shodan.io/shodan/host/{t}?key={API_KEYS['shodan']}")
        if "_error" not in d4 and "ip_str" in d4:
            ports = d4.get("ports",[])
            vulns = list(d4.get("vulns",{}).keys())
            svcs = []
            for item in d4.get("data",[])[:8]:
                svc = f"Port {item.get('port','')} — {item.get('transport','').upper()} — {item.get('product','')} {item.get('version','')}".strip(" —")
                if svc: svcs.append(svc)
            out["🔭 Shodan"] = {
                "Açık Portlar": ", ".join(map(str,ports)),
                "Servisler": "\n".join(svcs),
                "CVE / Zaafiyet": "\n".join(vulns) if vulns else "Bulunamadı",
                "OS": d4.get("os",""),
                "Org": d4.get("org",""),
                "ISP": d4.get("isp",""),
                "Hostnames": ", ".join(d4.get("hostnames",[])),
                "Son Güncelleme": d4.get("last_update",""),
            }
    # 5. Nmap (native)
    nmap_r = cmd(f"nmap -T4 --top-ports 50 --open -Pn -sV {t} 2>/dev/null | head -40")
    out["🔍 Nmap Port Tarama"] = {"__terminal": nmap_r}
    # 6. Ping + traceroute
    ping_r = cmd(f"ping -c 4 -W 2 {t} 2>/dev/null")
    out["📡 Ping"] = {"__terminal": ping_r}
    tr_r = cmd(f"traceroute -m 12 -w 2 {t} 2>/dev/null || tracepath -m 12 {t} 2>/dev/null")
    out["🛣️ Traceroute"] = {"__terminal": tr_r}
    # 7. Reverse DNS
    rdns = cmd(f"dig +short -x {t} 2>/dev/null | head -5")
    out["🔄 Reverse DNS"] = {"Sonuç": rdns or "Bulunamadı"}
    # 8. BGP / ASN
    asn_d = req(f"https://api.bgpview.io/ip/{t}")
    if "data" in asn_d:
        prefixes = asn_d["data"].get("prefixes",[])
        if prefixes:
            p = prefixes[0]
            asn_info = p.get("asn",{})
            out["🌍 BGP / ASN"] = {
                "ASN": asn_info.get("asn",""),
                "ASN İsmi": asn_info.get("name",""),
                "Prefix": p.get("prefix",""),
                "Açıklama": asn_info.get("description",""),
                "Ülke": asn_info.get("country_code",""),
            }
    return out

def mod_domain(t):
    out = {}
    # 1. DNS kayıtları
    for rtype in ["A","AAAA","MX","NS","TXT","SOA","CNAME","CAA"]:
        r = cmd(f"dig +short {rtype} {t} 2>/dev/null | head -15")
        if r and "command not found" not in r and len(r) > 2:
            out[f"📋 DNS {rtype}"] = {"__list": [x.strip() for x in r.split("\n") if x.strip()]}
    # 2. WHOIS
    w = cmd(f"whois {t} 2>/dev/null | head -60")
    if w: out["📜 WHOIS"] = {"__terminal": w}
    # 3. crt.sh subdomainler
    crt = req(f"https://crt.sh/?q=%.{t}&output=json", timeout=15)
    if isinstance(crt, list):
        subs = sorted(set([x.get("name_value","").lower() for x in crt if "name_value" in x]))
        subs = [s for s in subs if "\n" not in s][:40]
        out["🌿 Subdomain (crt.sh)"] = {
            "__list": subs,
            "_count": f"Toplam {len(crt)} sertifika, {len(subs)} unique subdomain"
        }
    # 4. URLScan
    us = req(f"https://urlscan.io/api/v1/search/?q=domain:{t}&size=8")
    if "results" in us:
        rows = []
        for r in us["results"]:
            pg = r.get("page",{})
            rows.append(f"{pg.get('url','')} | IP: {pg.get('ip','')} | {r.get('task',{}).get('time','')[:10]}")
        out["🔍 URLScan Geçmişi"] = {"__list": rows}
    # 5. VirusTotal
    if API_KEYS.get("virustotal"):
        vt = req(f"https://www.virustotal.com/api/v3/domains/{t}",
                 headers={"x-apikey": API_KEYS["virustotal"]})
        if "data" in vt:
            a = vt["data"].get("attributes",{})
            st = a.get("last_analysis_stats",{})
            cats = list(a.get("categories",{}).values())
            out["🦠 VirusTotal"] = {
                "Zararlı": st.get("malicious",0),
                "Şüpheli": st.get("suspicious",0),
                "Temiz": st.get("harmless",0),
                "İtibar Skoru": a.get("reputation",0),
                "Kategoriler": ", ".join(cats[:5]),
                "Son Analiz": a.get("last_analysis_date",""),
                "__score": {"val": st.get("malicious",0)+st.get("suspicious",0), "max": 10, "label": "Tehdit Seviyesi"},
            }
    # 6. SecurityTrails
    if API_KEYS.get("securitytrails"):
        st = req(f"https://api.securitytrails.com/v1/domain/{t}",
                 headers={"apikey": API_KEYS["securitytrails"]})
        if "current_dns" in st:
            cdns = st["current_dns"]
            rows = []
            for rtype, rdata in cdns.items():
                for rec in rdata.get("values",[]):
                    rows.append(f"{rtype.upper()}: {rec.get('ip',rec.get('hostname',rec.get('value','')))} (TTL {rec.get('ttl','')})")
            out["🕵️ SecurityTrails DNS"] = {"__list": rows}
    # 7. HTTP headers
    h = cmd(f"curl -sI --max-time 10 --location 'https://{t}' 2>/dev/null | head -30")
    if h: out["🌐 HTTP Başlıkları"] = {"__terminal": h}
    # 8. SSL sertifika
    ssl_info = cmd(f"echo | openssl s_client -connect {t}:443 -servername {t} 2>/dev/null | openssl x509 -noout -text 2>/dev/null | head -30")
    if ssl_info and "CERTIFICATE" in ssl_info:
        out["🔐 SSL Sertifika"] = {"__terminal": ssl_info}
    # 9. Wayback
    wb = req(f"https://archive.org/wayback/available?url={t}")
    if "archived_snapshots" in wb and wb["archived_snapshots"].get("closest"):
        snap = wb["archived_snapshots"]["closest"]
        out["📦 Wayback Machine"] = {
            "Mevcut": snap.get("available",False),
            "Snapshot URL": snap.get("url",""),
            "Zaman": snap.get("timestamp",""),
        }
    return out

def mod_email(t):
    out = {}
    # 1. EmailRep
    d = req(f"https://emailrep.io/{t}", headers={"User-Agent":"phantom-osint-v4"})
    if "_error" not in d and "reputation" in d:
        det = d.get("details",{})
        out["📊 EmailRep Analiz"] = {
            "İtibar": d.get("reputation",""),
            "Şüpheli": d.get("suspicious",False),
            "Referans Sayısı": d.get("references",0),
            "Domain Var mı": det.get("domain_exists",False),
            "Disposable": det.get("disposable",False),
            "Ücretsiz Sağlayıcı": det.get("free_provider",False),
            "Geçerli MX": det.get("valid_mx",False),
            "SPF Strict": det.get("spf_strict",False),
            "DMARC Uygulanıyor": det.get("dmarc_enforced",False),
            "Profil Fotoğrafı": det.get("profile_photo",False),
            "Son Göründüğü": det.get("last_seen_sending",""),
            "Veri İhlali Geçmişi": det.get("data_breach",False),
            "Profiller": ", ".join(det.get("profiles",[])),
        }
    # 2. Hunter doğrulama
    if API_KEYS.get("hunter"):
        h = req(f"https://api.hunter.io/v2/email-verifier?email={t}&api_key={API_KEYS['hunter']}")
        if "data" in h:
            hd = h["data"]
            out["🎯 Hunter.io Doğrulama"] = {
                "Durum": hd.get("status",""),
                "Sonuç": hd.get("result",""),
                "Puan": hd.get("score",0),
                "Regex Geçerli": hd.get("regexp",False),
                "Gibberish": hd.get("gibberish",False),
                "Disposable": hd.get("disposable",False),
                "Webmail": hd.get("webmail",False),
                "MX Kayıtları": hd.get("mx_records",False),
                "SMTP Sunucu": hd.get("smtp_server",False),
                "SMTP Kontrol": hd.get("smtp_check",False),
                "__score": {"val": hd.get("score",0), "max": 100, "label": "Doğrulama Puanı"},
            }
    # 3. HIBP
    if API_KEYS.get("hibp"):
        hib = req(f"https://haveibeenpwned.com/api/v3/breachedaccount/{urllib.parse.quote(t)}?truncateResponse=false",
                  headers={"hibp-api-key": API_KEYS["hibp"], "User-Agent":"phantom-osint"})
        if isinstance(hib, list):
            rows = [f"{b['Name']} ({b.get('BreachDate','')}) — {b.get('PwnCount',0):,} hesap" for b in hib[:15]]
            out["💀 HaveIBeenPwned"] = {
                "_count": f"⚠️ {len(hib)} veri ihlali bulundu!",
                "__list": rows
            }
        else:
            out["💀 HaveIBeenPwned"] = {"Sonuç": "✓ Temiz — Hiçbir ihlalde bulunamadı"}
    # 4. Domain DNS
    domain = t.split("@")[1] if "@" in t else ""
    if domain:
        mx = cmd(f"dig +short MX {domain} 2>/dev/null | head -5")
        spf = cmd(f"dig +short TXT {domain} 2>/dev/null | grep spf | head -3")
        out["📮 Domain DNS Kontrolü"] = {
            "Domain": domain,
            "MX Kayıtları": mx or "Bulunamadı",
            "SPF Kaydı": spf or "Bulunamadı",
        }
    # 5. Holehe-style site kontrolü
    import concurrent.futures
    sites = [
        ("Google","https://accounts.google.com/signup/v2/webcontent?Email={e}&flowName=GlifWebSignIn"),
        ("Twitter/X","https://api.twitter.com/i/users/email_available.json?email={e}"),
        ("GitHub","https://github.com/join?email={e}"),
    ]
    found_sites = []
    def chk_site(name, url_tpl):
        try:
            u = url_tpl.format(e=urllib.parse.quote(t))
            r2 = req(u, timeout=6)
            raw = str(r2)
            if any(x in raw.lower() for x in ["taken","exists","already","false","unavailable"]):
                return f"✓ {name} — Kayıtlı olabilir"
        except: pass
        return None
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as ex:
        fs = [ex.submit(chk_site, n, u) for n,u in sites]
        for f in concurrent.futures.as_completed(fs):
            r2 = f.result()
            if r2: found_sites.append(r2)
    if found_sites:
        out["🌐 Site Kayıt Kontrolü"] = {"__list": found_sites}
    return out

def mod_phone(t):
    out = {}
    clean = re.sub(r"[^0-9+]","",t)
    # 1. NumLookup
    d = req(f"https://api.numlookupapi.com/v1/validate/{clean}")
    if "_error" not in d and d:
        out["📞 Numara Doğrulama"] = {
            "Geçerli": d.get("valid",False),
            "Ülke": d.get("country_name",""),
            "Ülke Kodu": d.get("country_code",""),
            "Bölge": d.get("location",""),
            "Taşıyıcı": d.get("carrier",""),
            "Hat Tipi": d.get("line_type",""),
            "Uluslararası Format": d.get("international_format",""),
            "Yerel Format": d.get("local_format",""),
        }
    # 2. Abstract API phone
    d2 = req(f"https://phonevalidation.abstractapi.com/v1/?api_key=a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3&phone={clean}")
    if "_error" not in d2 and d2 and "valid" in d2:
        out["🔬 Abstract API"] = {
            "Geçerli": d2.get("valid",False),
            "Uluslararası": d2.get("format",{}).get("international",""),
            "Yerel": d2.get("format",{}).get("local",""),
            "Ülke": d2.get("country",{}).get("name",""),
            "Taşıyıcı": d2.get("carrier",""),
            "Hat Tipi": d2.get("type",""),
        }
    # 3. Whois XML Phone
    out["🔎 Numara Analizi"] = {
        "Ham Numara": t,
        "Temizlenmiş": clean,
        "Uzunluk": len(clean.replace("+","")),
        "Uluslararası Alan Kodu": clean[:3] if clean.startswith("+") else "Belirtilmemiş",
    }
    # 4. Calleridservice
    d3 = req(f"https://api.callerapi.com/api?api=demo&phone={clean}")
    if "_error" not in d3 and "name" in d3:
        out["👤 Caller ID"] = {
            "İsim": d3.get("name",""),
            "Taşıyıcı": d3.get("carrier",""),
            "Tip": d3.get("type",""),
        }
    return out

def mod_username(t):
    out = {}
    import concurrent.futures
    # WhatsMyName data
    wmn = req("https://raw.githubusercontent.com/WebBreacher/WhatsMyName/main/wmn-data.json", timeout=20)
    found, checked = [], 0
    if "sites" in wmn:
        sites = wmn["sites"]
        checked = len(sites)
        def chk(site):
            try:
                url = site.get("uri_check","").replace("{account}",t)
                if not url: return None
                r2 = urllib.request.Request(url, headers={"User-Agent":"Mozilla/5.0"})
                with urllib.request.urlopen(r2, context=CTX, timeout=6) as resp:
                    if resp.status == 200:
                        body = resp.read().decode("utf-8","replace")
                        em = site.get("e_string","")
                        if em and em in body:
                            return {"platform": site["name"], "url": url, "cat": site.get("category","")}
            except: pass
            return None
        with concurrent.futures.ThreadPoolExecutor(max_workers=20) as ex:
            fts = [ex.submit(chk,s) for s in sites]
            for f in concurrent.futures.as_completed(fts, timeout=45):
                try:
                    r2 = f.result()
                    if r2: found.append(r2)
                except: pass
        found.sort(key=lambda x: x["platform"])
        rows = [f"✅ {f['platform']} | {f['url']}" for f in found]
        out["🔍 Platform Tarama (WhatsMyName)"] = {
            "_count": f"✅ {len(found)} platform bulundu / {checked} kontrol edildi",
            "__list": rows if rows else ["Hiçbir platformda bulunamadı"]
        }
        by_cat = {}
        for f in found:
            c = f.get("cat","Other")
            by_cat.setdefault(c,[]).append(f["platform"])
        if by_cat:
            out["📊 Kategori Dağılımı"] = {k: ", ".join(v) for k,v in sorted(by_cat.items())}
    # Sherlock
    sh = cmd(f"python3 -m sherlock '{t}' --timeout 8 --print-found 2>/dev/null | head -50")
    if sh and "usage" not in sh.lower() and len(sh) > 10:
        out["🕵️ Sherlock"] = {"__terminal": sh}
    # Profil linkleri
    profiles = {
        "Twitter/X": f"https://twitter.com/{t}",
        "Instagram": f"https://instagram.com/{t}",
        "GitHub": f"https://github.com/{t}",
        "Reddit": f"https://reddit.com/u/{t}",
        "TikTok": f"https://tiktok.com/@{t}",
        "Telegram": f"https://t.me/{t}",
        "YouTube": f"https://youtube.com/@{t}",
        "LinkedIn": f"https://linkedin.com/in/{t}",
        "Pinterest": f"https://pinterest.com/{t}",
        "Twitch": f"https://twitch.tv/{t}",
        "Steam": f"https://steamcommunity.com/id/{t}",
        "DeviantArt": f"https://deviantart.com/{t}",
        "Flickr": f"https://flickr.com/people/{t}",
        "Keybase": f"https://keybase.io/{t}",
    }
    out["🌐 Profil Linkleri (Inline Kontrol)"] = {"__profiles": profiles}
    return out

def mod_url(t):
    out = {}
    if not t.startswith("http"): t = "https://" + t
    # 1. HTTP başlıklar + redirect zinciri
    h = cmd(f"curl -sIL --max-time 12 '{t}' 2>/dev/null | head -50")
    if h: out["🌐 HTTP Başlık & Redirect"] = {"__terminal": h}
    # 2. VirusTotal URL
    if API_KEYS.get("virustotal"):
        uid = base64.urlsafe_b64encode(t.encode()).decode().strip("=")
        vt = req(f"https://www.virustotal.com/api/v3/urls/{uid}",
                 headers={"x-apikey": API_KEYS["virustotal"]})
        if "data" in vt:
            a = vt["data"].get("attributes",{})
            st = a.get("last_analysis_stats",{})
            out["🦠 VirusTotal URL"] = {
                "Zararlı": st.get("malicious",0),
                "Şüpheli": st.get("suspicious",0),
                "Temiz": st.get("harmless",0),
                "Son Analiz": a.get("last_analysis_date",""),
                "__score": {"val": st.get("malicious",0)+st.get("suspicious",0), "max": 10, "label": "Tehdit Seviyesi"},
            }
    # 3. URLScan
    if API_KEYS.get("urlscan"):
        payload = json.dumps({"url":t,"visibility":"public"}).encode()
        r2 = req("https://urlscan.io/api/v1/scan/", method="POST",
                 headers={"API-Key":API_KEYS["urlscan"],"Content-Type":"application/json"},
                 data=payload)
        if "uuid" in r2:
            out["🔭 URLScan.io"] = {
                "UUID": r2.get("uuid",""),
                "Sonuç URL": r2.get("result",""),
                "API URL": r2.get("api",""),
                "Görünürlük": r2.get("visibility",""),
            }
    # 4. Wayback
    wb = req(f"https://archive.org/wayback/available?url={urllib.parse.quote(t)}")
    if "archived_snapshots" in wb and wb["archived_snapshots"].get("closest"):
        sn = wb["archived_snapshots"]["closest"]
        out["📦 Wayback Machine"] = {
            "Arşiv Mevcut": sn.get("available",False),
            "Arşiv URL": sn.get("url",""),
            "Zaman Damgası": sn.get("timestamp",""),
        }
    # 5. URL metadata
    parsed = urllib.parse.urlparse(t)
    out["🔗 URL Analizi"] = {
        "Scheme": parsed.scheme,
        "Domain": parsed.netloc,
        "Path": parsed.path,
        "Query": parsed.query,
        "Fragment": parsed.fragment,
    }
    # 6. Website içerik başlık
    content = cmd(f"curl -sL --max-time 12 '{t}' 2>/dev/null | python3 -c \"\nimport sys,re\nb=sys.stdin.read(8192)\nt=re.findall(r'<title[^>]*>(.*?)</title>',b,re.I|re.S)\nd=re.findall(r'<meta[^>]+name=[\\\"']description[\\\"'][^>]+content=[\\\"'](.*?)[\\\"']',b,re.I)\nprint('Başlık:',t[0][:150] if t else 'Bulunamadı')\nprint('Açıklama:',d[0][:200] if d else 'Bulunamadı')\n\"")
    if content: out["📄 Sayfa Metadata"] = {"__terminal": content}
    return out

def mod_breach(t):
    out = {}
    # 1. Breach Directory
    bd = req(f"https://breachdirectory.org/api?func=auto&term={urllib.parse.quote(t)}")
    if "result" in bd and bd["result"]:
        rows = []
        for r2 in bd["result"][:20]:
            if isinstance(r2, dict):
                rows.append(f"{r2.get('sources','?')} | Şifre: {'✓' if r2.get('password') else '—'} | Hash: {r2.get('sha1','')[:20]}...")
            else:
                rows.append(str(r2))
        out["💀 Breach Directory"] = {
            "_count": f"⚠️ {bd.get('found',0)} kayıt bulundu",
            "__list": rows
        }
    elif bd.get("found") == 0:
        out["💀 Breach Directory"] = {"Sonuç": "✓ Temiz — İhlal bulunamadı"}
    # 2. HIBP
    if API_KEYS.get("hibp"):
        hib = req(f"https://haveibeenpwned.com/api/v3/breachedaccount/{urllib.parse.quote(t)}?truncateResponse=false",
                  headers={"hibp-api-key": API_KEYS["hibp"], "User-Agent":"phantom-osint"})
        if isinstance(hib, list):
            rows2 = [f"{b['Name']} | {b.get('BreachDate','')} | {b.get('PwnCount',0):,} hesap | {','.join(b.get('DataClasses',[])[:3])}" for b in hib[:15]]
            out["🔑 HaveIBeenPwned"] = {
                "_count": f"⚠️ {len(hib)} ihlal tespit edildi",
                "__list": rows2
            }
        else:
            out["🔑 HaveIBeenPwned"] = {"Sonuç": "✓ Temiz"}
    # 3. LeakCheck
    if API_KEYS.get("leakcheck"):
        lc = req(f"https://leakcheck.io/api/public?key={API_KEYS['leakcheck']}&check={urllib.parse.quote(t)}")
        if "result" in lc:
            out["🔐 LeakCheck"] = {"Sonuç": json.dumps(lc.get("result",[]), ensure_ascii=False)[:500]}
    # 4. Hash arama (SHA1/MD5)
    if re.match(r'^[a-f0-9]{32}$',t,re.I) or re.match(r'^[a-f0-9]{40}$',t,re.I):
        out["🔐 Hash Arama"] = {
            "Tip": "MD5" if len(t)==32 else "SHA1",
            "Hash": t,
            "CrackStation": f"https://crackstation.net/ (hash: {t})",
            "HashKiller": f"https://hashkiller.io/listmanager",
        }
    return out

def mod_network(t):
    out = {}
    nmap_full = cmd(f"nmap -T4 -sV -sC --top-ports 200 -Pn {t} 2>/dev/null | head -80")
    out["🔍 Nmap Tam Tarama"] = {"__terminal": nmap_full}
    tr = cmd(f"traceroute -m 15 -w 2 {t} 2>/dev/null || tracepath -m 15 {t} 2>/dev/null")
    out["🛣️ Traceroute"] = {"__terminal": tr}
    # SSL
    ssl_scan = cmd(f"echo | openssl s_client -connect {t}:443 2>/dev/null | head -20")
    if ssl_scan: out["🔐 SSL/TLS"] = {"__terminal": ssl_scan}
    # Banner grab
    banner = cmd(f"nc -w 3 {t} 80 <<< 'HEAD / HTTP/1.0\r\n\r\n' 2>/dev/null | head -10")
    if banner: out["📋 Banner Grab"] = {"__terminal": banner}
    return out

def mod_image(filepath):
    out = {}
    exif_r = cmd(f"exiftool '{filepath}' 2>/dev/null")
    if exif_r and "not found" not in exif_r:
        d = {}
        for line in exif_r.split("\n"):
            if ":" in line:
                k,v = line.split(":",1)
                d[k.strip()] = v.strip()
        # GPS extraction
        lat = d.get("GPS Latitude",""); lon = d.get("GPS Longitude","")
        gps_lat = d.get("GPS Latitude Ref",""); gps_lon = d.get("GPS Longitude Ref","")
        if lat and lon:
            d["🗺️ Harita Linki"] = f"https://www.google.com/maps?q={lat}{gps_lat},{lon}{gps_lon}"
        out["📷 EXIF Verisi"] = d
    else:
        py_exif = cmd(f"""python3 -c "
try:
    from PIL import Image
    from PIL.ExifTags import TAGS
    img=Image.open('{filepath}')
    ex=img._getexif()
    if ex:
        for k,v in list(ex.items())[:30]:
            print(f'{{TAGS.get(k,k)}}: {{str(v)[:100]}}')
    else: print('EXIF bulunamadı')
except Exception as e: print(f'Hata: {{e}}')
" 2>/dev/null""")
        out["📷 EXIF (Python)"] = {"__terminal": py_exif or "EXIF okunamadı"}
    # File info
    file_info = cmd(f"file '{filepath}' 2>/dev/null; ls -lh '{filepath}' 2>/dev/null")
    out["📁 Dosya Bilgisi"] = {"__terminal": file_info}
    return out

def mod_github(t):
    out = {}
    # GitHub user
    u = req(f"https://api.github.com/users/{t}", headers={"Accept":"application/vnd.github.v3+json"})
    if "login" in u:
        out["👤 GitHub Profil"] = {
            "Login": u.get("login",""),
            "İsim": u.get("name",""),
            "Bio": u.get("bio",""),
            "Şirket": u.get("company",""),
            "Lokasyon": u.get("location",""),
            "E-posta": u.get("email",""),
            "Blog/Web": u.get("blog",""),
            "Twitter": u.get("twitter_username",""),
            "Public Repo": u.get("public_repos",0),
            "Followers": u.get("followers",0),
            "Following": u.get("following",0),
            "Üyelik Tarihi": u.get("created_at",""),
            "Son Aktivite": u.get("updated_at",""),
        }
        # Repos
        repos = req(f"https://api.github.com/users/{t}/repos?sort=updated&per_page=10")
        if isinstance(repos, list):
            rows = [f"⭐{r.get('stargazers_count',0):4d} | {r.get('name','')} | {r.get('language','')} | {r.get('description','')[:60]}" for r in repos]
            out["📦 Repolar"] = {"__list": rows}
        # Events (recent activity)
        evts = req(f"https://api.github.com/users/{t}/events/public?per_page=10")
        if isinstance(evts, list):
            erows = [f"{e.get('type','')} → {e.get('repo',{}).get('name','')} ({e.get('created_at','')[:10]})" for e in evts]
            out["📅 Son Aktiviteler"] = {"__list": erows}
    # Code search
    search = req(f"https://api.github.com/search/code?q={urllib.parse.quote(t)}+in:file&per_page=8",
                 headers={"Accept":"application/vnd.github.v3+json"})
    if "items" in search:
        srows = [f"{i.get('repository',{}).get('full_name','')} / {i.get('name','')} → {i.get('html_url','')}" for i in search["items"]]
        out["🔍 Kod Araması"] = {"__list": srows}
    return out

def mod_crypto(t):
    out = {}
    clean = t.strip()
    # Bitcoin address
    if re.match(r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$|^bc1[a-z0-9]{39,59}$', clean):
        d = req(f"https://blockchain.info/rawaddr/{clean}?limit=10")
        if "address" in d:
            out["₿ Bitcoin Adres"] = {
                "Adres": d.get("address",""),
                "Hash160": d.get("hash160",""),
                "Toplam Alınan": f"{d.get('total_received',0)/1e8:.8f} BTC",
                "Toplam Gönderilen": f"{d.get('total_sent',0)/1e8:.8f} BTC",
                "Son Bakiye": f"{d.get('final_balance',0)/1e8:.8f} BTC",
                "İşlem Sayısı": d.get("n_tx",0),
            }
            txs = d.get("txs",[])
            if txs:
                tx_rows = []
                for tx in txs[:8]:
                    val = sum([o.get("value",0) for o in tx.get("out",[])])/1e8
                    tx_rows.append(f"Hash: {tx.get('hash','')[:20]}... | {val:.4f} BTC | {tx.get('time','')}")
                out["💸 Son İşlemler"] = {"__list": tx_rows}
    # Ethereum
    if re.match(r'^0x[a-fA-F0-9]{40}$', clean):
        if API_KEYS.get("etherscan"):
            bal = req(f"https://api.etherscan.io/api?module=account&action=balance&address={clean}&tag=latest&apikey={API_KEYS['etherscan']}")
            txcount = req(f"https://api.etherscan.io/api?module=proxy&action=eth_getTransactionCount&address={clean}&tag=latest&apikey={API_KEYS['etherscan']}")
            txlist = req(f"https://api.etherscan.io/api?module=account&action=txlist&address={clean}&startblock=0&endblock=99999999&sort=desc&page=1&offset=10&apikey={API_KEYS['etherscan']}")
            if bal.get("status")=="1":
                out["⟠ Ethereum Adres"] = {
                    "Adres": clean,
                    "Bakiye (Wei)": bal.get("result",""),
                    "Bakiye (ETH)": f"{int(bal.get('result',0))/1e18:.6f} ETH",
                    "İşlem Sayısı": int(txcount.get("result","0x0"),16) if txcount.get("result") else 0,
                }
            if "result" in txlist and isinstance(txlist["result"], list):
                erows = [f"{tx.get('hash','')[:18]}... | {int(tx.get('value',0))/1e18:.4f} ETH | {tx.get('from','')[:12]}→{tx.get('to','')[:12]}" for tx in txlist["result"][:8]]
                out["💸 ETH İşlemler"] = {"__list": erows}
        else:
            out["⟠ Ethereum"] = {"Not": "Etherscan API key gerekli"}
    # OFAC/sanctions check
    out["⚖️ Sanction Kontrolü"] = {
        "OFAC": f"Manuel kontrol: https://sanctionssearch.ofac.treas.gov/",
        "Elliptic": "https://www.elliptic.co",
        "Chainalysis": "https://www.chainalysis.com",
        "Hedef": clean,
    }
    return out

def mod_social(t):
    out = {}
    # Twitter/X hızlı kontrol
    tw = cmd(f"curl -sA 'Mozilla/5.0' 'https://api.twitter.com/i/users/email_available.json?email={urllib.parse.quote(t)}' 2>/dev/null")
    if tw: out["🐦 Twitter/X API"] = {"__terminal": tw}
    # Instagram
    if re.match(r'^[a-zA-Z0-9._]+$', t):
        ig = cmd(f"curl -sA 'Mozilla/5.0' 'https://www.instagram.com/{t}/?__a=1&__d=dis' 2>/dev/null | python3 -c \"import sys,json,re; b=sys.stdin.read(); data=re.findall(r'window._sharedData\s*=\s*({{.*?}})\s*;',b); print(data[0][:500] if data else 'Veri bulunamadı')\" 2>/dev/null")
        if ig and len(ig) > 5: out["📸 Instagram"] = {"__terminal": ig[:300]}
    # LinkedIn
    out["💼 LinkedIn Arama"] = {
        "Profil Ara": f"https://linkedin.com/search/results/people/?keywords={urllib.parse.quote(t)}",
        "Şirket Ara": f"https://linkedin.com/search/results/companies/?keywords={urllib.parse.quote(t)}",
        "Not": "LinkedIn panel içinde doğrudan iframe ile gösterilir",
    }
    # Reddit
    rdt = req(f"https://www.reddit.com/user/{t}/about.json", headers={"User-Agent":"phantom-osint/4.0"})
    if "data" in rdt:
        rd = rdt["data"]
        out["🤖 Reddit Profil"] = {
            "Kullanıcı Adı": rd.get("name",""),
            "Karma (Post)": rd.get("link_karma",0),
            "Karma (Yorum)": rd.get("comment_karma",0),
            "Hesap Yaşı": rd.get("created_utc",0),
            "Premium": rd.get("is_gold",False),
            "Moderatör": rd.get("is_mod",False),
            "NSFW": rd.get("over_18",False),
        }
        posts = req(f"https://www.reddit.com/user/{t}/submitted.json?limit=10", headers={"User-Agent":"phantom-osint/4.0"})
        if "data" in posts:
            prows = [f"r/{p.get('data',{}).get('subreddit','')} | {p.get('data',{}).get('title','')[:60]}" for p in posts["data"].get("children",[])]
            if prows: out["📝 Reddit Paylaşımlar"] = {"__list": prows}
    return out

def mod_darkweb(t):
    out = {}
    # Ahmia arama (clear web proxy)
    ahmia = req(f"https://ahmia.fi/search/?q={urllib.parse.quote(t)}")
    if "_raw" in ahmia:
        links = re.findall(r'href="(/redirect\?[^"]+)"', ahmia["_raw"])
        onions = re.findall(r'([a-z2-7]{56}\.onion)', ahmia["_raw"])
        out["🧅 Ahmia Tor Araması"] = {
            "_count": f"{len(onions)} .onion adresi bulundu",
            "__list": list(set(onions))[:20]
        }
    # IntelX (ücretsiz)
    intelx = req(f"https://2.intelx.io/intelligent/search?k=test&selector={urllib.parse.quote(t)}&ps=5")
    if "_error" not in intelx:
        out["🔭 IntelX Selector"] = {"Ham": str(intelx)[:400]}
    # Pastebin
    paste = req(f"https://psbdmp.ws/api/v3/search/{urllib.parse.quote(t)}")
    if "data" in paste and isinstance(paste["data"], list):
        prows = [f"ID: {p.get('id','')} | {p.get('time','')} | {p.get('tags','')} | Text: {str(p.get('text',''))[:60]}" for p in paste["data"][:10]]
        out["📋 Pastebin Arama"] = {"__list": prows if prows else ["Bulunamadı"]}
    out["🌑 Dark Web Arama Kaynakları"] = {
        "__list": [
            "Ahmia: https://ahmia.fi (Tor indexer)",
            "IntelX: https://intelx.io (leak DB)",
            "OnionSearch: Termux'ta: python3 OnionSearch",
            "Not: .onion sitelere erişmek için Termux'ta 'pkg install tor' gerekir",
        ]
    }
    return out

def mod_whois_adv(t):
    out = {}
    # Whois CLI
    w = cmd(f"whois {t} 2>/dev/null | head -80")
    out["📜 WHOIS Detay"] = {"__terminal": w}
    # RDAP
    rdap = req(f"https://rdap.verisign.com/com/v1/domain/{t}")
    if "_error" not in rdap and "ldhName" in rdap:
        status = [s for s in rdap.get("status",[])]
        nservers = [n.get("ldhName","") for n in rdap.get("nameservers",[])]
        events = {e.get("eventAction",""):e.get("eventDate","") for e in rdap.get("events",[])}
        out["🌐 RDAP Kayıt Bilgisi"] = {
            "Domain": rdap.get("ldhName",""),
            "Durum": ", ".join(status),
            "Name Servers": ", ".join(nservers),
            "Kayıt Tarihi": events.get("registration",""),
            "Son Güncelleme": events.get("last changed",""),
            "Bitiş Tarihi": events.get("expiration",""),
        }
    # DomainTools free
    dt = req(f"https://api.domainsdb.info/v1/domains/search?domain={t}&zone=com")
    if "domains" in dt and dt["domains"]:
        d = dt["domains"][0]
        out["📊 Domain DB"] = {
            "Domain": d.get("domain",""),
            "Create Date": d.get("create_date",""),
            "Update Date": d.get("update_date",""),
            "Ülke": d.get("country",""),
            "isDead": d.get("isDead",""),
        }
    return out

def mod_news(t):
    out = {}
    # GDELT
    gdelt = req(f"https://api.gdeltproject.org/api/v2/doc/doc?query={urllib.parse.quote(t)}&mode=artlist&maxrecords=10&format=json")
    if "articles" in gdelt:
        rows = [f"[{a.get('seendate','')[:8]}] {a.get('title','')} — {a.get('domain','')}" for a in gdelt["articles"][:10]]
        out["📰 GDELT Haber Araması"] = {
            "_count": f"{len(gdelt['articles'])} haber bulundu",
            "__list": rows
        }
    # HackerNews
    hn = req(f"https://hn.algolia.com/api/v1/search?query={urllib.parse.quote(t)}&tags=story&hitsPerPage=8")
    if "hits" in hn:
        hnrows = [f"[{h.get('points',0):4d}pts] {h.get('title','')} ({h.get('created_at','')[:10]})" for h in hn["hits"]]
        out["🟠 HackerNews"] = {"__list": hnrows}
    # Reddit search
    rdt = req(f"https://www.reddit.com/search.json?q={urllib.parse.quote(t)}&sort=relevance&limit=8",
              headers={"User-Agent":"phantom-osint/4.0"})
    if "data" in rdt:
        rrows = [f"r/{p['data'].get('subreddit','')} | {p['data'].get('title','')[:70]} ({p['data'].get('score',0)} puan)" for p in rdt["data"].get("children",[]) if "data" in p]
        out["🤖 Reddit Araması"] = {"__list": rrows}
    return out

# ──────────────────────────────────────────────
# HTTP SERVER
# ──────────────────────────────────────────────
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self,*a): pass
    def send_json(self, d, code=200):
        b = json.dumps(d, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header("Content-Type","application/json; charset=utf-8")
        self.send_header("Content-Length",len(b))
        self.send_header("Access-Control-Allow-Origin","*")
        self.end_headers(); self.wfile.write(b)
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin","*")
        self.send_header("Access-Control-Allow-Methods","GET,POST,OPTIONS")
        self.send_header("Access-Control-Allow-Headers","Content-Type")
        self.end_headers()
    def do_GET(self):
        if self.path in ("/","/index.html"):
            p = os.path.join(WD,"index.html")
            b = open(p,"rb").read()
            self.send_response(200)
            self.send_header("Content-Type","text/html; charset=utf-8")
            self.send_header("Content-Length",len(b))
            self.end_headers(); self.wfile.write(b)
        elif self.path == "/api/status":
            tools = {t: bool(cmd(f"which {t} 2>/dev/null").strip()) for t in ["nmap","whois","curl","dig","exiftool","traceroute","nc"]}
            self.send_json({"ok":True,"port":PORT,"tools":tools,"keys":list(API_KEYS.keys())})
        else:
            self.send_response(404); self.end_headers()
    def do_POST(self):
        n = int(self.headers.get("Content-Length",0))
        body = json.loads(self.rfile.read(n).decode()) if n else {}
        p = self.path; res = {"ok":False,"data":{},"error":""}
        try:
            if p=="/api/keys":
                API_KEYS.update({k:v for k,v in body.items() if v})
                save_keys(); res={"ok":True,"data":{"saved":list(body.keys())}}
            elif p=="/api/scan/ip":      res={"ok":True,"data":mod_ip(body["target"])}
            elif p=="/api/scan/domain":  res={"ok":True,"data":mod_domain(body["target"])}
            elif p=="/api/scan/email":   res={"ok":True,"data":mod_email(body["target"])}
            elif p=="/api/scan/phone":   res={"ok":True,"data":mod_phone(body["target"])}
            elif p=="/api/scan/username":res={"ok":True,"data":mod_username(body["target"])}
            elif p=="/api/scan/url":     res={"ok":True,"data":mod_url(body["target"])}
            elif p=="/api/scan/breach":  res={"ok":True,"data":mod_breach(body["target"])}
            elif p=="/api/scan/network": res={"ok":True,"data":mod_network(body["target"])}
            elif p=="/api/scan/github":  res={"ok":True,"data":mod_github(body["target"])}
            elif p=="/api/scan/crypto":  res={"ok":True,"data":mod_crypto(body["target"])}
            elif p=="/api/scan/social":  res={"ok":True,"data":mod_social(body["target"])}
            elif p=="/api/scan/darkweb": res={"ok":True,"data":mod_darkweb(body["target"])}
            elif p=="/api/scan/whois":   res={"ok":True,"data":mod_whois_adv(body["target"])}
            elif p=="/api/scan/news":    res={"ok":True,"data":mod_news(body["target"])}
            elif p=="/api/image":
                data = base64.b64decode(body["data"])
                fp = os.path.join(WD,"img_upload")
                open(fp,"wb").write(data)
                res={"ok":True,"data":mod_image(fp)}
            elif p=="/api/cmd":
                out2 = cmd(body.get("cmd",""), 25)
                res={"ok":True,"data":{"__terminal":out2}}
        except Exception as e:
            res={"ok":False,"error":str(e)}
        self.send_json(res)

srv = http.server.HTTPServer(("127.0.0.1",PORT), H)
srv.serve_forever()
PYEOF

# ═══════════════════════════════════════════════════════
# HTML FRONTEND
# ═══════════════════════════════════════════════════════
cat > "$WD/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<title>PHANTOM OSINT v4</title>
<link href="https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;700;900&family=Rajdhani:wght@300;500;700&display=swap" rel="stylesheet">
<style>
/* ──────────── VARIABLES ──────────── */
:root {
  --c1:#00fff7; --c2:#ff00aa; --c3:#00ff88; --c4:#ff3355;
  --gold:#ffd700; --blue:#00aaff; --orange:#ff8c00;
  --bg:#020c12; --bg2:rgba(0,255,247,.04); --bg3:rgba(0,10,18,.85);
  --br:rgba(0,255,247,.11); --br2:rgba(0,255,247,.22);
  --tx:#8fd8e6; --dim:rgba(0,255,247,.42); --font:'Share Tech Mono',monospace;
}
/* ──────────── RESET ──────────── */
*{margin:0;padding:0;box-sizing:border-box}
html,body{height:100%;overflow:hidden;background:var(--bg);font-family:var(--font);color:var(--tx)}
button,select,input{font-family:var(--font)}

/* ──────────── SCANLINES ──────────── */
body::before{content:'';position:fixed;inset:0;pointer-events:none;z-index:9998;
  background:repeating-linear-gradient(0deg,transparent 0px,transparent 3px,rgba(0,0,0,.05) 3px,rgba(0,0,0,.05) 4px);
  animation:scanA 15s linear infinite}
@keyframes scanA{from{background-position:0 0}to{background-position:0 400px}}
/* ──────────── HEX GRID BACKGROUND ──────────── */
body::after{content:'';position:fixed;inset:0;pointer-events:none;z-index:0;
  background-image:linear-gradient(rgba(0,255,247,.018) 1px,transparent 1px),
    linear-gradient(90deg,rgba(0,255,247,.018) 1px,transparent 1px),
    linear-gradient(rgba(0,255,247,.008) 1px,transparent 1px),
    linear-gradient(90deg,rgba(0,255,247,.008) 1px,transparent 1px);
  background-size:60px 60px,60px 60px,12px 12px,12px 12px}

/* ──────────── SCROLLBAR ──────────── */
::-webkit-scrollbar{width:3px;height:3px}
::-webkit-scrollbar-track{background:transparent}
::-webkit-scrollbar-thumb{background:rgba(0,255,247,.2);border-radius:2px}

/* ══════════════ LOGIN ══════════════ */
#LS{position:fixed;inset:0;z-index:2000;display:flex;align-items:center;justify-content:center;
  background:radial-gradient(ellipse at 50% 35%,rgba(0,30,50,.98) 0%,#020c12 65%);
  transition:opacity .7s,visibility .7s}
#LS.gone{opacity:0;visibility:hidden;pointer-events:none}

.lw{width:min(460px,95vw);position:relative}
/* corner decorators */
.lw::before,.lw::after,.lcorn1,.lcorn2{content:'';position:absolute;width:24px;height:24px;pointer-events:none}
.lw::before{top:0;left:0;border-top:1px solid var(--c2);border-left:1px solid var(--c2)}
.lw::after{bottom:0;right:0;border-bottom:1px solid var(--c2);border-right:1px solid var(--c2)}
.lcorn1{top:0;right:0;border-top:1px solid var(--c1);border-right:1px solid var(--c1)}
.lcorn2{bottom:0;left:0;border-bottom:1px solid var(--c1);border-left:1px solid var(--c1)}

.lbox{border:1px solid rgba(0,255,247,.18);background:rgba(1,8,15,.97);padding:44px 40px 36px;
  box-shadow:0 0 80px rgba(0,255,247,.07),inset 0 0 60px rgba(0,0,0,.5)}
.lhead{text-align:center;margin-bottom:32px}
.leye{display:block;font-size:52px;margin-bottom:12px;
  filter:drop-shadow(0 0 10px var(--c1)) drop-shadow(0 0 25px var(--c2));
  animation:eyeP 4s ease-in-out infinite}
@keyframes eyeP{0%,100%{filter:drop-shadow(0 0 8px var(--c1))}50%{filter:drop-shadow(0 0 30px var(--c1)) drop-shadow(0 0 60px var(--c2)) drop-shadow(0 0 90px rgba(0,255,247,.3))}}
.ltit{font-family:'Orbitron',sans-serif;font-size:30px;font-weight:900;letter-spacing:8px;
  color:var(--c1);text-shadow:0 0 20px var(--c1),0 0 40px rgba(0,255,247,.3);display:block;margin-bottom:6px}
.lver{font-family:'Orbitron',sans-serif;font-size:9px;letter-spacing:5px;color:var(--c2);
  text-shadow:0 0 8px var(--c2)}
.ltag{font-size:10px;letter-spacing:2px;color:var(--dim);margin-top:8px;display:block}
/* divider */
.ldiv{height:1px;background:linear-gradient(90deg,transparent,var(--br2),transparent);margin:26px 0}
.llbl{display:block;font-size:9px;letter-spacing:4px;color:var(--dim);margin-bottom:8px;text-transform:uppercase}
.linp{width:100%;padding:12px 16px;background:rgba(0,255,247,.03);border:1px solid var(--br);
  color:var(--c1);font-size:13px;outline:none;transition:all .3s;letter-spacing:2px;margin-bottom:16px}
.linp:focus{border-color:var(--c1);background:rgba(0,255,247,.06);box-shadow:0 0 20px rgba(0,255,247,.1)}
.linp::placeholder{color:rgba(0,255,247,.18)}
.lbtn{width:100%;padding:14px;background:transparent;border:1px solid var(--c1);
  color:var(--c1);font-family:'Orbitron',sans-serif;font-size:12px;letter-spacing:5px;
  cursor:pointer;overflow:hidden;position:relative;transition:all .3s;margin-top:6px}
.lbtn::before{content:'';position:absolute;inset:0;background:linear-gradient(135deg,transparent 40%,rgba(0,255,247,.08) 50%,transparent 60%);
  transform:translateX(-100%);transition:transform .5s}
.lbtn:hover::before{transform:translateX(100%)}
.lbtn:hover{box-shadow:0 0 30px rgba(0,255,247,.2);text-shadow:0 0 10px var(--c1)}
.lstat{min-height:20px;margin-top:14px;text-align:center;font-size:10px;letter-spacing:2px}
.lstat.e{color:var(--c4)}.lstat.ok{color:var(--c3)}
.lhint{margin-top:22px;border-top:1px solid var(--br);padding-top:16px;font-size:10px;
  color:rgba(0,255,247,.22);letter-spacing:1px;line-height:2}
.lhint b{color:var(--gold)}

/* ══════════════ MAIN LAYOUT ══════════════ */
#MP{display:none;flex-direction:column;height:100vh;z-index:1;position:relative}

/* ── TOPBAR ── */
.topbar{display:flex;align-items:center;gap:12px;padding:9px 20px;
  border-bottom:1px solid var(--br);background:rgba(1,6,14,.93);
  backdrop-filter:blur(12px);flex-shrink:0;z-index:100}
.tb-logo{font-family:'Orbitron',sans-serif;font-weight:900;font-size:14px;
  color:var(--c1);letter-spacing:4px;text-shadow:0 0 12px rgba(0,255,247,.5);white-space:nowrap}
.tb-logo em{color:var(--c2);font-style:normal}
.tb-logo sup{color:var(--gold);font-size:9px;letter-spacing:1px}
.tb-sep{width:1px;height:18px;background:var(--br);flex-shrink:0}
.tb-stat{display:flex;align-items:center;gap:6px;font-size:10px}
.td{width:7px;height:7px;border-radius:50%;background:var(--c3);
  box-shadow:0 0 8px var(--c3);animation:bk 2.5s infinite}
@keyframes bk{0%,100%{opacity:1}50%{opacity:.2}}
.tb-space{flex:1}
.tb-clock{font-family:'Orbitron',sans-serif;font-size:11px;color:var(--gold);letter-spacing:2px}
.tb-user{font-size:10px;color:var(--c2);letter-spacing:2px}
.tbtn{padding:5px 14px;background:transparent;border:1px solid var(--br);color:var(--dim);
  font-size:10px;letter-spacing:1px;cursor:pointer;transition:all .2s;white-space:nowrap}
.tbtn:hover{border-color:var(--c1);color:var(--c1);box-shadow:0 0 10px rgba(0,255,247,.1)}
.tbtn.danger:hover{border-color:var(--c4);color:var(--c4)}

/* ── BODY ── */
.body{display:flex;flex:1;overflow:hidden}

/* ══════════════ SIDEBAR ══════════════ */
.sidebar{width:215px;flex-shrink:0;border-right:1px solid var(--br);
  background:rgba(1,5,12,.88);display:flex;flex-direction:column;overflow:hidden}
.sb-top{padding:12px 14px 6px;flex-shrink:0}
.sb-search{width:100%;padding:7px 10px;background:rgba(0,255,247,.03);border:1px solid var(--br);
  color:var(--c1);font-size:11px;outline:none;letter-spacing:1px}
.sb-search::placeholder{color:rgba(0,255,247,.18)}
.sb-search:focus{border-color:var(--c1)}
.sb-scroll{flex:1;overflow-y:auto;padding-bottom:10px}
.sbg{font-size:8.5px;letter-spacing:3px;color:var(--c2);padding:12px 14px 5px;
  display:flex;align-items:center;gap:8px;opacity:.7}
.sbg::after{content:'';flex:1;height:1px;background:var(--br)}
.sbi{display:flex;align-items:center;gap:9px;padding:8px 14px 8px 18px;cursor:pointer;
  font-size:11px;color:var(--tx);transition:all .18s;position:relative;
  border-left:2px solid transparent;user-select:none}
.sbi:hover{background:rgba(0,255,247,.04);color:var(--c1)}
.sbi.act{background:rgba(0,255,247,.07);color:var(--c1);border-left-color:var(--c1)}
.sbi.act::before{content:'';position:absolute;right:0;top:0;bottom:0;width:1px;
  background:rgba(0,255,247,.2)}
.sbi-ic{font-size:13px;flex-shrink:0;width:17px;text-align:center}
.sbi-tx{flex:1;letter-spacing:.3px}
.sbi-dot{width:5px;height:5px;border-radius:50%;flex-shrink:0;margin-left:2px}
.sbi-dot.live{background:var(--c3);box-shadow:0 0 5px var(--c3)}
.sbi-dot.ref{background:rgba(0,255,247,.2)}
/* scan count badge */
.sbc{font-size:8px;padding:1px 5px;background:rgba(0,255,247,.08);
  color:var(--dim);border:1px solid var(--br);letter-spacing:1px}

/* ══════════════ CONTENT ══════════════ */
.content{flex:1;overflow:hidden;display:flex;flex-direction:column}

/* ── INPUT ZONE ── */
.inputzone{padding:13px 18px;border-bottom:1px solid var(--br);
  background:rgba(1,6,12,.8);flex-shrink:0}
.iz-title{font-family:'Orbitron',sans-serif;font-size:11px;letter-spacing:3px;
  color:var(--c1);margin-bottom:10px;display:flex;align-items:center;gap:10px;opacity:.9}
.iz-title::after{content:'';flex:1;height:1px;background:linear-gradient(90deg,var(--br),transparent)}
.iz-row{display:flex;gap:8px;flex-wrap:wrap;align-items:stretch}
.iz-inp{flex:1;min-width:180px;padding:10px 15px;background:rgba(0,255,247,.035);
  border:1px solid var(--br);color:var(--c1);font-size:13px;outline:none;
  transition:all .3s;letter-spacing:1px}
.iz-inp:focus{border-color:var(--c1);background:rgba(0,255,247,.06);box-shadow:0 0 15px rgba(0,255,247,.08)}
.iz-inp::placeholder{color:rgba(0,255,247,.2)}
.iz-sel{padding:10px 12px;background:rgba(0,255,247,.03);border:1px solid var(--br);
  color:var(--tx);font-size:11px;outline:none;cursor:pointer;letter-spacing:.5px}
.iz-sel option{background:#020c12}
.scan-btn{padding:10px 22px;background:rgba(0,255,247,.07);border:1px solid var(--c1);
  color:var(--c1);font-family:'Orbitron',sans-serif;font-size:11px;letter-spacing:3px;
  cursor:pointer;white-space:nowrap;position:relative;overflow:hidden;transition:all .25s}
.scan-btn::after{content:'';position:absolute;inset:0;background:rgba(0,255,247,.06);
  transform:scaleX(0);transform-origin:left;transition:transform .3s}
.scan-btn.go::after{transform:scaleX(1);animation:progA 1.8s ease infinite}
@keyframes progA{0%,100%{opacity:.5}50%{opacity:1}}
.scan-btn:hover{box-shadow:0 0 22px rgba(0,255,247,.18)}
.img-btn,.clr-btn{padding:10px 13px;background:transparent;border:1px solid var(--br);
  color:var(--dim);font-size:11px;cursor:pointer;transition:all .2s;white-space:nowrap}
.img-btn:hover{border-color:var(--gold);color:var(--gold)}
.clr-btn:hover{border-color:var(--c4);color:var(--c4)}
#fi{display:none}

/* ── RESULTS ── */
.results{flex:1;overflow-y:auto;padding:16px 18px 20px;display:flex;flex-direction:column;gap:10px}

/* ── EMPTY STATE ── */
.empty{display:flex;flex-direction:column;align-items:center;justify-content:center;
  height:100%;gap:16px;opacity:.5;pointer-events:none}
.em-eye{font-size:64px;filter:drop-shadow(0 0 20px var(--c1));animation:eyeP 5s infinite}
.em-t1{font-family:'Orbitron',sans-serif;font-size:13px;letter-spacing:4px;color:var(--c1)}
.em-t2{font-size:10px;letter-spacing:3px;color:var(--dim)}
.em-cats{display:flex;flex-wrap:wrap;gap:6px;justify-content:center;max-width:500px;margin-top:8px}
.em-cat{font-size:9px;padding:3px 10px;border:1px solid var(--br);color:rgba(0,255,247,.3);letter-spacing:1px}

/* ── RESULT BLOCK ── */
.rblock{border:1px solid var(--br);background:rgba(0,8,15,.7);
  animation:blockIn .35s ease both;overflow:hidden}
@keyframes blockIn{from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:translateY(0)}}
.rbh{display:flex;align-items:center;gap:10px;padding:11px 16px;
  border-bottom:1px solid var(--br);cursor:pointer;user-select:none;background:rgba(0,255,247,.02)}
.rbh:hover{background:rgba(0,255,247,.04)}
.rbi{font-size:16px}
.rbt{font-family:'Rajdhani',sans-serif;font-size:14px;font-weight:700;
  color:#e4f9ff;letter-spacing:.8px;flex:1}
.rbt em{color:var(--c1);font-style:normal}
.rb-ms{font-size:9px;color:var(--dim);letter-spacing:2px;padding:2px 8px;border:1px solid var(--br)}
.rb-arr{color:var(--dim);font-size:12px;transition:transform .2s}
.rb-arr.open{transform:rotate(180deg)}
/* modules grid */
.rb-body{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:8px;padding:12px}
.rb-body.hide{display:none}

/* ── MODULE CARD ── */
.mc{border:1px solid rgba(0,255,247,.07);background:rgba(0,5,10,.6);padding:12px 14px;
  transition:border-color .2s}
.mc:hover{border-color:rgba(0,255,247,.18)}
.mc.full{grid-column:1/-1}
.mc-key{font-size:8.5px;letter-spacing:3px;color:var(--c2);margin-bottom:8px;
  display:flex;align-items:center;gap:8px}
.mc-key::after{content:'';flex:1;height:1px;background:rgba(255,0,170,.1)}
.mc-cnt{font-size:12px;color:#d0f0fa;line-height:1.65}
/* KV fields */
.kv{display:flex;flex-direction:column;gap:4px}
.kv-row{display:flex;gap:8px;align-items:baseline;padding:3px 0;
  border-bottom:1px solid rgba(0,255,247,.04)}
.kv-row:last-child{border-bottom:none}
.kv-k{font-size:9px;letter-spacing:2px;color:var(--dim);flex-shrink:0;min-width:120px;text-transform:uppercase}
.kv-v{font-size:12px;color:#cef5fa;word-break:break-all;flex:1}
.kv-v.good{color:var(--c3)} .kv-v.bad{color:var(--c4)} .kv-v.warn{color:var(--gold)}
/* terminal output */
.term{font-size:10.5px;color:rgba(0,255,136,.85);background:rgba(0,0,0,.4);
  padding:10px;white-space:pre-wrap;overflow-y:auto;max-height:220px;line-height:1.55;
  border:1px solid rgba(0,255,136,.08)}
/* list */
.lst{list-style:none;display:flex;flex-direction:column;gap:2px}
.lst li{font-size:11px;color:#b8ebf5;padding:3px 0;border-bottom:1px solid rgba(0,255,247,.04);
  word-break:break-all;display:flex;gap:6px;align-items:flex-start}
.lst li::before{content:'◈';color:var(--c2);font-size:8px;flex-shrink:0;margin-top:3px}
/* score bar */
.sbar{height:5px;background:rgba(0,255,247,.08);margin-top:6px}
.sbar-f{height:100%;transition:width 1s ease}
/* count badge */
.cnt-badge{display:inline-block;padding:2px 8px;font-size:9px;letter-spacing:2px;
  border-radius:1px;margin-bottom:8px}
.cnt-badge.warn{background:rgba(255,51,85,.1);border:1px solid var(--c4);color:var(--c4)}
.cnt-badge.good{background:rgba(0,255,136,.08);border:1px solid var(--c3);color:var(--c3)}
/* profiles */
.prof-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(130px,1fr));gap:6px;margin-top:4px}
.prof-item{padding:6px 10px;border:1px solid var(--br);background:rgba(0,255,247,.03);
  display:flex;flex-direction:column;gap:3px;cursor:pointer;transition:all .2s;position:relative}
.prof-item:hover{border-color:rgba(0,255,247,.3);background:rgba(0,255,247,.07)}
.prof-item .pname{font-size:10px;letter-spacing:1px;color:var(--c1)}
.prof-item .pcheck{font-size:9px;color:var(--dim)}
.prof-item .pok{color:var(--c3)}

/* ── STATUS BAR ── */
.stbar{padding:7px 18px;border-top:1px solid var(--br);background:rgba(1,4,10,.95);
  display:flex;gap:20px;align-items:center;flex-shrink:0;font-size:10px;letter-spacing:1px}
.sv{color:var(--c1);font-weight:bold;font-size:12px}
.sl{color:rgba(0,255,247,.3)}
.stbar-r{margin-left:auto;display:flex;gap:10px}
.tool-ind{display:flex;align-items:center;gap:4px}
.ti-d{width:5px;height:5px;border-radius:50%}
.ti-d.on{background:var(--c3);box-shadow:0 0 4px var(--c3)}
.ti-d.off{background:var(--c4);opacity:.4}

/* ── API MODAL ── */
.mov{position:fixed;inset:0;z-index:800;background:rgba(0,0,0,.9);
  display:flex;align-items:center;justify-content:center;opacity:0;visibility:hidden;transition:all .3s}
.mov.open{opacity:1;visibility:visible}
.mbox{width:min(560px,97vw);max-height:90vh;overflow-y:auto;border:1px solid var(--c1);
  background:rgba(1,8,15,.99);padding:28px;position:relative;
  box-shadow:0 0 60px rgba(0,255,247,.1)}
.mbox h3{font-family:'Orbitron',sans-serif;font-size:13px;color:var(--c1);
  letter-spacing:3px;margin-bottom:18px}
.arow{display:flex;align-items:center;gap:8px;margin-bottom:9px}
.albl{font-size:9px;letter-spacing:2px;color:var(--dim);width:140px;flex-shrink:0}
.ainp{flex:1;padding:8px 12px;background:rgba(0,255,247,.03);border:1px solid var(--br);
  color:var(--c1);font-size:12px;outline:none;letter-spacing:1px}
.ainp:focus{border-color:var(--c1)}
.mc-{position:absolute;top:14px;right:14px;background:none;border:none;
  color:var(--dim);font-size:18px;cursor:pointer;transition:color .2s}
.mc-:hover{color:var(--c4)}
.msave{padding:10px 22px;border:1px solid var(--c1);background:rgba(0,255,247,.06);
  color:var(--c1);font-family:'Orbitron',sans-serif;font-size:10px;letter-spacing:3px;
  cursor:pointer;margin-top:14px;transition:all .2s}
.msave:hover{background:rgba(0,255,247,.14)}
.anote{margin-top:14px;padding-top:14px;border-top:1px solid var(--br);
  font-size:10px;color:rgba(0,255,247,.25);line-height:1.9}
.anote a{color:var(--c1)}
/* key status chips */
.kchips{display:flex;flex-wrap:wrap;gap:6px;margin-bottom:16px}
.kchip{font-size:9px;padding:3px 10px;letter-spacing:2px;border-radius:1px}
.kchip.set{border:1px solid var(--c3);color:var(--c3)}
.kchip.unset{border:1px solid var(--br);color:var(--dim)}

/* ── TOAST ── */
.toast{position:fixed;bottom:52px;left:50%;transform:translateX(-50%);
  padding:10px 22px;font-size:11px;letter-spacing:2px;z-index:3000;
  border:1px solid;font-family:var(--font);transition:opacity .3s;
  box-shadow:0 4px 30px rgba(0,0,0,.5)}
.toast.ok{background:rgba(0,10,5,.97);border-color:var(--c3);color:var(--c3)}
.toast.err{background:rgba(15,0,5,.97);border-color:var(--c4);color:var(--c4)}

/* ── RESPONSIVE ── */
@media(max-width:600px){
  .sidebar{display:none}
  .rb-body{grid-template-columns:1fr}
  .iz-row{flex-direction:column}
  .iz-sel,.img-btn,.clr-btn{width:100%}
}
</style>
</head>
<body>

<!-- ══════════════ LOGIN ══════════════ -->
<div id="LS">
<div class="lw">
  <div class="lcorn1"></div><div class="lcorn2"></div>
  <div class="lbox">
    <div class="lhead">
      <span class="leye">👁</span>
      <span class="ltit">PHANTOM</span>
      <span class="lver">OSINT INTELLIGENCE PANEL</span>
      <span class="ltag">v4.0 — ZERO REDIRECTS · ALL DATA INLINE · TERMUX NATIVE</span>
    </div>
    <div class="ldiv"></div>
    <label class="llbl">Operator Kimliği</label>
    <input class="linp" id="lu" type="text" placeholder="operator_id" autocomplete="off" spellcheck="false">
    <label class="llbl">Şifre Anahtarı</label>
    <input class="linp" id="lp" type="password" placeholder="••••••••" autocomplete="off">
    <button class="lbtn" id="lbtn" onclick="doLogin()">◉ KİMLİK DOĞRULA &amp; BAĞLAN</button>
    <div class="lstat" id="lst"></div>
    <div class="lhint">
      Varsayılan Giriş: <b>phantom</b> / <b>osint2024</b><br>
      Misafir: <b>guest</b> / <b>guest</b> &nbsp;|&nbsp; Admin: <b>admin</b> / <b>phantom123</b><br>
      <span style="color:var(--c1)">⚙ API Keys menüsünden ücretsiz key ekleyerek daha fazla veri görün</span>
    </div>
  </div>
</div>
</div>

<!-- ══════════════ MAIN ══════════════ -->
<div id="MP">
  <!-- TOPBAR -->
  <div class="topbar">
    <div class="tb-logo">PH<em>ANT</em>OM <em style="color:var(--gold);font-size:9px;letter-spacing:2px"> OSINT</em><sup>v4</sup></div>
    <div class="tb-sep"></div>
    <div class="tb-stat"><div class="td"></div><span style="color:var(--c3);font-size:10px;letter-spacing:2px">ONLINE</span></div>
    <div class="tb-space"></div>
    <div class="tb-clock" id="clk">00:00:00</div>
    <div class="tb-sep"></div>
    <div class="tb-user" id="tbu">◈ OPERATOR</div>
    <button class="tbtn" onclick="openApiM()">⚙ API KEYS</button>
    <button class="tbtn danger" onclick="clearAll()">⌫ TEMİZLE</button>
  </div>

  <div class="body">
    <!-- SIDEBAR -->
    <div class="sidebar">
      <div class="sb-top">
        <input class="sb-search" id="sbsearch" placeholder="🔍 Modül ara..." oninput="filterSidebar(this.value)">
      </div>
      <div class="sb-scroll" id="SB"></div>
    </div>

    <!-- CONTENT -->
    <div class="content">
      <!-- INPUT ZONE -->
      <div class="inputzone">
        <div class="iz-title" id="iz-title">◈ HEDEF ANALİZİ</div>
        <div class="iz-row">
          <input class="iz-inp" id="tinp" placeholder="IP, domain, e-posta, telefon, kullanıcı adı..." autocomplete="off" spellcheck="false">
          <select class="iz-sel" id="tmod">
            <option value="ip">🌐 IP Analizi</option>
            <option value="domain">🔗 Domain &amp; DNS</option>
            <option value="email">✉️ E-Posta OSINT</option>
            <option value="phone">📞 Telefon OSINT</option>
            <option value="username">👤 Kullanıcı Adı</option>
            <option value="url">🔍 URL Tarama</option>
            <option value="breach">💀 İhlal Araması</option>
            <option value="network">⚡ Ağ Tarama</option>
            <option value="github">🐙 GitHub OSINT</option>
            <option value="crypto">₿ Kripto OSINT</option>
            <option value="social">📱 Sosyal Medya</option>
            <option value="darkweb">🌑 Dark Web</option>
            <option value="whois">📜 WHOIS Detay</option>
            <option value="news">📰 Haber &amp; Medya</option>
          </select>
          <button class="scan-btn" id="sbtn" onclick="runScan()">⚡ TARA</button>
          <button class="img-btn" onclick="document.getElementById('fi').click()">📸 EXIF</button>
          <button class="clr-btn" onclick="clearAll()">✕</button>
          <input type="file" id="fi" accept="image/*" onchange="handleImg(this)">
        </div>
      </div>

      <!-- RESULTS -->
      <div class="results" id="RES">
        <div class="empty" id="empt">
          <div class="em-eye">👁</div>
          <div class="em-t1">PHANTOM OSINT v4.0</div>
          <div class="em-t2">HEDEF GİRİN · MOD SEÇİN · TARAMAYI BAŞLATIN</div>
          <div class="em-cats" id="em-cats"></div>
        </div>
      </div>

      <!-- STATUSBAR -->
      <div class="stbar">
        <span class="sv" id="st-sc">0</span><span class="sl">TARAMA</span>
        <span class="sv" id="st-hi">0</span><span class="sl">HIT</span>
        <span class="sv" id="st-ms">—</span><span class="sl">SÜRE</span>
        <span class="sv" id="st-mo">—</span><span class="sl">MODÜL</span>
        <div class="stbar-r" id="stbar-r"></div>
      </div>
    </div>
  </div>
</div>

<!-- API MODAL -->
<div class="mov" id="apiM" onclick="closeApiM(event)">
<div class="mbox">
  <button class="mc-" onclick="closeApiM()">✕</button>
  <h3>⚙ API KEY YÖNETİMİ</h3>
  <div class="kchips" id="kchips"></div>
  <div class="arow"><span class="albl">SHODAN</span><input class="ainp" id="k-shodan" placeholder="Shodan API key..."></div>
  <div class="arow"><span class="albl">VIRUSTOTAL</span><input class="ainp" id="k-virustotal" placeholder="VirusTotal API key..."></div>
  <div class="arow"><span class="albl">ABUSEIPDB</span><input class="ainp" id="k-abuseipdb" placeholder="AbuseIPDB API key..."></div>
  <div class="arow"><span class="albl">HUNTER.IO</span><input class="ainp" id="k-hunter" placeholder="Hunter.io API key..."></div>
  <div class="arow"><span class="albl">HAVEIBEENPWNED</span><input class="ainp" id="k-hibp" placeholder="HIBP API key..."></div>
  <div class="arow"><span class="albl">URLSCAN.IO</span><input class="ainp" id="k-urlscan" placeholder="URLScan.io API key..."></div>
  <div class="arow"><span class="albl">SECURITYTRAILS</span><input class="ainp" id="k-securitytrails" placeholder="SecurityTrails API key..."></div>
  <div class="arow"><span class="albl">LEAKCHECK</span><input class="ainp" id="k-leakcheck" placeholder="LeakCheck API key..."></div>
  <div class="arow"><span class="albl">ETHERSCAN</span><input class="ainp" id="k-etherscan" placeholder="Etherscan API key..."></div>
  <button class="msave" onclick="saveKeys()">💾 KAYDET</button>
  <div class="anote">
    API key'ler sadece Termux içinde yerel olarak saklanır — asla dışarı gönderilmez.<br>
    Ücretsiz key kaynakları:<br>
    → <a href="https://account.shodan.io/" target="_blank">shodan.io</a> &nbsp;
    → <a href="https://virustotal.com/" target="_blank">virustotal.com</a> &nbsp;
    → <a href="https://www.abuseipdb.com/api" target="_blank">abuseipdb.com</a><br>
    → <a href="https://hunter.io/api-keys" target="_blank">hunter.io</a> &nbsp;
    → <a href="https://haveibeenpwned.com/API/Key" target="_blank">haveibeenpwned.com</a> &nbsp;
    → <a href="https://urlscan.io/api/" target="_blank">urlscan.io</a>
  </div>
</div>
</div>

<script>
// ═══════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════
const CREDS={phantom:"osint2024",admin:"phantom123",guest:"guest"};
let scanCount=0,hitCount=0,activeUser="OPERATOR";
const modeIcons={ip:"🌐",domain:"🔗",email:"✉️",phone:"📞",username:"👤",url:"🔍",
  breach:"💀",network:"⚡",github:"🐙",crypto:"₿",social:"📱",darkweb:"🌑",whois:"📜",news:"📰",image:"📷"};
const modeTitles={ip:"IP & AĞ ANALİZİ",domain:"DOMAIN & DNS KEŞFİ",email:"E-POSTA OSINT",
  phone:"TELEFON OSINT",username:"KULLANICI ADI OSINT",url:"URL & SİTE TARAMA",
  breach:"VERİ İHLALİ ARAMASI",network:"AĞ & PORT TARAMA",github:"GITHUB OSINT",
  crypto:"KRİPTO & BLOCKCHAIN OSINT",social:"SOSYAL MEDYA OSINT",darkweb:"DARK WEB & LEAK",
  whois:"WHOIS & DOMAIN KAYIT",news:"HABER & MEDYA OSINT",image:"GÖRSEL & EXIF ANALİZİ"};

// ═══════════════════════════════════════════
// LOGIN
// ═══════════════════════════════════════════
async function doLogin(){
  const u=document.getElementById("lu").value.trim();
  const p=document.getElementById("lp").value;
  const s=document.getElementById("lst");
  const btn=document.getElementById("lbtn");
  s.className="lstat"; s.textContent="[ BACKEND BAĞLANTI KONTROL EDİLİYOR... ]";
  btn.disabled=true;
  await sleep(400);
  if(!CREDS[u]||CREDS[u]!==p){
    s.className="lstat e"; s.textContent="[ ERİŞİM REDDEDİLDİ — GEÇERSİZ KİMLİK DOĞRULAMA ]";
    document.getElementById("lp").value="";
    btn.disabled=false; return;
  }
  try{
    const r=await fetch("/api/status");
    const d=await r.json();
    if(d.ok){
      s.className="lstat ok"; s.textContent="[ ERİŞİM ONAYLANDI — BACKEND HAZIR ]";
      activeUser=u.toUpperCase();
      await sleep(600);
      document.getElementById("LS").classList.add("gone");
      document.getElementById("MP").style.display="flex";
      initPanel(d.tools||{},d.keys||[]);
    }
  }catch(e){
    s.className="lstat e"; s.textContent="[ BACKEND HATASI: "+e.message+" ]";
    btn.disabled=false;
  }
}
document.addEventListener("keydown",e=>{
  if(e.key==="Enter"&&!document.getElementById("LS").classList.contains("gone"))doLogin();
});

// ═══════════════════════════════════════════
// INIT
// ═══════════════════════════════════════════
function initPanel(tools,keys){
  document.getElementById("tbu").textContent="◈ "+activeUser;
  setInterval(()=>{document.getElementById("clk").textContent=new Date().toLocaleTimeString("tr-TR",{hour12:false})},1000);
  buildSidebar();
  buildStatusBar(tools);
  buildKeyChips(keys);
  buildEmptyCats();
  document.getElementById("tinp").focus();
}

// ═══════════════════════════════════════════
// SIDEBAR
// ═══════════════════════════════════════════
const SIDEBAR_DATA=[
  {grp:"AKTIF MODÜLLER",items:[
    {id:"ip",   ic:"🌐",tx:"IP & Ağ Analizi",   dot:"live"},
    {id:"domain",ic:"🔗",tx:"Domain & DNS",      dot:"live"},
    {id:"email", ic:"✉️",tx:"E-Posta OSINT",     dot:"live"},
    {id:"phone", ic:"📞",tx:"Telefon OSINT",     dot:"live"},
    {id:"username",ic:"👤",tx:"Kullanıcı Adı",   dot:"live"},
    {id:"url",   ic:"🔍",tx:"URL Tarama",        dot:"live"},
    {id:"breach",ic:"💀",tx:"Veri İhlali",       dot:"live"},
    {id:"network",ic:"⚡",tx:"Ağ & Port Tarama", dot:"live"},
    {id:"github",ic:"🐙",tx:"GitHub OSINT",      dot:"live"},
    {id:"crypto",ic:"₿", tx:"Kripto Analizi",    dot:"live"},
    {id:"social",ic:"📱",tx:"Sosyal Medya",      dot:"live"},
    {id:"darkweb",ic:"🌑",tx:"Dark Web & Leak",  dot:"live"},
    {id:"whois", ic:"📜",tx:"WHOIS Detay",       dot:"live"},
    {id:"news",  ic:"📰",tx:"Haber & Medya",     dot:"live"},
    {id:"image", ic:"📷",tx:"EXIF / Görsel",     dot:"live"},
  ]},
  {grp:"OSINT REFERANS ARAÇLARI",items:[
    {id:"r-pipl",   ic:"👤",tx:"Pipl",           ref:"https://pipl.com"},
    {id:"r-maltego",ic:"🕸️",tx:"Maltego",        ref:"https://maltego.com"},
    {id:"r-shodan", ic:"🔭",tx:"Shodan Web",     ref:"https://shodan.io"},
    {id:"r-censys",ic:"🌐",tx:"Censys",          ref:"https://censys.io"},
    {id:"r-intelx", ic:"🕵️",tx:"IntelX",        ref:"https://intelx.io"},
    {id:"r-spiderfoot",ic:"🕷️",tx:"SpiderFoot",  ref:"https://spiderfoot.net"},
    {id:"r-pimeyes",ic:"👁",tx:"PimEyes",        ref:"https://pimeyes.com"},
    {id:"r-osintfr",ic:"🛠️",tx:"OSINT Framework",ref:"https://osintframework.com"},
    {id:"r-bellingcat",ic:"📡",tx:"Bellingcat",  ref:"https://bellingcat.com"},
    {id:"r-marine", ic:"🚢",tx:"MarineTraffic",  ref:"https://marinetraffic.com"},
    {id:"r-flight", ic:"✈️",tx:"FlightRadar24",  ref:"https://flightradar24.com"},
    {id:"r-adsbx",  ic:"✈️",tx:"ADS-B Exchange", ref:"https://globe.adsbexchange.com"},
    {id:"r-opencorp",ic:"🏢",tx:"OpenCorporates",ref:"https://opencorporates.com"},
    {id:"r-wayback",ic:"📦",tx:"Wayback Machine",ref:"https://web.archive.org"},
    {id:"r-tineye", ic:"🖼️",tx:"TinEye",        ref:"https://tineye.com"},
    {id:"r-ahmia",  ic:"🧅",tx:"Ahmia (Tor)",   ref:"https://ahmia.fi"},
    {id:"r-dehashed",ic:"🔑",tx:"DeHashed",     ref:"https://dehashed.com"},
    {id:"r-blockchain",ic:"₿",tx:"Blockchain Explorer",ref:"https://blockchain.com/explorer"},
    {id:"r-etherscan",ic:"⟠",tx:"Etherscan",   ref:"https://etherscan.io"},
    {id:"r-icij",   ic:"📁",tx:"ICIJ Offshore", ref:"https://offshoreleaks.icij.org"},
  ]}
];

function buildSidebar(){
  let h="";
  SIDEBAR_DATA.forEach(g=>{
    h+=`<div class="sbg">${g.grp}</div>`;
    g.items.forEach(i=>{
      const isRef=!!i.ref;
      h+=`<div class="sbi ${isRef?'':'act' === i.id?'act':''}" id="si-${i.id}"
        onclick="${isRef?`openRef('${i.ref}')`:`selMode('${i.id}')`}">
        <span class="sbi-ic">${i.ic}</span>
        <span class="sbi-tx">${i.tx}</span>
        ${i.dot?`<span class="sbi-dot ${i.dot}"></span>`:''}
        ${isRef?'<span style="font-size:8px;color:var(--dim)">↗</span>':''}
      </div>`;
    });
  });
  document.getElementById("SB").innerHTML=h;
  setActive("ip");
}

function filterSidebar(q){
  document.querySelectorAll(".sbi").forEach(el=>{
    const tx=el.textContent.toLowerCase();
    el.style.display=(!q||tx.includes(q.toLowerCase()))?"flex":"none";
  });
}

function setActive(id){
  document.querySelectorAll(".sbi").forEach(el=>el.classList.remove("act"));
  const el=document.getElementById("si-"+id);
  if(el) el.classList.add("act");
}

function selMode(id){
  const modeMap={image:"image"};
  const mode=modeMap[id]||id;
  document.getElementById("tmod").value=mode;
  document.getElementById("iz-title").textContent="◈ "+(modeTitles[mode]||mode.toUpperCase());
  setActive(id);
  const ph={ip:"IP adresi (örn: 8.8.8.8 veya 1.1.1.1)",
    domain:"Domain adı (örn: google.com)",
    email:"E-posta adresi (örn: user@example.com)",
    phone:"Telefon numarası (örn: +905xxxxxxxxx)",
    username:"Kullanıcı adı (örn: johndoe)",
    url:"URL (örn: https://example.com)",
    breach:"E-posta veya kullanıcı adı",
    network:"IP veya domain (nmap + traceroute)",
    github:"GitHub kullanıcı adı veya arama terimi",
    crypto:"Bitcoin/Ethereum cüzdan adresi veya TX hash",
    social:"Kullanıcı adı, isim veya e-posta",
    darkweb:"Arama terimi, e-posta veya domain",
    whois:"Domain adı (örn: example.com)",
    news:"Arama terimi, isim veya olay",
    image:"← 📸 butonuna tıklayın",
  };
  document.getElementById("tinp").placeholder=ph[mode]||"Hedef girin...";
  document.getElementById("tinp").focus();
}

function openRef(url){ window.open(url,"_blank","noopener"); }

function buildEmptyCats(){
  const cats=Object.entries(modeTitles).map(([k,v])=>`<span class="em-cat">${modeIcons[k]} ${v}</span>`).join("");
  document.getElementById("em-cats").innerHTML=cats;
}

// ═══════════════════════════════════════════
// SCAN
// ═══════════════════════════════════════════
document.addEventListener("keydown",e=>{
  if(e.key==="Enter"&&document.getElementById("LS").classList.contains("gone"))runScan();
});

async function runScan(){
  const target=document.getElementById("tinp").value.trim();
  const mode=document.getElementById("tmod").value;
  if(!target){toast("Hedef girin!","err");return;}
  if(mode==="image"){toast("📸 EXIF için görsel yükleyin","err");return;}
  const t0=Date.now();
  const btn=document.getElementById("sbtn");
  btn.classList.add("go"); btn.textContent="◉ TARANIYOR...";
  rmEmpty();
  try{
    const r=await fetch(`/api/scan/${mode}`,{method:"POST",
      headers:{"Content-Type":"application/json"},body:JSON.stringify({target})});
    const d=await r.json();
    const ms=Date.now()-t0;
    if(d.ok){
      renderBlock(mode,target,d.data,ms);
      scanCount++;
      document.getElementById("st-sc").textContent=scanCount;
      document.getElementById("st-ms").textContent=ms+"ms";
      document.getElementById("st-mo").textContent=(modeTitles[mode]||mode).split(" ")[0];
    } else { addErr(d.error||"Bilinmeyen hata"); }
  }catch(e){ addErr(e.message); }
  btn.classList.remove("go"); btn.textContent="⚡ TARA";
}

async function handleImg(inp){
  const file=inp.files[0]; if(!file)return;
  const reader=new FileReader();
  reader.onload=async function(e){
    const b64=e.target.result.split(",")[1];
    const btn=document.getElementById("sbtn");
    btn.classList.add("go"); btn.textContent="◉ EXIF OKUNUYOR...";
    rmEmpty();
    try{
      const r=await fetch("/api/image",{method:"POST",
        headers:{"Content-Type":"application/json"},body:JSON.stringify({data:b64})});
      const d=await r.json();
      if(d.ok) renderBlock("image",file.name,d.data,0);
      else addErr(d.error);
    }catch(e){addErr(e.message);}
    btn.classList.remove("go"); btn.textContent="⚡ TARA";
  };
  reader.readAsDataURL(file); inp.value="";
}

// ═══════════════════════════════════════════
// RENDER ENGINE
// ═══════════════════════════════════════════
function renderBlock(mode,target,data,ms){
  const res=document.getElementById("RES");
  const wrap=document.createElement("div");
  wrap.className="rblock";
  const icon=modeIcons[mode]||"◈";
  const title=modeTitles[mode]||mode.toUpperCase();
  const mcount=Object.keys(data).length;
  wrap.innerHTML=`
    <div class="rbh" onclick="toggleBlock(this)">
      <span class="rbi">${icon}</span>
      <span class="rbt">${title} — <em>${esc(target)}</em></span>
      <span class="rb-ms">${mcount} modül</span>
      <span class="rb-ms">${ms||"—"}ms</span>
      <span class="rb-arr open">▼</span>
    </div>
    <div class="rb-body" id="bd-${Date.now()}">
      ${buildModules(data)}
    </div>`;
  res.insertBefore(wrap,res.firstChild);
  countHits(data);
}

function toggleBlock(hdr){
  const body=hdr.nextElementSibling;
  const arr=hdr.querySelector(".rb-arr");
  body.classList.toggle("hide");
  arr.classList.toggle("open");
}

function buildModules(data){
  return Object.entries(data).map(([key,val])=>{
    if(!val) return "";
    // Full-width modules
    const full=key.includes("terminal")||key.includes("Nmap")||key.includes("WHOIS")||
      key.includes("Traceroute")||key.includes("Liste")||key.includes("Platform")||
      key.includes("Platform")||key.includes("Profil Linkleri")||key.includes("Kategori")||
      key.includes("Haber")||key.includes("Reddit")||key.includes("İşlemler")||
      key.includes("Subdomain")||key.includes("Aktivite")||key.includes("Pastebin")||
      key.includes("Ahmia")||key.includes("Repolar");
    const cls=`mc${full?" full":""}`;
    const body=buildModuleBody(val);
    if(!body.trim()) return "";
    return `<div class="${cls}">
      <div class="mc-key">${esc(key)}</div>
      <div class="mc-cnt">${body}</div>
    </div>`;
  }).join("");
}

function buildModuleBody(val){
  if(!val) return "";
  // Terminal output
  if(val.__terminal){
    return `<div class="term">${esc(val.__terminal)}</div>`;
  }
  // List
  if(val.__list){
    const count=val._count?`<div class="cnt-badge ${val._count.includes('⚠')?"warn":"good"}">${esc(val._count)}</div>`:"";
    const items=(val.__list||[]).filter(Boolean).map(i=>`<li>${esc(String(i))}</li>`).join("");
    return count+`<ul class="lst">${items}</ul>`;
  }
  // Profiles grid
  if(val.__profiles){
    let h=`<div class="prof-grid">`;
    for(const[name,url] of Object.entries(val.__profiles)){
      h+=`<div class="prof-item" onclick="checkProfile('${esc(url)}',this)">
        <span class="pname">${esc(name)}</span>
        <span class="pcheck">kontrol et →</span>
      </div>`;
    }
    h+=`</div>`;
    return h;
  }
  // Score object
  const scoreData=Object.values(val).find(v=>v&&v.label&&v.max!==undefined);
  // Build KV pairs
  let kvHtml=`<div class="kv">`;
  let hasContent=false;
  for(const[k,v] of Object.entries(val)){
    if(k.startsWith("_")) continue;
    if(v===null||v===undefined||v==="") continue;
    const vStr=typeof v==="object"?JSON.stringify(v):String(v);
    const cls=vStr==="true"||vStr.includes("✓")?"good":
               vStr==="false"||vStr.includes("⚠")?"bad":
               /^\d+\/100$/.test(vStr)&&parseInt(vStr)>50?"warn":"";
    kvHtml+=`<div class="kv-row">
      <span class="kv-k">${esc(k)}</span>
      <span class="kv-v ${cls}">${fmtVal(k,vStr)}</span>
    </div>`;
    hasContent=true;
  }
  kvHtml+=`</div>`;
  if(scoreData){
    const pct=Math.min(100,Math.round(scoreData.val/scoreData.max*100));
    const col=pct>60?"var(--c4)":pct>30?"var(--gold)":"var(--c3)";
    kvHtml+=`<div style="margin-top:8px">
      <div style="font-size:9px;color:var(--dim);margin-bottom:4px;letter-spacing:2px">${esc(scoreData.label)}: ${scoreData.val}/${scoreData.max}</div>
      <div class="sbar"><div class="sbar-f" style="width:${pct}%;background:${col}"></div></div>
    </div>`;
  }
  return hasContent?kvHtml:"";
}

function fmtVal(k,v){
  if(v==="true") return `<span style="color:var(--c4)">● EVET</span>`;
  if(v==="false") return `<span style="color:var(--c3)">○ HAYIR</span>`;
  if(v.startsWith("http")&&v.length<200) return `<span style="color:var(--c1)">${esc(v)}</span>`;
  return esc(v);
}

async function checkProfile(url,el){
  el.querySelector(".pcheck").textContent="kontrol ediliyor...";
  try{
    const r=await fetch("/api/scan/url",{method:"POST",
      headers:{"Content-Type":"application/json"},body:JSON.stringify({target:url})});
    const d=await r.json();
    if(d.ok){
      const raw=JSON.stringify(d.data);
      const exists=raw.includes("200")||raw.includes("OK");
      el.querySelector(".pcheck").textContent=exists?"✓ Mevcut":"✗ Bulunamadı";
      el.querySelector(".pcheck").className=`pcheck ${exists?"pok":""}`;
    }
  }catch(e){ el.querySelector(".pcheck").textContent="hata"; }
}

// ═══════════════════════════════════════════
// STATUS + API
// ═══════════════════════════════════════════
function buildStatusBar(tools){
  const names=["nmap","whois","curl","dig","exiftool","traceroute"];
  const h=names.map(n=>`<div class="tool-ind"><div class="ti-d ${tools[n]?"on":"off"}"></div><span style="font-size:8px;color:var(--dim)">${n}</span></div>`).join("");
  document.getElementById("stbar-r").innerHTML=h;
}

function buildKeyChips(keys){
  const all=["shodan","virustotal","abuseipdb","hunter","hibp","urlscan","securitytrails","leakcheck","etherscan"];
  document.getElementById("kchips").innerHTML=all.map(k=>`<span class="kchip ${keys.includes(k)?"set":"unset"}">${k}</span>`).join("");
}

function countHits(data){
  const s=JSON.stringify(data).toLowerCase();
  const matches=(s.match(/breach|malicious|found|pwned|vulnerable|hit|✅|⚠/g)||[]).length;
  hitCount+=matches;
  document.getElementById("st-hi").textContent=hitCount;
}

function openApiM(){document.getElementById("apiM").classList.add("open")}
function closeApiM(e){if(!e||e.target===document.getElementById("apiM"))document.getElementById("apiM").classList.remove("open")}

async function saveKeys(){
  const ks={};
  ["shodan","virustotal","abuseipdb","hunter","hibp","urlscan","securitytrails","leakcheck","etherscan"].forEach(k=>{
    const v=document.getElementById("k-"+k).value.trim();
    if(v) ks[k]=v;
  });
  try{
    const r=await fetch("/api/keys",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(ks)});
    const d=await r.json();
    if(d.ok){
      closeApiM();
      buildKeyChips(Object.keys(ks));
      toast("API keys kaydedildi: "+d.data.saved.join(", "),"ok");
    }
  }catch(e){toast("Hata: "+e.message,"err");}
}

// ═══════════════════════════════════════════
// UTILS
// ═══════════════════════════════════════════
function esc(s){return String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;")}
function sleep(ms){return new Promise(r=>setTimeout(r,ms))}
function rmEmpty(){document.getElementById("empt")&&document.getElementById("empt").remove()}
function clearAll(){
  document.getElementById("RES").innerHTML=`<div class="empty" id="empt">
    <div class="em-eye">👁</div>
    <div class="em-t1">PHANTOM OSINT v4.0</div>
    <div class="em-t2">HEDEF GİRİN · MOD SEÇİN · TARAMAYI BAŞLATIN</div>
    <div class="em-cats" id="em-cats"></div>
  </div>`;
  buildEmptyCats();
  scanCount=0;hitCount=0;
  document.getElementById("st-sc").textContent=0;
  document.getElementById("st-hi").textContent=0;
  document.getElementById("st-ms").textContent="—";
  document.getElementById("st-mo").textContent="—";
}
function addErr(msg){
  rmEmpty();
  document.getElementById("RES").insertAdjacentHTML("afterbegin",
    `<div class="rblock"><div class="rb-body">
      <div class="mc full" style="border-color:var(--c4)">
        <div class="mc-key" style="color:var(--c4)">❌ HATA</div>
        <div class="mc-cnt" style="color:var(--c4)">${esc(msg)}</div>
      </div></div></div>`);
}
let _toastTimer=null;
function toast(msg,type="ok"){
  if(_toastTimer) clearTimeout(_toastTimer);
  let t=document.querySelector(".toast");
  if(!t){t=document.createElement("div");document.body.appendChild(t);}
  t.className=`toast ${type}`;t.textContent=msg;t.style.opacity="1";
  _toastTimer=setTimeout(()=>{t.style.opacity="0";setTimeout(()=>t.remove(),300)},2800);
}
</script>
</body>
</html>
HTMLEOF

# ── Backend başlat ──
python3 "$WD/server.py" "$PORT" "$WD" &
SPID=$!
sleep 1

if kill -0 $SPID 2>/dev/null; then
  echo -e "\033[32m  [✓] Phantom OSINT v4 hazır!\033[0m"
  echo -e "\033[36m  [→] http://localhost:$PORT\033[0m"
  echo ""
else
  echo -e "\033[31m  [✗] Başlatma hatası\033[0m"; exit 1
fi

cleanup(){ kill $SPID 2>/dev/null; rm -rf "$WD"; exit 0; }
trap cleanup INT TERM
wait $SPID
