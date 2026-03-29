#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║         PHANTOM OSINT PANEL v3.0 — FULL INTEGRATED SYSTEM          ║
# ║   Live Tool Execution · API Integration · Termux Native Support     ║
# ╚══════════════════════════════════════════════════════════════════════╝

PORT=$((RANDOM % 40000 + 10000))
TMPDIR_PH=$(mktemp -d)

# ── Banner ──
echo ""
echo -e "\033[36m  ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗████████╗ ██████╗ ███╗   ███╗\033[0m"
echo -e "\033[36m  ██╔══██╗██║  ██║██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗████╗ ████║\033[0m"
echo -e "\033[35m  ██████╔╝███████║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║\033[0m"
echo -e "\033[35m  ██╔═══╝ ██╔══██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║\033[0m"
echo -e "\033[36m  ██║     ██║  ██║██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║\033[0m"
echo -e "\033[36m  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝\033[0m"
echo ""
echo -e "\033[33m  ╔══════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[33m  ║      PHANTOM OSINT INTELLIGENCE PANEL v3.0          ║\033[0m"
echo -e "\033[33m  ║      Live Execution · API Integration · TUI HUD     ║\033[0m"
echo -e "\033[33m  ╚══════════════════════════════════════════════════════╝\033[0m"
echo ""

# ── Bağımlılık kontrolü ──
install_if_missing() {
  if ! python3 -c "import $1" 2>/dev/null; then
    echo -e "\033[33m  [*] $1 yükleniyor...\033[0m"
    pip install $2 --quiet --break-system-packages 2>/dev/null || pip install $2 --quiet 2>/dev/null
  fi
}
install_if_missing "requests" "requests"

for tool in nmap whois curl dig; do
  command -v $tool &>/dev/null || pkg install $tool -y --quiet 2>/dev/null
done

echo -e "\033[32m  [✓] Port: $PORT\033[0m"
echo -e "\033[32m  [✓] URL : http://localhost:$PORT\033[0m"
echo -e "\033[33m  [!] Çıkmak için CTRL+C\033[0m"
echo ""

# ══════════════════════════════════════════════════════════════
# PYTHON BACKEND
# ══════════════════════════════════════════════════════════════
cat > "$TMPDIR_PH/server.py" << 'PYEOF'
import http.server, json, subprocess, urllib.request, urllib.parse, os, sys, ssl, re, socket, threading, time
from urllib.parse import urlparse, parse_qs

PORT = int(sys.argv[1])
WORK_DIR = sys.argv[2]

# ─── API KEYS (kullanıcı panelden girer, buraya kaydedilir) ───
API_KEYS = {}
KEY_FILE = os.path.join(WORK_DIR, "api_keys.json")
if os.path.exists(KEY_FILE):
    try:
        with open(KEY_FILE) as f:
            API_KEYS = json.load(f)
    except: pass

def save_keys():
    with open(KEY_FILE, "w") as f:
        json.dump(API_KEYS, f)

# ─── HELPERS ───
def fetch_url(url, headers=None, timeout=10):
    try:
        req = urllib.request.Request(url, headers=headers or {"User-Agent":"Mozilla/5.0"})
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        with urllib.request.urlopen(req, context=ctx, timeout=timeout) as r:
            return json.loads(r.read().decode())
    except Exception as e:
        return {"error": str(e)}

def run_cmd(cmd, timeout=15):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return (r.stdout + r.stderr).strip()
    except subprocess.TimeoutExpired:
        return "[!] Komut zaman aşımına uğradı"
    except Exception as e:
        return f"[!] Hata: {e}"

def is_ip(s):
    try: socket.inet_aton(s); return True
    except: return False

def is_valid_email(s):
    return bool(re.match(r'^[^@]+@[^@]+\.[^@]+$', s))

# ══════════════════════════════════════════════
# OSINT ENGINE FUNCTIONS
# ══════════════════════════════════════════════

def osint_ip(target):
    results = {}
    # IPinfo
    d = fetch_url(f"https://ipinfo.io/{target}/json")
    if "error" not in d:
        results["ipinfo"] = {
            "ip": d.get("ip",""), "hostname": d.get("hostname",""),
            "city": d.get("city",""), "region": d.get("region",""),
            "country": d.get("country",""), "org": d.get("org",""),
            "timezone": d.get("timezone",""), "loc": d.get("loc","")
        }
    # AbuseIPDB
    if API_KEYS.get("abuseipdb"):
        d2 = fetch_url(f"https://api.abuseipdb.com/api/v2/check?ipAddress={target}&maxAgeInDays=90",
                       headers={"Key": API_KEYS["abuseipdb"], "Accept":"application/json"})
        if "data" in d2:
            results["abuseipdb"] = {
                "abuse_score": d2["data"].get("abuseConfidenceScore",0),
                "total_reports": d2["data"].get("totalReports",0),
                "isp": d2["data"].get("isp",""),
                "usage_type": d2["data"].get("usageType",""),
                "is_tor": d2["data"].get("isTor",False),
                "last_reported": d2["data"].get("lastReportedAt","")
            }
    # GreyNoise Community
    d3 = fetch_url(f"https://api.greynoise.io/v3/community/{target}")
    if "error" not in d3:
        results["greynoise"] = {
            "noise": d3.get("noise", False),
            "riot": d3.get("riot", False),
            "classification": d3.get("classification",""),
            "name": d3.get("name",""),
            "message": d3.get("message","")
        }
    # Shodan (free)
    if API_KEYS.get("shodan"):
        d4 = fetch_url(f"https://api.shodan.io/shodan/host/{target}?key={API_KEYS['shodan']}")
        if "error" not in d4:
            results["shodan"] = {
                "ports": d4.get("ports",[]),
                "vulns": list(d4.get("vulns",{}).keys())[:10],
                "os": d4.get("os",""),
                "org": d4.get("org",""),
                "isp": d4.get("isp",""),
                "hostnames": d4.get("hostnames",[])
            }
    # Termux nmap
    nmap_out = run_cmd(f"nmap -T4 --top-ports 20 --open -Pn {target} 2>/dev/null | head -30")
    if nmap_out and "command not found" not in nmap_out:
        results["nmap"] = {"output": nmap_out}
    # Ping
    ping_out = run_cmd(f"ping -c 3 -W 2 {target} 2>/dev/null | tail -3")
    results["ping"] = {"output": ping_out}
    return results

def osint_domain(target):
    results = {}
    # DNS kayıtları
    for rtype in ["A","MX","TXT","NS","AAAA"]:
        out = run_cmd(f"dig +short {rtype} {target} 2>/dev/null | head -10")
        if out and "command not found" not in out:
            results[f"dns_{rtype}"] = {"records": out.split("\n")}
    # WHOIS
    whois_out = run_cmd(f"whois {target} 2>/dev/null | head -40")
    if whois_out and "command not found" not in whois_out:
        results["whois"] = {"output": whois_out}
    # SecurityTrails (free)
    d = fetch_url(f"https://api.securitytrails.com/v1/domain/{target}",
                  headers={"apikey": API_KEYS.get("securitytrails",""), "Accept":"application/json"}) if API_KEYS.get("securitytrails") else {}
    if "current_dns" in d:
        results["securitytrails"] = {"current_dns": d["current_dns"]}
    # crt.sh subdomains
    crt = fetch_url(f"https://crt.sh/?q=%.{target}&output=json")
    if isinstance(crt, list):
        subs = list(set([x.get("name_value","") for x in crt if "name_value" in x]))[:20]
        results["crtsh"] = {"subdomains": subs, "count": len(crt)}
    # URLScan
    us = fetch_url(f"https://urlscan.io/api/v1/search/?q=domain:{target}&size=5")
    if "results" in us:
        results["urlscan"] = {"results": [{"url":r.get("page",{}).get("url",""), "ip":r.get("page",{}).get("ip",""), "date":r.get("task",{}).get("time","")} for r in us["results"]]}
    # VirusTotal domain
    if API_KEYS.get("virustotal"):
        vt = fetch_url(f"https://www.virustotal.com/api/v3/domains/{target}",
                       headers={"x-apikey": API_KEYS["virustotal"]})
        if "data" in vt:
            attr = vt["data"].get("attributes",{})
            stats = attr.get("last_analysis_stats",{})
            results["virustotal"] = {
                "malicious": stats.get("malicious",0),
                "suspicious": stats.get("suspicious",0),
                "reputation": attr.get("reputation",0),
                "categories": list(attr.get("categories",{}).values())[:5]
            }
    return results

def osint_email(target):
    results = {}
    # Hunter.io
    if API_KEYS.get("hunter"):
        d = fetch_url(f"https://api.hunter.io/v2/email-verifier?email={target}&api_key={API_KEYS['hunter']}")
        if "data" in d:
            results["hunter"] = d["data"]
    # EmailRep
    d2 = fetch_url(f"https://emailrep.io/{target}", headers={"User-Agent":"phantom-osint"})
    if "error" not in d2:
        results["emailrep"] = {
            "reputation": d2.get("reputation",""),
            "suspicious": d2.get("suspicious",False),
            "references": d2.get("references",0),
            "details": d2.get("details",{})
        }
    # HaveIBeenPwned
    if API_KEYS.get("hibp"):
        d3 = fetch_url(f"https://haveibeenpwned.com/api/v3/breachedaccount/{urllib.parse.quote(target)}?truncateResponse=false",
                       headers={"hibp-api-key": API_KEYS["hibp"], "User-Agent":"phantom-osint"})
        if isinstance(d3, list):
            results["haveibeenpwned"] = {"breach_count": len(d3), "breaches": [{"name":b["Name"],"date":b.get("BreachDate",""),"pw_exposed":b.get("IsVerified",False)} for b in d3[:10]]}
        elif isinstance(d3, dict) and "error" in d3:
            if "404" in str(d3["error"]):
                results["haveibeenpwned"] = {"breach_count": 0, "breaches": [], "note": "Temiz — hiç ihlal bulunamadı"}
    # Domain extraction + check
    domain = target.split("@")[1] if "@" in target else ""
    if domain:
        mx = run_cmd(f"dig +short MX {domain} 2>/dev/null | head -5")
        results["mx_check"] = {"domain": domain, "mx_records": mx.split("\n") if mx else []}
    # Holehe style (manual check common sites)
    results["quick_check"] = {"target": target, "note": "Aşağıdaki sitelerde manuel doğrulama için linklere tıklayın"}
    return results

def osint_phone(target):
    results = {}
    # NumLookupAPI (ücretsiz)
    clean = re.sub(r'[^0-9+]', '', target)
    d = fetch_url(f"https://api.numlookupapi.com/v1/validate/{clean}?apikey=num_live_demo_key")
    if "error" not in d and d:
        results["numlookup"] = {
            "valid": d.get("valid", False),
            "country": d.get("country_name",""),
            "country_code": d.get("country_code",""),
            "location": d.get("location",""),
            "carrier": d.get("carrier",""),
            "line_type": d.get("line_type","")
        }
    # Abstract API (ücretsiz tier)
    d2 = fetch_url(f"https://phonevalidation.abstractapi.com/v1/?api_key=demo&phone={clean}")
    if "error" not in d2 and d2:
        results["abstract"] = {
            "valid": d2.get("valid", False),
            "format": d2.get("format",{}),
            "country": d2.get("country",{}),
            "carrier": d2.get("carrier",""),
            "type": d2.get("type","")
        }
    # Truecaller search link
    results["links"] = {
        "truecaller": f"https://truecaller.com/search/tr/{clean}",
        "sync_me": f"https://sync.me/search/?number={clean}",
        "spydialer": f"https://spydialer.com/default.aspx?phone={clean}"
    }
    return results

def osint_username(target):
    results = {}
    # WhatsMyName API (GitHub raw)
    wmndata = fetch_url("https://raw.githubusercontent.com/WebBreacher/WhatsMyName/main/wmn-data.json")
    found = []
    if "sites" in wmndata:
        # Hızlı kontrol - ilk 30 site
        import concurrent.futures
        def check_site(site):
            try:
                url = site.get("uri_check","").replace("{account}", target)
                req = urllib.request.Request(url, headers={"User-Agent":"Mozilla/5.0"})
                ctx = ssl.create_default_context(); ctx.check_hostname=False; ctx.verify_mode=ssl.CERT_NONE
                with urllib.request.urlopen(req, context=ctx, timeout=5) as r:
                    if r.status == 200:
                        return {"name": site["name"], "url": url, "category": site.get("category","")}
            except: pass
            return None
        sites = wmndata["sites"][:50]
        with concurrent.futures.ThreadPoolExecutor(max_workers=15) as ex:
            futures = [ex.submit(check_site, s) for s in sites]
            for f in concurrent.futures.as_completed(futures):
                res = f.result()
                if res: found.append(res)
        results["whatsmyname"] = {"found": found, "checked": len(sites), "hits": len(found)}
    # Sherlock CLI
    sherlock_out = run_cmd(f"python3 -m sherlock {target} --timeout 10 2>/dev/null | head -30") if run_cmd("python3 -m sherlock --help 2>/dev/null | head -1") else ""
    if sherlock_out and "error" not in sherlock_out.lower():
        results["sherlock"] = {"output": sherlock_out}
    return results

def osint_image(filepath):
    results = {}
    # EXIF via exiftool or python
    exif_out = run_cmd(f"exiftool '{filepath}' 2>/dev/null | head -40")
    if exif_out and "command not found" not in exif_out:
        lines = {}
        for line in exif_out.split("\n"):
            if ":" in line:
                k,v = line.split(":",1)
                lines[k.strip()] = v.strip()
        results["exif"] = lines
    else:
        # Python PIL fallback
        py_exif = run_cmd(f"""python3 -c "
from PIL import Image
from PIL.ExifTags import TAGS
img=Image.open('{filepath}')
exif=img._getexif()
if exif:
    for k,v in list(exif.items())[:20]:
        tag=TAGS.get(k,k)
        print(f'{{tag}}: {{v}}')
else:
    print('EXIF verisi bulunamadı')
" 2>/dev/null""")
        results["exif"] = {"output": py_exif or "EXIF okunamadı"}
    # GPS
    gps_match = run_cmd(f"exiftool -GPSLatitude -GPSLongitude -n '{filepath}' 2>/dev/null")
    if gps_match and ":" in gps_match:
        results["gps"] = {"output": gps_match}
    return results

def osint_url_scan(target):
    results = {}
    # VirusTotal URL
    if API_KEYS.get("virustotal"):
        import base64
        url_id = base64.urlsafe_b64encode(target.encode()).decode().strip("=")
        vt = fetch_url(f"https://www.virustotal.com/api/v3/urls/{url_id}",
                       headers={"x-apikey": API_KEYS["virustotal"]})
        if "data" in vt:
            attr = vt["data"].get("attributes",{})
            stats = attr.get("last_analysis_stats",{})
            results["virustotal"] = {"malicious": stats.get("malicious",0), "suspicious": stats.get("suspicious",0), "harmless": stats.get("harmless",0)}
    # URLScan submit
    if API_KEYS.get("urlscan"):
        try:
            data = json.dumps({"url": target, "visibility":"public"}).encode()
            req = urllib.request.Request("https://urlscan.io/api/v1/scan/",
                data=data, headers={"API-Key":API_KEYS["urlscan"],"Content-Type":"application/json"})
            ctx = ssl.create_default_context(); ctx.check_hostname=False; ctx.verify_mode=ssl.CERT_NONE
            with urllib.request.urlopen(req, context=ctx, timeout=10) as r:
                resp = json.loads(r.read().decode())
                results["urlscan"] = {"uuid": resp.get("uuid",""), "result": resp.get("result",""), "api": resp.get("api","")}
        except Exception as e:
            results["urlscan"] = {"error": str(e)}
    # Wayback check
    wb = fetch_url(f"https://archive.org/wayback/available?url={target}")
    if "archived_snapshots" in wb and wb["archived_snapshots"].get("closest"):
        snap = wb["archived_snapshots"]["closest"]
        results["wayback"] = {"available": snap.get("available"), "url": snap.get("url",""), "timestamp": snap.get("timestamp","")}
    # HTTPx headers
    headers_out = run_cmd(f"curl -sI --max-time 8 '{target}' 2>/dev/null | head -20")
    if headers_out:
        results["headers"] = {"output": headers_out}
    return results

def osint_breach(target):
    results = {}
    # Breach Directory
    bd = fetch_url(f"https://breachdirectory.org/api?func=auto&term={urllib.parse.quote(target)}")
    if "result" in bd:
        results["breachdirectory"] = {"found": bd.get("found",0), "results": bd["result"][:10] if bd["result"] else []}
    # LeakCheck
    if API_KEYS.get("leakcheck"):
        lc = fetch_url(f"https://leakcheck.io/api/public?key={API_KEYS['leakcheck']}&check={urllib.parse.quote(target)}")
        if "result" in lc:
            results["leakcheck"] = lc
    # HaveIBeenPwned
    if API_KEYS.get("hibp"):
        d = fetch_url(f"https://haveibeenpwned.com/api/v3/breachedaccount/{urllib.parse.quote(target)}?truncateResponse=false",
                      headers={"hibp-api-key": API_KEYS["hibp"], "User-Agent":"phantom-osint"})
        if isinstance(d, list):
            results["hibp"] = {"count": len(d), "breaches": [b["Name"] for b in d]}
    return results

def network_scan(target):
    results = {}
    # Nmap
    nmap = run_cmd(f"nmap -T4 -sV --top-ports 100 -Pn {target} 2>/dev/null | head -50")
    results["nmap"] = {"output": nmap}
    # Traceroute
    tr = run_cmd(f"traceroute -m 10 -w 2 {target} 2>/dev/null || tracepath -m 10 {target} 2>/dev/null | head -15")
    results["traceroute"] = {"output": tr}
    return results

# ══════════════════════════════════════════════
# HTTP SERVER
# ══════════════════════════════════════════════
class PhantomHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin","*")
        self.send_header("Access-Control-Allow-Methods","GET,POST,OPTIONS")
        self.send_header("Access-Control-Allow-Headers","Content-Type")
        self.end_headers()

    def do_POST(self):
        length = int(self.headers.get("Content-Length",0))
        body = json.loads(self.rfile.read(length).decode()) if length else {}
        path = self.path

        result = {"ok": False, "data": {}, "error": ""}
        try:
            if path == "/api/keys":
                API_KEYS.update(body)
                save_keys()
                result = {"ok": True, "data": {"saved": list(body.keys())}}
            elif path == "/api/scan/ip":
                result = {"ok": True, "data": osint_ip(body["target"])}
            elif path == "/api/scan/domain":
                result = {"ok": True, "data": osint_domain(body["target"])}
            elif path == "/api/scan/email":
                result = {"ok": True, "data": osint_email(body["target"])}
            elif path == "/api/scan/phone":
                result = {"ok": True, "data": osint_phone(body["target"])}
            elif path == "/api/scan/username":
                result = {"ok": True, "data": osint_username(body["target"])}
            elif path == "/api/scan/url":
                result = {"ok": True, "data": osint_url_scan(body["target"])}
            elif path == "/api/scan/breach":
                result = {"ok": True, "data": osint_breach(body["target"])}
            elif path == "/api/scan/network":
                result = {"ok": True, "data": network_scan(body["target"])}
            elif path == "/api/upload/image":
                # Base64 image
                import base64
                img_data = base64.b64decode(body["data"])
                fname = os.path.join(WORK_DIR, "upload_img")
                with open(fname,"wb") as f: f.write(img_data)
                result = {"ok": True, "data": osint_image(fname)}
            elif path == "/api/cmd":
                cmd = body.get("cmd","")
                out = run_cmd(cmd, timeout=20)
                result = {"ok": True, "data": {"output": out}}
            elif path == "/api/keys/get":
                result = {"ok": True, "data": {k: "***"+v[-4:] if v else "" for k,v in API_KEYS.items()}}
        except Exception as e:
            result = {"ok": False, "error": str(e)}

        resp = json.dumps(result).encode()
        self.send_response(200)
        self.send_header("Content-Type","application/json")
        self.send_header("Content-Length", len(resp))
        self.send_header("Access-Control-Allow-Origin","*")
        self.end_headers()
        self.wfile.write(resp)

    def do_GET(self):
        if self.path == "/" or self.path == "/index.html":
            html_path = os.path.join(WORK_DIR, "index.html")
            with open(html_path,"rb") as f: content = f.read()
            self.send_response(200)
            self.send_header("Content-Type","text/html; charset=utf-8")
            self.send_header("Content-Length", len(content))
            self.end_headers()
            self.wfile.write(content)
        elif self.path == "/api/status":
            r = json.dumps({"ok":True,"port":PORT,"tools":{"nmap":bool(run_cmd("which nmap 2>/dev/null")),"whois":bool(run_cmd("which whois 2>/dev/null")),"curl":bool(run_cmd("which curl 2>/dev/null")),"dig":bool(run_cmd("which dig 2>/dev/null"))}}).encode()
            self.send_response(200)
            self.send_header("Content-Type","application/json")
            self.send_header("Access-Control-Allow-Origin","*")
            self.end_headers()
            self.wfile.write(r)
        else:
            self.send_response(404); self.end_headers()

server = http.server.HTTPServer(("127.0.0.1", PORT), PhantomHandler)
server.serve_forever()
PYEOF

# ══════════════════════════════════════════════
# HTML FRONTEND
# ══════════════════════════════════════════════
cat > "$TMPDIR_PH/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
<title>PHANTOM OSINT v3</title>
<link href="https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;700;900&family=Rajdhani:wght@300;500;700&display=swap" rel="stylesheet">
<style>
:root {
  --c: #00fff7; --m: #ff00aa; --g: #00ff88; --r: #ff3355;
  --gold: #ffd700; --bg: #030d12; --p: rgba(0,255,247,0.04);
  --b: rgba(0,255,247,0.12); --t: #8ecfda; --dim: rgba(0,255,247,0.45);
}
*{margin:0;padding:0;box-sizing:border-box}
html,body{height:100%;background:var(--bg);font-family:'Share Tech Mono',monospace;color:var(--t);overflow:hidden}
body::before{content:'';position:fixed;inset:0;pointer-events:none;z-index:9999;
  background:repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(0,0,0,0.06) 2px,rgba(0,0,0,0.06) 4px);
  animation:scan 12s linear infinite}
@keyframes scan{0%{background-position:0 0}100%{background-position:0 200px}}
body::after{content:'';position:fixed;inset:0;pointer-events:none;z-index:0;
  background-image:linear-gradient(rgba(0,255,247,0.02) 1px,transparent 1px),linear-gradient(90deg,rgba(0,255,247,0.02) 1px,transparent 1px);
  background-size:50px 50px}

/* ── SCROLLBAR ── */
::-webkit-scrollbar{width:3px;height:3px}
::-webkit-scrollbar-thumb{background:var(--b)}

/* ══ LOGIN ══ */
#LS{position:fixed;inset:0;z-index:1000;display:flex;align-items:center;justify-content:center;
  background:radial-gradient(ellipse at 50% 40%,rgba(0,30,45,.97) 0%,#030d12 70%);transition:opacity .7s,visibility .7s}
#LS.gone{opacity:0;visibility:hidden;pointer-events:none}
.lbox{width:min(440px,94vw);border:1px solid var(--c);background:rgba(2,8,14,.97);padding:44px 38px;
  position:relative;box-shadow:0 0 80px rgba(0,255,247,.1),inset 0 0 40px rgba(0,255,247,.02)}
.lbox::before,.lbox::after{content:'';position:absolute;width:18px;height:18px;border-color:var(--m);border-style:solid}
.lbox::before{top:-1px;left:-1px;border-width:2px 0 0 2px}
.lbox::after{bottom:-1px;right:-1px;border-width:0 2px 2px 0}
.llogo{text-align:center;margin-bottom:34px}
.leye{font-size:44px;display:block;animation:ep 3s ease-in-out infinite;margin-bottom:10px}
@keyframes ep{0%,100%{filter:drop-shadow(0 0 8px var(--c))}50%{filter:drop-shadow(0 0 28px var(--c)) drop-shadow(0 0 50px var(--m))}}
.ltitle{font-family:'Orbitron',sans-serif;font-size:26px;font-weight:900;color:var(--c);letter-spacing:7px;
  text-shadow:0 0 20px var(--c);display:block;margin-bottom:5px}
.lsub{font-size:10px;letter-spacing:4px;color:var(--m);text-shadow:0 0 10px var(--m)}
.llbl{font-size:10px;letter-spacing:3px;color:var(--dim);margin-bottom:7px;display:block;margin-top:18px}
.linp{width:100%;padding:11px 15px;background:rgba(0,255,247,.04);border:1px solid var(--b);
  color:var(--c);font-family:'Share Tech Mono',monospace;font-size:13px;outline:none;transition:all .3s;letter-spacing:2px}
.linp:focus{border-color:var(--c);box-shadow:0 0 18px rgba(0,255,247,.12)}
.linp::placeholder{color:rgba(0,255,247,.2)}
.lbtn{width:100%;padding:13px;margin-top:22px;background:transparent;border:1px solid var(--c);
  color:var(--c);font-family:'Orbitron',sans-serif;font-size:12px;letter-spacing:4px;cursor:pointer;
  position:relative;overflow:hidden;transition:all .3s}
.lbtn::before{content:'';position:absolute;top:0;left:-100%;width:100%;height:100%;
  background:linear-gradient(90deg,transparent,rgba(0,255,247,.12),transparent);transition:left .4s}
.lbtn:hover::before{left:100%}
.lbtn:hover{background:rgba(0,255,247,.07);box-shadow:0 0 28px rgba(0,255,247,.18)}
.lstat{height:18px;margin-top:14px;text-align:center;font-size:10px;letter-spacing:2px}
.lstat.e{color:var(--r)}.lstat.ok{color:var(--g)}
.lhint{margin-top:24px;border-top:1px solid var(--b);padding-top:18px;font-size:10px;color:rgba(0,255,247,.25);letter-spacing:1px;line-height:1.8}
.lhint span{color:var(--gold)}

/* ══ MAIN ══ */
#MP{display:none;flex-direction:column;height:100vh;position:relative;z-index:1}

/* ── TOPBAR ── */
.tb{display:flex;align-items:center;padding:8px 18px;border-bottom:1px solid var(--b);
  background:rgba(3,8,18,.92);backdrop-filter:blur(10px);flex-shrink:0;gap:16px}
.tb-logo{font-family:'Orbitron',sans-serif;font-size:15px;font-weight:900;color:var(--c);
  letter-spacing:4px;text-shadow:0 0 12px var(--c);white-space:nowrap}
.tb-logo em{color:var(--m);font-style:normal}
.tb-spacer{flex:1}
.tb-clock{font-size:11px;color:var(--gold);letter-spacing:2px;white-space:nowrap}
.tb-dot{width:7px;height:7px;border-radius:50%;background:var(--g);box-shadow:0 0 6px var(--g);animation:bk 2s infinite}
@keyframes bk{0%,100%{opacity:1}50%{opacity:.2}}
.tb-user{font-size:10px;color:var(--m);letter-spacing:2px}
.tb-btn{padding:5px 12px;border:1px solid var(--b);background:transparent;color:var(--dim);
  font-family:'Share Tech Mono',monospace;font-size:10px;cursor:pointer;letter-spacing:1px;transition:all .2s}
.tb-btn:hover{border-color:var(--c);color:var(--c)}

/* ── LAYOUT ── */
.layout{display:flex;flex:1;overflow:hidden}

/* ── SIDEBAR ── */
.sb{width:200px;flex-shrink:0;border-right:1px solid var(--b);background:rgba(2,6,12,.85);
  overflow-y:auto;padding:10px 0;display:flex;flex-direction:column}
.sb-group{font-size:9px;letter-spacing:3px;color:var(--m);padding:10px 14px 5px;opacity:.6;
  display:flex;align-items:center;gap:6px}
.sb-group::after{content:'';flex:1;height:1px;background:var(--b)}
.sb-item{display:flex;align-items:center;gap:9px;padding:8px 14px 8px 18px;cursor:pointer;
  font-size:11px;letter-spacing:.5px;color:var(--t);transition:all .2s;position:relative;border-left:2px solid transparent}
.sb-item:hover{background:rgba(0,255,247,.05);color:var(--c)}
.sb-item.act{background:rgba(0,255,247,.08);color:var(--c);border-left-color:var(--c)}
.sb-icon{font-size:13px;flex-shrink:0;width:18px;text-align:center}
.sb-label{flex:1}
.sb-c{font-size:9px;background:rgba(0,255,247,.08);color:var(--dim);padding:1px 6px;border-radius:1px}

/* ── CONTENT ── */
.cnt{flex:1;overflow:hidden;display:flex;flex-direction:column}

/* ── TOOL PANEL ── */
.toolpanel{padding:16px 20px;border-bottom:1px solid var(--b);background:rgba(2,6,12,.7);flex-shrink:0}
.tool-title{font-family:'Orbitron',sans-serif;font-size:12px;letter-spacing:3px;color:var(--c);
  margin-bottom:12px;display:flex;align-items:center;gap:10px}
.tool-title::after{content:'';flex:1;height:1px;background:linear-gradient(90deg,var(--b),transparent)}
.tool-row{display:flex;gap:8px;flex-wrap:wrap;align-items:center}
.tool-inp{flex:1;min-width:200px;padding:9px 14px;background:rgba(0,255,247,.04);border:1px solid var(--b);
  color:var(--c);font-family:'Share Tech Mono',monospace;font-size:13px;outline:none;transition:all .3s;letter-spacing:1px}
.tool-inp:focus{border-color:var(--c);box-shadow:0 0 14px rgba(0,255,247,.1)}
.tool-inp::placeholder{color:rgba(0,255,247,.22)}
.tool-sel{padding:9px 12px;background:rgba(0,255,247,.04);border:1px solid var(--b);color:var(--t);
  font-family:'Share Tech Mono',monospace;font-size:11px;outline:none;cursor:pointer}
.tool-sel option{background:#030d12}
.run-btn{padding:9px 22px;background:rgba(0,255,247,.08);border:1px solid var(--c);color:var(--c);
  font-family:'Orbitron',sans-serif;font-size:11px;letter-spacing:3px;cursor:pointer;white-space:nowrap;
  transition:all .2s;position:relative;overflow:hidden}
.run-btn::before{content:'';position:absolute;inset:0;background:rgba(0,255,247,.08);transform:scaleX(0);transform-origin:left;transition:transform .3s}
.run-btn.loading::before{transform:scaleX(1);animation:prog 2s ease infinite}
@keyframes prog{0%{transform:scaleX(0);transform-origin:left}50%{transform:scaleX(1);transform-origin:left}51%{transform-origin:right}100%{transform:scaleX(0);transform-origin:right}}
.run-btn:hover{box-shadow:0 0 20px rgba(0,255,247,.18)}
.clr-btn{padding:9px 14px;background:transparent;border:1px solid var(--b);color:var(--dim);
  font-family:'Share Tech Mono',monospace;font-size:11px;cursor:pointer;transition:all .2s}
.clr-btn:hover{border-color:var(--r);color:var(--r)}
.img-btn{padding:9px 14px;background:transparent;border:1px solid var(--b);color:var(--dim);
  font-family:'Share Tech Mono',monospace;font-size:11px;cursor:pointer;transition:all .2s;white-space:nowrap}
.img-btn:hover{border-color:var(--gold);color:var(--gold)}
#file-inp{display:none}

/* ── RESULTS AREA ── */
.results{flex:1;overflow-y:auto;padding:16px 20px}

/* ── RESULT CARDS ── */
.rc{border:1px solid var(--b);background:var(--p);margin-bottom:12px;animation:ri .35s ease both}
@keyframes ri{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}
.rc-head{display:flex;align-items:center;gap:10px;padding:10px 14px;border-bottom:1px solid var(--b);
  cursor:pointer;user-select:none}
.rc-icon{font-size:15px}
.rc-title{font-family:'Rajdhani',sans-serif;font-size:14px;font-weight:700;color:#dff5fa;letter-spacing:1px;flex:1}
.rc-badge{font-size:9px;padding:2px 8px;border-radius:1px;font-family:'Orbitron',sans-serif;letter-spacing:2px}
.rc-badge.ok{border:1px solid var(--g);color:var(--g)}
.rc-badge.warn{border:1px solid var(--gold);color:var(--gold)}
.rc-badge.bad{border:1px solid var(--r);color:var(--r)}
.rc-badge.info{border:1px solid var(--b);color:var(--dim)}
.rc-body{padding:14px;display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:10px}
.rc-body.collapsed{display:none}
.rf{background:rgba(0,0,0,.25);padding:10px 12px;border:1px solid rgba(0,255,247,.06)}
.rf-key{font-size:9px;letter-spacing:3px;color:var(--m);margin-bottom:5px;text-transform:uppercase}
.rf-val{font-size:12px;color:#cef5fa;word-break:break-all;line-height:1.6}
.rf-val.pre{white-space:pre-wrap;font-size:11px;color:rgba(200,245,250,.7);max-height:200px;overflow-y:auto}
.rf-val a{color:var(--c);text-decoration:none}
.rf-val a:hover{text-decoration:underline}
.rf-list{list-style:none}
.rf-list li{padding:3px 0;border-bottom:1px solid rgba(0,255,247,.05);font-size:11px;display:flex;gap:6px;align-items:flex-start}
.rf-list li::before{content:'◈';color:var(--m);flex-shrink:0;font-size:9px;margin-top:2px}
.score-bar{height:6px;background:rgba(0,255,247,.1);margin-top:6px;position:relative}
.score-fill{height:100%;transition:width .8s ease}

/* ── EMPTY STATE ── */
.empty{display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;
  color:var(--dim);font-size:12px;letter-spacing:3px;gap:14px;opacity:.6}
.empty .big{font-size:48px;opacity:.4}

/* ── TERMINAL ── */
.terminal{font-family:'Share Tech Mono',monospace;font-size:11px;color:var(--g);
  background:rgba(0,0,0,.5);padding:12px;border:1px solid rgba(0,255,247,.08);
  white-space:pre-wrap;max-height:220px;overflow-y:auto;line-height:1.6}

/* ── STATUSBAR ── */
.sbar{padding:6px 18px;border-top:1px solid var(--b);background:rgba(2,4,10,.95);
  display:flex;gap:20px;align-items:center;flex-shrink:0;font-size:10px;letter-spacing:1px}
.sv{color:var(--c);font-weight:700}.sl{color:rgba(0,255,247,.35)}
.sbar-right{margin-left:auto;display:flex;gap:14px}
.tool-indicator{display:flex;align-items:center;gap:5px}
.ti-dot{width:6px;height:6px;border-radius:50%}
.ti-dot.on{background:var(--g);box-shadow:0 0 5px var(--g)}
.ti-dot.off{background:var(--r);opacity:.5}

/* ── API MODAL ── */
.modal-ov{position:fixed;inset:0;z-index:500;background:rgba(0,0,0,.88);
  display:flex;align-items:center;justify-content:center;opacity:0;visibility:hidden;transition:all .3s}
.modal-ov.open{opacity:1;visibility:visible}
.modal{width:min(540px,96vw);border:1px solid var(--c);background:rgba(2,8,14,.98);padding:28px;
  position:relative;box-shadow:0 0 60px rgba(0,255,247,.12)}
.modal h3{font-family:'Orbitron',sans-serif;font-size:14px;color:var(--c);letter-spacing:3px;margin-bottom:20px}
.api-row{display:flex;align-items:center;gap:8px;margin-bottom:10px}
.api-lbl{font-size:10px;letter-spacing:2px;color:var(--dim);width:130px;flex-shrink:0}
.api-inp{flex:1;padding:8px 12px;background:rgba(0,255,247,.04);border:1px solid var(--b);
  color:var(--c);font-family:'Share Tech Mono',monospace;font-size:12px;outline:none}
.api-inp:focus{border-color:var(--c)}
.mclose{position:absolute;top:14px;right:14px;background:none;border:none;color:var(--dim);font-size:18px;cursor:pointer}
.mclose:hover{color:var(--r)}
.m-save{padding:10px 24px;background:rgba(0,255,247,.08);border:1px solid var(--c);color:var(--c);
  font-family:'Orbitron',sans-serif;font-size:10px;letter-spacing:3px;cursor:pointer;margin-top:16px;transition:all .2s}
.m-save:hover{background:rgba(0,255,247,.15)}
.api-note{font-size:10px;color:var(--dim);margin-top:12px;line-height:1.8;border-top:1px solid var(--b);padding-top:12px}

/* ── LINK CHIPS ── */
.link-chips{display:flex;flex-wrap:wrap;gap:6px}
.chip{font-size:10px;padding:4px 10px;border:1px solid var(--b);color:var(--c);text-decoration:none;
  letter-spacing:1px;transition:all .2s}
.chip:hover{border-color:var(--c);background:rgba(0,255,247,.08)}

/* ── FOUND / NOT FOUND ── */
.found-item{display:flex;justify-content:space-between;align-items:center;padding:5px 0;
  border-bottom:1px solid rgba(0,255,247,.05)}
.found-item a{color:var(--g);font-size:11px;text-decoration:none}
.found-item a:hover{text-decoration:underline}
.found-item .cat{font-size:9px;color:var(--dim);letter-spacing:1px}

/* ── RESPONSIVE ── */
@media(max-width:580px){.sb{display:none}.tb-clock{display:none}}
</style>
</head>
<body>

<!-- ══ LOGIN ══ -->
<div id="LS">
<div class="lbox">
  <div class="llogo">
    <span class="leye">👁</span>
    <span class="ltitle">PHANTOM</span>
    <span class="lsub">OSINT INTELLIGENCE PANEL v3.0 — LIVE EXECUTION</span>
  </div>
  <span class="llbl">OPERATOR ID</span>
  <input class="linp" id="lu" type="text" placeholder="operator_id" autocomplete="off" spellcheck="false">
  <span class="llbl">CIPHER KEY</span>
  <input class="linp" id="lp" type="password" placeholder="••••••••" autocomplete="off">
  <button class="lbtn" onclick="doLogin()">▶ AUTHENTICATE &amp; CONNECT</button>
  <div class="lstat" id="lst"></div>
  <div class="lhint">
    ADMIN&nbsp;&nbsp;: <span>phantom</span> / <span>osint2024</span><br>
    GUEST&nbsp;&nbsp;: <span>guest</span> / <span>guest</span><br>
    <span style="color:var(--c)">Gerçek araçları çalıştırmak için API Keys girin (⚙)</span>
  </div>
</div>
</div>

<!-- ══ MAIN ══ -->
<div id="MP">
  <div class="tb">
    <div class="tb-logo">PH<em>ANT</em>OM <em style="font-size:10px;letter-spacing:2px;color:var(--gold)">OSINT</em></div>
    <div class="tb-spacer"></div>
    <div class="tb-dot"></div>
    <span style="font-size:10px;color:var(--g);letter-spacing:2px">ONLINE</span>
    <div class="tb-clock" id="clk">--:--:--</div>
    <div class="tb-user" id="tbu">◈ OPERATOR</div>
    <button class="tb-btn" onclick="openApiModal()">⚙ API KEYS</button>
    <button class="tb-btn" onclick="clearResults()">⌫ TEMİZLE</button>
  </div>

  <div class="layout">
    <!-- SIDEBAR -->
    <div class="sb" id="SB"></div>

    <!-- CONTENT -->
    <div class="cnt">
      <!-- TOOL PANEL -->
      <div class="toolpanel">
        <div class="tool-title" id="tool-title">◈ IP / AĞ ANALIZI</div>
        <div class="tool-row">
          <input class="tool-inp" id="tinp" placeholder="Hedef girin..." autocomplete="off" spellcheck="false">
          <select class="tool-sel" id="tmode">
            <option value="ip">IP Analizi</option>
            <option value="domain">Domain / DNS</option>
            <option value="email">E-Posta</option>
            <option value="phone">Telefon</option>
            <option value="username">Kullanıcı Adı</option>
            <option value="url">URL / Site</option>
            <option value="breach">İhlal Araması</option>
            <option value="network">Ağ Tarama</option>
          </select>
          <button class="run-btn" id="rbtn" onclick="runScan()">⚡ TARA</button>
          <button class="img-btn" onclick="document.getElementById('file-inp').click()">📸 EXIF</button>
          <button class="clr-btn" onclick="clearResults()">✕</button>
          <input type="file" id="file-inp" accept="image/*" onchange="handleImage(this)">
        </div>
      </div>

      <!-- RESULTS -->
      <div class="results" id="RES">
        <div class="empty" id="empty-state">
          <div class="big">👁</div>
          <div>HEDEF GİRİN VE TARAMAYI BAŞLATIN</div>
          <div style="font-size:10px;color:rgba(0,255,247,.25)">Tüm araçlar Termux üzerinde native çalışır</div>
        </div>
      </div>

      <!-- STATUS BAR -->
      <div class="sbar">
        <div><span class="sv" id="s-scans">0</span> <span class="sl">TARAMA</span></div>
        <div><span class="sv" id="s-hits">0</span> <span class="sl">HIT</span></div>
        <div><span class="sv" id="s-time">0ms</span> <span class="sl">SÜRE</span></div>
        <div class="sbar-right" id="tool-status"></div>
      </div>
    </div>
  </div>
</div>

<!-- API MODAL -->
<div class="modal-ov" id="apiMod" onclick="closeApiModal(event)">
<div class="modal">
  <button class="mclose" onclick="closeApiModal()">✕</button>
  <h3>⚙ API KEY YÖNETİMİ</h3>
  <div class="api-row"><span class="api-lbl">SHODAN</span><input class="api-inp" id="k-shodan" placeholder="Shodan API Key..."></div>
  <div class="api-row"><span class="api-lbl">VIRUSTOTAL</span><input class="api-inp" id="k-virustotal" placeholder="VirusTotal API Key..."></div>
  <div class="api-row"><span class="api-lbl">ABUSEIPDB</span><input class="api-inp" id="k-abuseipdb" placeholder="AbuseIPDB API Key..."></div>
  <div class="api-row"><span class="api-lbl">HUNTER.IO</span><input class="api-inp" id="k-hunter" placeholder="Hunter.io API Key..."></div>
  <div class="api-row"><span class="api-lbl">HIBP</span><input class="api-inp" id="k-hibp" placeholder="HaveIBeenPwned API Key..."></div>
  <div class="api-row"><span class="api-lbl">URLSCAN</span><input class="api-inp" id="k-urlscan" placeholder="URLScan.io API Key..."></div>
  <div class="api-row"><span class="api-lbl">SECURITYTRAILS</span><input class="api-inp" id="k-securitytrails" placeholder="SecurityTrails API Key..."></div>
  <div class="api-row"><span class="api-lbl">LEAKCHECK</span><input class="api-inp" id="k-leakcheck" placeholder="LeakCheck API Key..."></div>
  <button class="m-save" onclick="saveApiKeys()">💾 KAYDET</button>
  <div class="api-note">
    API key'ler Termux içinde yerel olarak saklanır — internete gönderilmez.<br>
    Ücretsiz key almak için: shodan.io · virustotal.com · abuseipdb.com · hunter.io
  </div>
</div>
</div>

<script>
// ══════════════════════════════════════
// STATE
// ══════════════════════════════════════
const CREDS = {phantom:"osint2024",admin:"phantom123",guest:"guest"};
let scanCount=0, hitCount=0, currentUser="OPERATOR";

// ══ LOGIN ══
function doLogin(){
  const u=document.getElementById("lu").value.trim();
  const p=document.getElementById("lp").value;
  const s=document.getElementById("lst");
  s.className="lstat"; s.textContent="[ CONNECTING TO BACKEND... ]";
  setTimeout(async()=>{
    if(CREDS[u]&&CREDS[u]===p){
      // Backend bağlantı kontrolü
      try{
        const r=await fetch("/api/status");
        const d=await r.json();
        if(d.ok){
          s.className="lstat ok"; s.textContent="[ ACCESS GRANTED — BACKEND ONLINE ]";
          currentUser=u.toUpperCase();
          setTimeout(()=>{
            document.getElementById("LS").classList.add("gone");
            document.getElementById("MP").style.display="flex";
            initPanel(d.tools);
          },600);
        }
      }catch(e){
        s.className="lstat e"; s.textContent="[ BACKEND ERRORː "+e.message+" ]";
      }
    } else {
      s.className="lstat e"; s.textContent="[ ACCESS DENIED ]";
      document.getElementById("lp").value="";
    }
  },700);
}
document.addEventListener("keydown",e=>{if(e.key==="Enter"&&!document.getElementById("LS").classList.contains("gone"))doLogin()});

// ══ INIT ══
function initPanel(tools){
  document.getElementById("tbu").textContent="◈ "+currentUser;
  updateClock(); setInterval(updateClock,1000);
  buildSidebar();
  buildToolStatus(tools||{});
}
function updateClock(){
  const n=new Date();
  document.getElementById("clk").textContent=n.toLocaleTimeString("tr-TR",{hour12:false});
}

// ══ SIDEBAR ══
const SIDEBAR = [
  {group:"AKTIF TARAMA", items:[
    {id:"ip",icon:"🌐",label:"IP Analizi",mode:"ip"},
    {id:"domain",icon:"🔗",label:"Domain / DNS",mode:"domain"},
    {id:"email",icon:"✉️",label:"E-Posta",mode:"email"},
    {id:"phone",icon:"📞",label:"Telefon",mode:"phone"},
    {id:"username",icon:"👤",label:"Kullanıcı Adı",mode:"username"},
    {id:"url",icon:"🔍",label:"URL / Site",mode:"url"},
    {id:"breach",icon:"💀",label:"İhlal Araması",mode:"breach"},
    {id:"network",icon:"⚡",label:"Ağ Tarama",mode:"network"},
    {id:"image",icon:"🖼️",label:"EXIF / Görsel",mode:"image"},
  ]},
  {group:"OSINT REFERANS", items:[
    {id:"ref-person",icon:"👤",label:"Kişi & Kimlik",url:"https://pipl.com"},
    {id:"ref-social",icon:"📱",label:"Sosyal Medya",url:"https://whatsmyname.app"},
    {id:"ref-darkweb",icon:"🕵️",label:"Dark Web",url:"https://intelx.io"},
    {id:"ref-map",icon:"🗺️",label:"Harita & Konum",url:"https://earth.google.com"},
    {id:"ref-ship",icon:"🚢",label:"Gemi Takip",url:"https://marinetraffic.com"},
    {id:"ref-flight",icon:"✈️",label:"Uçuş Takip",url:"https://flightradar24.com"},
    {id:"ref-company",icon:"🏢",label:"Şirket & Finans",url:"https://opencorporates.com"},
    {id:"ref-crypto",icon:"₿",label:"Blockchain",url:"https://etherscan.io"},
    {id:"ref-framework",icon:"🛠️",label:"OSINT Framework",url:"https://osintframework.com"},
  ]}
];

function buildSidebar(){
  let h="";
  SIDEBAR.forEach(g=>{
    h+=`<div class="sb-group">${g.group}</div>`;
    g.items.forEach(item=>{
      if(item.mode){
        h+=`<div class="sb-item" id="si-${item.id}" onclick="selectMode('${item.mode}','${item.label}')">
          <span class="sb-icon">${item.icon}</span>
          <span class="sb-label">${item.label}</span>
        </div>`;
      } else {
        h+=`<div class="sb-item" onclick="window.open('${item.url}','_blank')">
          <span class="sb-icon">${item.icon}</span>
          <span class="sb-label">${item.label}</span>
          <span style="font-size:8px;color:var(--dim)">↗</span>
        </div>`;
      }
    });
  });
  document.getElementById("SB").innerHTML=h;
  setActiveSidebar("ip");
}

function setActiveSidebar(id){
  document.querySelectorAll(".sb-item").forEach(el=>el.classList.remove("act"));
  const el=document.getElementById("si-"+id);
  if(el) el.classList.add("act");
}

function selectMode(mode,label){
  document.getElementById("tmode").value=mode;
  document.getElementById("tool-title").textContent="◈ "+label.toUpperCase();
  setActiveSidebar(mode);
  const placeholders={
    ip:"IP adresi (örn: 8.8.8.8)",
    domain:"Domain (örn: example.com)",
    email:"E-posta (örn: user@example.com)",
    phone:"Telefon (örn: +905xxxxxxxxx)",
    username:"Kullanıcı adı (örn: johndoe)",
    url:"URL (örn: https://example.com)",
    breach:"E-posta veya kullanıcı adı",
    network:"IP veya domain (nmap + traceroute)",
    image:"← 📸 butonuna tıklayın"
  };
  document.getElementById("tinp").placeholder=placeholders[mode]||"Hedef girin...";
  document.getElementById("tinp").focus();
}

function buildToolStatus(tools){
  const items=[
    {label:"nmap",key:"nmap"},{label:"whois",key:"whois"},
    {label:"curl",key:"curl"},{label:"dig",key:"dig"}
  ];
  document.getElementById("tool-status").innerHTML=items.map(t=>
    `<div class="tool-indicator"><div class="ti-dot ${tools[t.key]?'on':'off'}"></div><span style="font-size:9px;color:var(--dim)">${t.label}</span></div>`
  ).join("");
}

// ══ API ══
function openApiModal(){document.getElementById("apiMod").classList.add("open")}
function closeApiModal(e){if(!e||e.target===document.getElementById("apiMod"))document.getElementById("apiMod").classList.remove("open")}
async function saveApiKeys(){
  const keys={};
  ["shodan","virustotal","abuseipdb","hunter","hibp","urlscan","securitytrails","leakcheck"].forEach(k=>{
    const v=document.getElementById("k-"+k).value.trim();
    if(v) keys[k]=v;
  });
  try{
    const r=await fetch("/api/keys",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(keys)});
    const d=await r.json();
    if(d.ok){
      closeApiModal();
      showToast("API Keys kaydedildi: "+d.data.saved.join(", "));
    }
  }catch(e){showToast("Hata: "+e.message,true)}
}

// ══ SCAN ══
document.getElementById("tinp").addEventListener("keydown",e=>{if(e.key==="Enter")runScan()});

async function runScan(){
  const target=document.getElementById("tinp").value.trim();
  const mode=document.getElementById("tmode").value;
  if(!target||mode==="image"){return}
  const t0=Date.now();
  const btn=document.getElementById("rbtn");
  btn.classList.add("loading"); btn.textContent="◉ TARANIYOR...";
  document.getElementById("empty-state") && document.getElementById("empty-state").remove();
  try{
    const r=await fetch(`/api/scan/${mode}`,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({target})});
    const d=await r.json();
    const ms=Date.now()-t0;
    if(d.ok){
      renderResults(mode,target,d.data,ms);
      scanCount++; document.getElementById("s-scans").textContent=scanCount;
      document.getElementById("s-time").textContent=ms+"ms";
    } else { showError(d.error||"Bilinmeyen hata"); }
  }catch(e){showError(e.message)}
  btn.classList.remove("loading"); btn.textContent="⚡ TARA";
}

async function handleImage(inp){
  const file=inp.files[0]; if(!file) return;
  const reader=new FileReader();
  reader.onload=async function(e){
    const b64=e.target.result.split(",")[1];
    const btn=document.getElementById("rbtn");
    btn.classList.add("loading"); btn.textContent="◉ EXIF OKUMA...";
    document.getElementById("empty-state") && document.getElementById("empty-state").remove();
    try{
      const r=await fetch("/api/upload/image",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({data:b64})});
      const d=await r.json();
      if(d.ok) renderResults("image",file.name,d.data,0);
      else showError(d.error);
    }catch(e){showError(e.message)}
    btn.classList.remove("loading"); btn.textContent="⚡ TARA";
  };
  reader.readAsDataURL(file);
  inp.value="";
}

// ══ RENDER ══
function renderResults(mode,target,data,ms){
  const res=document.getElementById("RES");
  const wrap=document.createElement("div");
  wrap.innerHTML=buildResultHTML(mode,target,data,ms);
  res.insertBefore(wrap,res.firstChild);
  countHits(data);
}

function buildResultHTML(mode,target,data,ms){
  const modeLabels={ip:"IP ANALİZİ",domain:"DOMAIN & DNS",email:"E-POSTA OSINT",phone:"TELEFON OSINT",
    username:"KULLANICI ADI",url:"URL TARAMA",breach:"İHLAL ARAMASI",network:"AĞ TARAMA",image:"EXIF ANALİZİ"};
  let html=`<div class="rc">
    <div class="rc-head" onclick="this.nextElementSibling.classList.toggle('collapsed')">
      <span class="rc-icon">${getModeIcon(mode)}</span>
      <span class="rc-title">${modeLabels[mode]||mode.toUpperCase()} — <span style="color:var(--c)">${escH(target)}</span></span>
      <span class="rc-badge info">${ms}ms</span>
      <span style="font-size:12px;color:var(--dim);margin-left:8px">▾</span>
    </div>
    <div class="rc-body">`;

  if(mode==="ip") html+=renderIP(data);
  else if(mode==="domain") html+=renderDomain(data);
  else if(mode==="email") html+=renderEmail(data);
  else if(mode==="phone") html+=renderPhone(data);
  else if(mode==="username") html+=renderUsername(data);
  else if(mode==="url") html+=renderURL(data);
  else if(mode==="breach") html+=renderBreach(data);
  else if(mode==="network") html+=renderNetwork(data);
  else if(mode==="image") html+=renderImage(data);
  else html+=renderGeneric(data);

  html+=`</div></div>`;
  return html;
}

function getModeIcon(m){return{ip:"🌐",domain:"🔗",email:"✉️",phone:"📞",username:"👤",url:"🔍",breach:"💀",network:"⚡",image:"🖼️"}[m]||"◈"}

function field(key,val){
  if(!val&&val!==0&&val!==false) return "";
  return `<div class="rf"><div class="rf-key">${escH(key)}</div><div class="rf-val">${formatVal(val)}</div></div>`;
}
function termField(key,val){
  if(!val) return "";
  return `<div class="rf" style="grid-column:1/-1"><div class="rf-key">${escH(key)}</div><div class="rf-val pre terminal">${escH(val)}</div></div>`;
}
function listField(key,items){
  if(!items||!items.length) return "";
  return `<div class="rf"><div class="rf-key">${escH(key)}</div><ul class="rf-list">${items.map(i=>`<li>${escH(String(i))}</li>`).join("")}</ul></div>`;
}
function formatVal(v){
  if(typeof v==="boolean") return v?`<span style="color:var(--r)">⚠ EVET</span>`:`<span style="color:var(--g)">✓ HAYIR</span>`;
  if(typeof v==="number") return `<span style="color:var(--gold)">${v}</span>`;
  if(typeof v==="string"&&v.startsWith("http")) return `<a href="${escH(v)}" target="_blank" rel="noopener">${escH(v)}</a>`;
  return escH(String(v));
}
function escH(s){return String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;")}
function scoreBar(score,max=100){
  const pct=Math.min(100,Math.round(score/max*100));
  const col=pct>70?`var(--r)`:pct>30?`var(--gold)`:`var(--g)`;
  return `<div class="score-bar"><div class="score-fill" style="width:${pct}%;background:${col}"></div></div>`;
}

// ─── IP ───
function renderIP(d){
  let h="";
  if(d.ipinfo){
    const i=d.ipinfo;
    h+=field("IP",i.ip)+field("HOSTNAME",i.hostname)+field("ŞEHİR",i.city)+
       field("BÖLGE",i.region)+field("ÜLKE",i.country)+field("ORG / ISP",i.org)+
       field("TIMEZONE",i.timezone)+field("KOORDİNAT",i.loc);
    if(i.loc){
      const [lat,lon]=i.loc.split(",");
      h+=`<div class="rf"><div class="rf-key">HARİTA</div><div class="rf-val">
        <a href="https://www.google.com/maps?q=${lat},${lon}" target="_blank" rel="noopener">📍 Google Maps'te Aç</a></div></div>`;
    }
  }
  if(d.abuseipdb){
    const a=d.abuseipdb;
    h+=`<div class="rf"><div class="rf-key">ABUSE SKORU</div><div class="rf-val">${a.abuse_score}/100${scoreBar(a.abuse_score)}</div></div>`;
    h+=field("TOPLAM RAPOR",a.total_reports)+field("ISP",a.isp)+field("KULLANIM TİPİ",a.usage_type)+
       field("TOR ÇIKIŞI",a.is_tor)+field("SON RAPOR",a.last_reported);
  }
  if(d.greynoise){
    const g=d.greynoise;
    h+=field("GREYNOISE GÜRÜLTÜ",g.noise)+field("GN SINIFLANDIRMA",g.classification)+field("GN İSİM",g.name);
  }
  if(d.shodan){
    const s=d.shodan;
    h+=listField("AÇIK PORTLAR",s.ports)+listField("CVE ZAAFIYETLER",s.vulns)+
       field("OS",s.os)+listField("HOSTNAME",s.hostnames);
  }
  if(d.nmap) h+=termField("NMAP TARAMA",d.nmap.output);
  if(d.ping) h+=termField("PİNG",d.ping.output);
  return h||noData();
}

// ─── DOMAIN ───
function renderDomain(d){
  let h="";
  ["A","MX","TXT","NS","AAAA"].forEach(r=>{
    if(d[`dns_${r}`]) h+=listField(`DNS ${r} KAYDI`,d[`dns_${r}`].records.filter(Boolean));
  });
  if(d.whois) h+=termField("WHOIS",d.whois.output);
  if(d.crtsh){
    h+=`<div class="rf"><div class="rf-key">CRT.SH — ${d.crtsh.count} SERTIFIKA</div>
      <ul class="rf-list">${(d.crtsh.subdomains||[]).slice(0,15).map(s=>`<li>${escH(s)}</li>`).join("")}</ul></div>`;
  }
  if(d.urlscan&&d.urlscan.results){
    h+=`<div class="rf" style="grid-column:1/-1"><div class="rf-key">URLSCAN SONUÇLARI</div>
      <ul class="rf-list">${d.urlscan.results.map(r=>`<li><a href="${escH(r.url)}" target="_blank" rel="noopener">${escH(r.url)}</a> — ${escH(r.ip||"")} ${escH(r.date||"")}</li>`).join("")}</ul></div>`;
  }
  if(d.virustotal){
    const v=d.virustotal;
    const total=(v.malicious||0)+(v.suspicious||0);
    const badge=total>0?`<span class="rc-badge bad">⚠ ${total} TEHDİT</span>`:`<span class="rc-badge ok">✓ TEMİZ</span>`;
    h+=`<div class="rf"><div class="rf-key">VIRUSTOTAL ${badge}</div>
      <div class="rf-val">Zararlı: ${v.malicious} · Şüpheli: ${v.suspicious} · İtibar: ${v.reputation}</div></div>`;
  }
  return h||noData();
}

// ─── EMAIL ───
function renderEmail(d){
  let h="";
  if(d.emailrep){
    const e=d.emailrep;
    h+=field("İTİBAR",e.reputation)+field("ŞÜPHELİ",e.suspicious)+field("REFERANS SAYISI",e.references);
    if(e.details){
      h+=field("DOMAIN EXİSTS",e.details.domain_exists)+field("DISPOSABLE",e.details.disposable)+
         field("FREE PROVIDER",e.details.free_provider)+field("VALID MX",e.details.valid_mx)+
         field("SPF STRICT",e.details.spf_strict)+field("DMARC ENFORCED",e.details.dmarc_enforced);
    }
  }
  if(d.hunter) h+=renderGenericObj("HUNTER.IO",d.hunter);
  if(d.haveibeenpwned){
    const hib=d.haveibeenpwned;
    h+=`<div class="rf" style="grid-column:1/-1"><div class="rf-key">HAVE I BEEN PWNED — ${hib.breach_count} İHLAL</div>
      <ul class="rf-list">${(hib.breaches||[]).map(b=>`<li>${escH(b.name||b)} <span style="color:var(--dim)">${b.date||""}</span></li>`).join("")}</ul>
      ${hib.note?`<div style="color:var(--g);margin-top:6px;font-size:11px">${escH(hib.note)}</div>`:""}</div>`;
  }
  if(d.mx_check){
    h+=listField("MX KAYITLARI — "+d.mx_check.domain, d.mx_check.mx_records.filter(Boolean));
  }
  // Quick check links
  const email=document.getElementById("tinp").value.trim();
  h+=`<div class="rf" style="grid-column:1/-1"><div class="rf-key">HIZLI KONTROL LİNKLERİ</div>
    <div class="link-chips">
      <a class="chip" href="https://haveibeenpwned.com/account/${encodeURIComponent(email)}" target="_blank">🔍 HIBP</a>
      <a class="chip" href="https://epieos.com/?q=${encodeURIComponent(email)}&t=email" target="_blank">🔍 Epieos</a>
      <a class="chip" href="https://hunter.io/email-verifier/${encodeURIComponent(email)}" target="_blank">🔍 Hunter</a>
      <a class="chip" href="https://intelx.io/?s=${encodeURIComponent(email)}" target="_blank">🔍 IntelX</a>
    </div></div>`;
  return h||noData();
}

// ─── PHONE ───
function renderPhone(d){
  let h="";
  if(d.numlookup&&d.numlookup.valid!==undefined){
    const n=d.numlookup;
    h+=field("GEÇERLİ",n.valid)+field("ÜLKE",n.country)+field("ÜLKE KODU",n.country_code)+
       field("KONUM",n.location)+field("TAŞIYICI",n.carrier)+field("HAT TİPİ",n.line_type);
  }
  if(d.abstract&&d.abstract.valid!==undefined){
    const a=d.abstract;
    h+=field("FORMAT (ULUSLARARASI)",a.format&&a.format.international)+field("FORMAT (YERELHe)",a.format&&a.format.local)+
       field("TAŞIYICI (ABSTRACT)",a.carrier)+field("HAT TİPİ (ABSTRACT)",a.type);
  }
  if(d.links){
    h+=`<div class="rf" style="grid-column:1/-1"><div class="rf-key">ARAMA LİNKLERİ</div>
      <div class="link-chips">
        <a class="chip" href="${d.links.truecaller}" target="_blank">📞 Truecaller</a>
        <a class="chip" href="${d.links.sync_me}" target="_blank">🔍 Sync.me</a>
        <a class="chip" href="${d.links.spydialer}" target="_blank">🔍 SpyDialer</a>
        <a class="chip" href="https://www.google.com/search?q=${encodeURIComponent(document.getElementById('tinp').value.trim())}" target="_blank">🌐 Google</a>
      </div></div>`;
  }
  return h||noData();
}

// ─── USERNAME ───
function renderUsername(d){
  let h="";
  if(d.whatsmyname){
    const w=d.whatsmyname;
    h+=`<div class="rf" style="grid-column:1/-1">
      <div class="rf-key">WHATSMYNAME — ${w.hits} HIT / ${w.checked} SİTE KONTROL EDİLDİ</div>
      <div>${(w.found||[]).map(f=>`<div class="found-item">
        <a href="${escH(f.url)}" target="_blank" rel="noopener">🟢 ${escH(f.name)}</a>
        <span class="cat">${escH(f.category||"")}</span>
      </div>`).join("")}</div></div>`;
  }
  if(d.sherlock) h+=termField("SHERLOCK",d.sherlock.output);
  const uname=document.getElementById("tinp").value.trim();
  h+=`<div class="rf" style="grid-column:1/-1"><div class="rf-key">MANUEL KONTROL LİNKLERİ</div>
    <div class="link-chips">
      <a class="chip" href="https://twitter.com/${encodeURIComponent(uname)}" target="_blank">X/Twitter</a>
      <a class="chip" href="https://instagram.com/${encodeURIComponent(uname)}" target="_blank">Instagram</a>
      <a class="chip" href="https://github.com/${encodeURIComponent(uname)}" target="_blank">GitHub</a>
      <a class="chip" href="https://reddit.com/u/${encodeURIComponent(uname)}" target="_blank">Reddit</a>
      <a class="chip" href="https://t.me/${encodeURIComponent(uname)}" target="_blank">Telegram</a>
      <a class="chip" href="https://www.tiktok.com/@${encodeURIComponent(uname)}" target="_blank">TikTok</a>
      <a class="chip" href="https://namechk.com/" target="_blank">Namechk</a>
    </div></div>`;
  return h||noData();
}

// ─── URL ───
function renderURL(d){
  let h="";
  if(d.virustotal){
    const v=d.virustotal;
    const tot=(v.malicious||0)+(v.suspicious||0);
    h+=`<div class="rf"><div class="rf-key">VİRUSTOTAL ANALİZ</div>
      <div class="rf-val">Zararlı: <span style="color:var(--r)">${v.malicious}</span> · Şüpheli: <span style="color:var(--gold)">${v.suspicious}</span> · Temiz: <span style="color:var(--g)">${v.harmless}</span>
      ${scoreBar(tot,5)}</div></div>`;
  }
  if(d.urlscan){
    h+=field("URLSCAN UUID",d.urlscan.uuid)+field("URLSCAN RAPOR",d.urlscan.result);
  }
  if(d.wayback){
    h+=`<div class="rf"><div class="rf-key">WAYBACK MACHINE</div>
      <div class="rf-val">${d.wayback.available?"<span style='color:var(--g)'>✓ ARŞİV MEVCUT</span>":"Arşiv yok"}<br>
      ${d.wayback.url?`<a href="${escH(d.wayback.url)}" target="_blank">Arşivi Aç</a>`:""}
      <br>Tarih: ${escH(d.wayback.timestamp||"")}</div></div>`;
  }
  if(d.headers) h+=termField("HTTP BAŞLIKLARI",d.headers.output);
  return h||noData();
}

// ─── BREACH ───
function renderBreach(d){
  let h="";
  if(d.breachdirectory){
    const b=d.breachdirectory;
    h+=`<div class="rf" style="grid-column:1/-1"><div class="rf-key">BREACH DIRECTORY — ${b.found||0} İHLAL</div>
      <ul class="rf-list">${(b.results||[]).map(r=>`<li>${escH(typeof r==="string"?r:JSON.stringify(r))}</li>`).join("")}</ul></div>`;
  }
  if(d.hibp){
    h+=listField("HAVEIBEENPWNED — "+d.hibp.count+" İHLAL",d.hibp.breaches);
  }
  if(d.leakcheck) h+=renderGenericObj("LEAKCHECK",d.leakcheck);
  const tgt=document.getElementById("tinp").value.trim();
  h+=`<div class="rf" style="grid-column:1/-1"><div class="rf-key">DİĞER KAYNAKLAR</div>
    <div class="link-chips">
      <a class="chip" href="https://haveibeenpwned.com/account/${encodeURIComponent(tgt)}" target="_blank">HIBP</a>
      <a class="chip" href="https://dehashed.com/search?query=${encodeURIComponent(tgt)}" target="_blank">DeHashed</a>
      <a class="chip" href="https://intelx.io/?s=${encodeURIComponent(tgt)}" target="_blank">IntelX</a>
      <a class="chip" href="https://snusbase.com/" target="_blank">SnusBase</a>
    </div></div>`;
  return h||noData();
}

// ─── NETWORK ───
function renderNetwork(d){
  let h="";
  if(d.nmap) h+=termField("NMAP PORT TARAMA",d.nmap.output);
  if(d.traceroute) h+=termField("TRACEROUTE",d.traceroute.output);
  return h||noData();
}

// ─── IMAGE ───
function renderImage(d){
  let h="";
  if(d.exif){
    if(typeof d.exif==="object"&&!d.exif.output){
      const entries=Object.entries(d.exif).filter(([k,v])=>v&&String(v).length<200);
      const interesting=["GPS","Make","Model","Software","DateTime","Artist","Copyright","CameraOwnerName","LensModel","ExposureTime","FNumber","ISO","Flash","ImageWidth","ImageHeight"];
      const sorted=entries.sort((a,b)=>{
        const ai=interesting.findIndex(i=>a[0].includes(i));
        const bi=interesting.findIndex(i=>b[0].includes(i));
        return (ai===-1?999:ai)-(bi===-1?999:bi);
      });
      sorted.forEach(([k,v])=>{ h+=field(k.toUpperCase(),v); });
    } else {
      h+=termField("EXIF VERİSİ",d.exif.output||JSON.stringify(d.exif,null,2));
    }
  }
  if(d.gps) h+=termField("GPS KOORDİNATLARI",d.gps.output);
  return h||`<div class="rf" style="grid-column:1/-1"><div class="rf-key">SONUÇ</div><div class="rf-val" style="color:var(--dim)">EXIF verisi bulunamadı veya resim metadata içermiyor.</div></div>`;
}

// ─── GENERIC ───
function renderGeneric(d){
  return Object.entries(d).map(([k,v])=>{
    if(typeof v==="object"&&v) return renderGenericObj(k,v);
    return field(k.toUpperCase(),v);
  }).join("");
}
function renderGenericObj(title,obj){
  return `<div class="rf"><div class="rf-key">${escH(title.toUpperCase())}</div>
    <div class="rf-val">${Object.entries(obj).map(([k,v])=>`<b style="color:var(--dim)">${escH(k)}:</b> ${escH(String(v))}`).join("<br>")}</div></div>`;
}
function noData(){return`<div class="rf" style="grid-column:1/-1"><div class="rf-key">SONUÇ</div><div class="rf-val" style="color:var(--dim)">API key girilmemiş veya sonuç bulunamadı. ⚙ API Keys menüsünden key ekleyin.</div></div>`}

// ─── UTILS ───
function countHits(data){
  const str=JSON.stringify(data);
  const found=(str.match(/found|breach|malicious|hit|valid/gi)||[]).length;
  hitCount+=found;
  document.getElementById("s-hits").textContent=hitCount;
}
function clearResults(){
  document.getElementById("RES").innerHTML=`<div class="empty" id="empty-state"><div class="big">👁</div><div>HEDEF GİRİN VE TARAMAYI BAŞLATIN</div><div style="font-size:10px;color:rgba(0,255,247,.25)">Tüm araçlar Termux üzerinde native çalışır</div></div>`;
  scanCount=0;hitCount=0;
  document.getElementById("s-scans").textContent=0;
  document.getElementById("s-hits").textContent=0;
}
function showError(msg){
  const res=document.getElementById("RES");
  document.getElementById("empty-state")&&document.getElementById("empty-state").remove();
  res.insertAdjacentHTML("afterbegin",`<div class="rc"><div class="rc-body"><div class="rf" style="grid-column:1/-1;border-color:var(--r)"><div class="rf-key" style="color:var(--r)">HATA</div><div class="rf-val" style="color:var(--r)">${escH(msg)}</div></div></div></div>`);
}
function showToast(msg,err=false){
  const t=document.createElement("div");
  t.style.cssText=`position:fixed;bottom:50px;left:50%;transform:translateX(-50%);padding:10px 20px;
    background:rgba(2,8,14,.95);border:1px solid ${err?"var(--r)":"var(--g)"};color:${err?"var(--r)":"var(--g)"};
    font-family:'Share Tech Mono',monospace;font-size:12px;letter-spacing:2px;z-index:9000;
    box-shadow:0 0 20px ${err?"rgba(255,51,85,.2)":"rgba(0,255,136,.2)"}`;
  t.textContent=msg;
  document.body.appendChild(t);
  setTimeout(()=>t.remove(),3000);
}
</script>
</body>
</html>
HTMLEOF

# ── Backend başlat ──
python3 "$TMPDIR_PH/server.py" "$PORT" "$TMPDIR_PH" &
SERVER_PID=$!
sleep 1

if kill -0 $SERVER_PID 2>/dev/null; then
  echo -e "\033[32m  [✓] Backend hazır: http://localhost:$PORT\033[0m"
else
  echo -e "\033[31m  [✗] Backend başlatılamadı!\033[0m"
  exit 1
fi

cleanup(){ echo ""; echo -e "\033[36m  [*] PHANTOM OSINT kapatılıyor...\033[0m"; kill $SERVER_PID 2>/dev/null; rm -rf "$TMPDIR_PH"; exit 0; }
trap cleanup INT TERM

wait $SERVER_PID
