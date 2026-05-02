#!/usr/bin/env python3
import os
import sys
import json
import socket
import subprocess
import requests
import re
import urllib3
from datetime import datetime, timedelta
from flask import Flask, request, render_template_string

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

NUCLEI_PATH = "/data/data/com.termux/files/home/go/bin/nuclei"
NVD_API_URL = "https://services.nvd.nist.gov/rest/json/cves/2.0"

app = Flask(__name__)

# ---------- Yardımcı fonksiyonlar ----------
def fetch_cves(params):
    headers = {"User-Agent": "Termux-CVE-Web/1.0"}
    try:
        resp = requests.get(NVD_API_URL, params=params, headers=headers, timeout=30)
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        print(f"[!] API hatası: {e}")
        return None

def extract_cve_info(vuln):
    cve = vuln.get("cve", {})
    cve_id = cve.get("id", "")
    desc = "Açıklama yok"
    for d in cve.get("descriptions", []):
        if d.get("lang") == "en":
            desc = d.get("value", desc)
            break
    metrics = cve.get("metrics", {})
    cvss_score, severity = "N/A", "N/A"
    if "cvssMetricV31" in metrics:
        m = metrics["cvssMetricV31"][0]["cvssData"]
        cvss_score = m.get("baseScore", "N/A")
        severity = m.get("baseSeverity", "N/A")
    elif "cvssMetricV30" in metrics:
        m = metrics["cvssMetricV30"][0]["cvssData"]
        cvss_score = m.get("baseScore", "N/A")
        severity = m.get("baseSeverity", "N/A")
    elif "cvssMetricV2" in metrics:
        m = metrics["cvssMetricV2"][0]["cvssData"]
        cvss_score = m.get("baseScore", "N/A")
        severity = m.get("baseSeverity", "N/A")
    published = cve.get("published", "Tarih yok")
    return {
        "id": cve_id,
        "desc": desc[:200],
        "score": cvss_score,
        "severity": severity,
        "published": published
    }

def filter_testable_cves(cve_ids):
    testable = []
    for cid in cve_ids:
        cmd = f"{NUCLEI_PATH} -id {cid} -s -stats"
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if "no templates provided" not in res.stderr:
            testable.append(cid)
    return testable

def run_nuclei_test(target, cve_id=None, tags=None):
    if cve_id:
        cmd = f"{NUCLEI_PATH} -target {target} -id {cve_id} -silent -stats"
    elif tags:
        cmd = f"{NUCLEI_PATH} -target {target} -tags {tags} -silent -stats"
    else:
        return "Hata: Geçersiz parametre."
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout
        return f"Zafiyet bulunamadı veya hedef erişilemez.\nHata: {result.stderr.strip()}"
    except subprocess.TimeoutExpired:
        return "Test zaman aşımına uğradı (120 sn)."
    except Exception as e:
        return f"Test başarısız: {e}"

def detect_technologies(url):
    detected = set()
    try:
        resp = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=15, verify=False)
    except Exception:
        return detected
    server = resp.headers.get('Server', '').lower()
    powered = resp.headers.get('X-Powered-By', '').lower()
    if server: detected.add(server.split('/')[0].strip())
    if powered: detected.add(powered.split('/')[0].strip())
    content = resp.text.lower()
    if 'wp-content' in content: detected.add('wordpress')
    if 'joomla' in content: detected.add('joomla')
    if 'drupal' in content: detected.add('drupal')
    if 'magento' in content: detected.add('magento')
    if 'shopify' in content: detected.add('shopify')
    if re.search(r'jquery[.\-]?([\d.]+)', content): detected.add('jquery')
    if 'bootstrap' in content: detected.add('bootstrap')
    if 'react' in content: detected.add('react')
    if 'apache' in server or 'apache' in powered: detected.add('apache')
    if 'nginx' in server: detected.add('nginx')
    if 'iis' in server or 'microsoft-iis' in server: detected.add('iis')
    if 'tomcat' in server or 'tomcat' in content: detected.add('tomcat')
    if not detected and server:
        detected.add(server.split('/')[0].strip())
    return detected

# ---------- Base HTML (içerik {{ content|safe }} ile eklenir) ----------
BASE_HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>CVE Paneli</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f4f4f4; }
        .container { max-width: 900px; margin: auto; background: white; padding: 20px; border-radius: 8px; }
        h1 { color: #333; }
        input, select, button { padding: 8px; margin: 5px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
        th { background: #eee; }
        .alert { padding: 10px; background: #ffe0e0; border-left: 5px solid red; margin: 10px 0; }
        .success { background: #e0ffe0; border-left: 5px solid green; }
        pre { background: #333; color: #fff; padding: 10px; overflow-x: auto; }
        a { color: #0066cc; }
    </style>
</head>
<body>
<div class="container">
    <h1>🔍 CVE Sorgulama & Test Paneli</h1>
    <p><a href="/">Ana Sayfa</a> | <a href="/search">CVE Arama</a> | <a href="/scan">Site Tara</a></p>
    <hr>
    {{ content|safe }}
</div>
</body>
</html>
"""

# ---------- Rotalar ----------
@app.route('/')
def index():
    content = """
    <h2>Hoş geldiniz</h2>
    <ul>
        <li><a href="/search">CVE Arama</a> – anahtar kelime, üretici, ID veya son kritikler</li>
        <li><a href="/scan">Site Tara</a> – hedef siteyi tara, teknoloji bul ve CVE'leri test et</li>
    </ul>
    """
    return render_template_string(BASE_HTML, content=content)

@app.route('/search', methods=['GET','POST'])
def search():
    if request.method == 'POST':
        search_type = request.form.get('type')
        params = {"resultsPerPage": 20}
        results = []
        if search_type == 'keyword':
            kw = request.form.get('keyword')
            if not kw:
                return render_template_string(BASE_HTML, content='<div class="alert">Anahtar kelime gerekli.</div>')
            params["keywordSearch"] = kw
            data = fetch_cves(params)
            if data and "vulnerabilities" in data:
                results = [extract_cve_info(v) for v in data["vulnerabilities"]]
        elif search_type == 'vendor':
            vendor = request.form.get('vendor')
            product = request.form.get('product')
            if not vendor:
                return render_template_string(BASE_HTML, content='<div class="alert">Üretici adı gerekli.</div>')
            query = f"{vendor} {product}" if product else vendor
            params["keywordSearch"] = query
            data = fetch_cves(params)
            if data and "vulnerabilities" in data:
                results = [extract_cve_info(v) for v in data["vulnerabilities"]]
        elif search_type == 'id':
            cve_id = request.form.get('cveid', '').upper()
            if not cve_id.startswith("CVE-"):
                return render_template_string(BASE_HTML, content='<div class="alert">Geçerli CVE ID girin.</div>')
            url = f"{NVD_API_URL}?cveId={cve_id}"
            headers = {"User-Agent": "Termux-CVE-Web/1.0"}
            try:
                resp = requests.get(url, headers=headers, timeout=30)
                resp.raise_for_status()
                data = resp.json()
                if data.get("vulnerabilitiesCount", 0) > 0:
                    vuln = data["vulnerabilities"][0]
                    results = [extract_cve_info(vuln)]
            except Exception as e:
                return render_template_string(BASE_HTML, content=f'<div class="alert">ID sorgulanamadı: {e}</div>')
        elif search_type == 'recent':
            end = datetime.now().strftime("%Y-%m-%dT%H:%M:%S.000")
            start = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%dT%H:%M:%S.000")
            params = {
                "pubStartDate": start,
                "pubEndDate": end,
                "severity": "CRITICAL",
                "resultsPerPage": 15
            }
            data = fetch_cves(params)
            if data and "vulnerabilities" in data:
                results = [extract_cve_info(v) for v in data["vulnerabilities"]]
        else:
            return render_template_string(BASE_HTML, content='<div class="alert">Geçersiz arama türü.</div>')

        # Sonuçları tablo ile göster
        if results:
            table_rows = ""
            for r in results:
                table_rows += f"<tr><td>{r['id']}</td><td>{r['severity']}</td><td>{r['score']}</td><td>{r['desc']}</td></tr>"
            content = f"""
            <h2>Arama Sonuçları ({len(results)} adet)</h2>
            <table><tr><th>CVE ID</th><th>Önem</th><th>Puan</th><th>Açıklama</th></tr>{table_rows}</table>
            <p><a href="/search">Yeni Arama</a></p>
            """
        else:
            content = '<p>Hiç sonuç bulunamadı.</p><a href="/search">Yeni Arama</a>'
        return render_template_string(BASE_HTML, content=content)

    # GET isteği: arama formu
    content = """
    <h2>CVE Arama</h2>
    <form method="POST">
        <label>Tür:</label><br>
        <input type="radio" name="type" value="keyword" checked> Anahtar Kelime<br>
        <input type="radio" name="type" value="vendor"> Üretici/Ürün<br>
        <input type="radio" name="type" value="id"> CVE ID<br>
        <input type="radio" name="type" value="recent"> Son 7 Gün Kritik<br><br>
        <div id="keyword_div"><input type="text" name="keyword" placeholder="örn: log4j"></div>
        <div id="vendor_div" style="display:none;">
            <input type="text" name="vendor" placeholder="Üretici (örn: microsoft)">
            <input type="text" name="product" placeholder="Ürün (opsiyonel)">
        </div>
        <div id="id_div" style="display:none;">
            <input type="text" name="cveid" placeholder="CVE-2021-44228">
        </div>
        <div id="recent_div" style="display:none;">
            <p>Otomatik olarak son 7 günün kritik CVE'leri getirilecek.</p>
        </div>
        <button type="submit">Ara</button>
    </form>
    <script>
    const radios = document.getElementsByName('type');
    const divs = {
        keyword: document.getElementById('keyword_div'),
        vendor: document.getElementById('vendor_div'),
        id: document.getElementById('id_div'),
        recent: document.getElementById('recent_div')
    };
    function update() {
        for (let key in divs) divs[key].style.display = 'none';
        const selected = document.querySelector('input[name="type"]:checked').value;
        divs[selected].style.display = 'block';
    }
    radios.forEach(r => r.addEventListener('change', update));
    update();
    </script>
    """
    return render_template_string(BASE_HTML, content=content)

@app.route('/scan', methods=['GET','POST'])
def scan():
    if request.method == 'POST':
        url = request.form.get('url', '').strip()
        if not url:
            return render_template_string(BASE_HTML, content='<div class="alert">URL gerekli.</div>')
        if not url.startswith(('http://','https://')):
            url = 'https://' + url

        techs = detect_technologies(url)
        if not techs:
            return render_template_string(BASE_HTML, content='<div class="alert">Teknoloji tespit edilemedi.</div>')

        all_cve_info = []
        for tech in techs:
            data = fetch_cves({"keywordSearch": tech, "resultsPerPage": 10})
            if data and "vulnerabilities" in data:
                for v in data["vulnerabilities"]:
                    info = extract_cve_info(v)
                    info["tech"] = tech
                    all_cve_info.append(info)

        testable_ids = filter_testable_cves([c['id'] for c in all_cve_info])

        # Tablo: test edilebilir olanları göster
        testable_rows = ""
        if testable_ids:
            for c in all_cve_info:
                if c['id'] in testable_ids:
                    testable_rows += f"<tr><td>{c['id']}</td><td>{c['tech']}</td><td>{c['severity']}</td><td>{c['score']}</td></tr>"

        content = f"""
        <h2>Tarama Sonuçları: {url}</h2>
        <p><b>Tespit edilen teknolojiler:</b> {', '.join(techs)}</p>
        <p>Toplam CVE sayısı: {len(all_cve_info)} | Test edilebilir: {len(testable_ids)}</p>
        """
        if testable_ids:
            content += f"""
            <h3>Test Edilebilir CVE'ler</h3>
            <table><tr><th>CVE ID</th><th>Teknoloji</th><th>Önem</th><th>Puan</th></tr>{testable_rows}</table>
            <form method="POST" action="/test">
                <input type="hidden" name="url" value="{url}">
                <input type="hidden" name="techs" value="{','.join(techs)}">
                <p>Test Seçenekleri:</p>
                <button name="action" value="all_ids">Tüm test edilebilir CVE'leri test et</button>
                <button name="action" value="tags">Teknoloji etiketleriyle toplu test</button><br><br>
                <label>veya belirli CVE'leri seçin (virgülle ayırarak):</label>
                <input type="text" name="selected_cves" placeholder="CVE-2021-...">
                <button name="action" value="selected">Seçilenleri test et</button>
            </form>
            """
        else:
            content += "<p>Test edilebilir CVE bulunamadı.</p>"
        content += '<p><a href="/scan">Yeni tarama</a></p>'
        return render_template_string(BASE_HTML, content=content)

    # GET isteği
    content = """
    <h2>Site Tara</h2>
    <form method="POST">
        <input type="text" name="url" placeholder="https://example.com" required>
        <button type="submit">Taramayı Başlat</button>
    </form>
    """
    return render_template_string(BASE_HTML, content=content)

@app.route('/test', methods=['POST'])
def test():
    url = request.form.get('url')
    techs_str = request.form.get('techs', '')
    action = request.form.get('action')
    selected = request.form.get('selected_cves', '')
    techs = [t.strip() for t in techs_str.split(',') if t.strip()]

    if action == 'tags' and techs:
        tags = ','.join(techs)
        output = run_nuclei_test(url, tags=tags)
        content = f"<h2>Toplu Etiket Testi ({tags})</h2><pre>{output}</pre><a href='/scan'>Geri dön</a>"
        return render_template_string(BASE_HTML, content=content)

    if action == 'all_ids' or action == 'selected':
        if action == 'selected' and selected:
            ids = [s.strip() for s in selected.split(',') if s.strip().startswith('CVE-')]
        else:
            # Tekrar teknoloji tespiti yapıp test edilebilir ID'leri al
            techs_detected = detect_technologies(url)
            all_ids = []
            for tech in techs_detected:
                data = fetch_cves({"keywordSearch": tech, "resultsPerPage": 10})
                if data and "vulnerabilities" in data:
                    all_ids.extend([v["cve"]["id"] for v in data["vulnerabilities"]])
            ids = filter_testable_cves(all_ids)

        outputs = []
        for cid in ids:
            out = run_nuclei_test(url, cve_id=cid)
            outputs.append((cid, out))
        content = "<h2>Bireysel CVE Testleri</h2>"
        for cid, out in outputs:
            content += f"<h3>{cid}</h3><pre>{out}</pre>"
        content += "<a href='/scan'>Geri dön</a>"
        return render_template_string(BASE_HTML, content=content)

    return render_template_string(BASE_HTML, content="<div class='alert'>Geçersiz işlem.</div>")

# ---------- Başlat ----------
def get_random_port():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('', 0))
        return s.getsockname()[1]

if __name__ == '__main__':
    port = get_random_port()
    print(f"\n🌐 Web paneli başlatıldı: http://127.0.0.1:{port}")
    print("Tarayıcınızda bu adresi açın. (Durdurmak için CTRL+C)")
    app.run(host='0.0.0.0', port=port, debug=False)