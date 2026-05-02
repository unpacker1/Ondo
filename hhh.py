#!/usr/bin/env python3
import requests
import re
import subprocess
import sys
import urllib3
from datetime import datetime, timedelta

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

NVD_API_URL = "https://services.nvd.nist.gov/rest/json/cves/2.0"
NUCLEI_PATH = "/data/data/com.termux/files/home/go/bin/nuclei"

def fetch_cves(params):
    headers = {"User-Agent": "Termux-CVE-Tool/3.0"}
    try:
        resp = requests.get(NVD_API_URL, params=params, headers=headers, timeout=30)
        resp.raise_for_status()
        return resp.json()
    except requests.exceptions.RequestException as e:
        print(f"\n[!] Bağlantı hatası: {e}")
        return None

def display_results(data, limit=10, return_ids=False):
    cve_ids = []
    if not data or "vulnerabilities" not in data:
        print("[!] Sonuç bulunamadı.")
        return cve_ids if return_ids else None

    cves = data["vulnerabilities"]
    if not cves:
        print("[!] Bu kriterlere uygun CVE bulunamadı.")
        return cve_ids if return_ids else None

    print(f"\n=== Toplam {len(cves)} sonuçtan ilk {min(limit, len(cves))} tanesi gösteriliyor ===\n")
    for i, vuln in enumerate(cves[:limit]):
        cve = vuln.get("cve", {})
        cve_id = cve.get("id", "")
        if cve_id:
            cve_ids.append(cve_id)

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
        print(f"{i+1}. {cve_id} ({severity} - {cvss_score})")
        print(f"   Tarih: {published}")
        print(f"   {desc[:150]}...\n")

    return cve_ids if return_ids else None

def test_cve(target, cve_id):
    """Tek bir CVE ID'sini Nuclei ile test eder (şablon varsa)."""
    print(f"\n[*] {cve_id} test ediliyor...")
    cmd = f"{NUCLEI_PATH} -target {target} -id {cve_id} -silent -stats"
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
        if result.returncode == 0 and result.stdout.strip():
            print(f"[+] Zafiyet doğrulandı:\n{result.stdout}")
        else:
            print(f"[-] {cve_id} doğrulanamadı veya hedef erişilemez.")
            if result.stderr:
                # Şablon yoksa hata mesajını kısaltalım
                if "no templates provided" in result.stderr:
                    print("    (Bu CVE için Nuclei şablonu bulunmuyor)")
                else:
                    print(f"    Hata: {result.stderr.strip()}")
    except subprocess.TimeoutExpired:
        print("[!] Test zaman aşımına uğradı (120 saniye).")
    except Exception as e:
        print(f"[!] Test çalıştırılamadı: {e}")

def test_tech_tags(target, tech_set):
    """Verilen teknoloji kümesi için Nuclei etiket taraması yapar."""
    tags = ",".join(tech_set)
    print(f"\n[*] '{tags}' etiketleriyle toplu test yapılıyor...")
    cmd = f"{NUCLEI_PATH} -target {target} -tags {tags} -silent -stats"
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=180)
        if result.returncode == 0 and result.stdout.strip():
            print(f"[+] Bulunan zafiyetler:\n{result.stdout}")
        else:
            print("[-] Etiket taramasında bir şey bulunamadı veya hedef erişilemez.")
            if result.stderr and "no templates provided" not in result.stderr:
                print(f"    Hata: {result.stderr.strip()}")
    except subprocess.TimeoutExpired:
        print("[!] Etiket testi zaman aşımına uğradı.")
    except Exception as e:
        print(f"[!] Etiket testi başarısız: {e}")

def search_by_keyword():
    kw = input("Anahtar kelime: ").strip()
    if not kw: return
    print(f"[*] '{kw}' aranıyor...")
    display_results(fetch_cves({"keywordSearch": kw, "resultsPerPage": 20}), limit=20)

def search_by_vendor():
    vendor = input("Üretici adı: ").strip()
    product = input("Ürün adı (opsiyonel): ").strip()
    if not vendor: return
    query = f"{vendor} {product}" if product else vendor
    data = fetch_cves({"keywordSearch": query, "resultsPerPage": 20})
    display_results(data, limit=20)

def search_by_id():
    cve_id = input("CVE ID: ").strip().upper()
    if not cve_id.startswith("CVE-"): return
    url = f"{NVD_API_URL}?cveId={cve_id}"
    headers = {"User-Agent": "Termux-CVE-Tool/3.0"}
    try:
        resp = requests.get(url, headers=headers, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        if data.get("vulnerabilitiesCount", 0) == 0:
            print(f"[!] {cve_id} bulunamadı.")
            return
        display_results(data, limit=1)
    except Exception as e:
        print(f"[!] Hata: {e}")

def search_critical_recent():
    print("[*] Son 7 günün kritik CVE'leri...")
    end_date = datetime.now().strftime("%Y-%m-%dT%H:%M:%S.000")
    start_date = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%dT%H:%M:%S.000")
    display_results(fetch_cves({
        "pubStartDate": start_date,
        "pubEndDate": end_date,
        "severity": "CRITICAL",
        "resultsPerPage": 15
    }), limit=15)

def scan_site_for_cves():
    url = input("Taranacak site adresi (https:// ile başlamalı): ").strip()
    if not url: return
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url

    print(f"[*] {url} adresine bağlanılıyor...")
    try:
        resp = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=15, verify=False)
    except Exception as e:
        print(f"[!] Bağlanılamadı: {e}")
        return

    if resp.status_code != 200:
        print(f"[!] HTTP {resp.status_code}")
        return

    print("[*] Teknolojiler tespit ediliyor...")
    detected = set()
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

    if not detected:
        print("[!] Teknoloji bulunamadı.")
        return

    print(f"[+] Tespit edilen teknolojiler: {', '.join(detected)}")

    all_cve_ids = []
    for tech in detected:
        print(f"\n--- {tech} için CVE'ler aranıyor ---")
        ids = display_results(fetch_cves({"keywordSearch": tech, "resultsPerPage": 10}), limit=10, return_ids=True)
        if ids:
            all_cve_ids.extend(ids)

    # TEST MENÜSÜ (genişletilmiş)
    while True:
        print("\n======== TEST SEÇENEKLERİ ========")
        print("1. Tüm CVE'leri ID ile test et (şablonu olanlar)")
        print("2. Tespit edilen teknolojilere ait ETİKETLERLE toplu test")
        print("3. Belirli CVE'leri seçerek test et")
        print("4. Test yapmadan ana menüye dön")
        ch = input("Seçiminiz: ").strip()

        if ch == "1":
            for cid in all_cve_ids:
                test_cve(url, cid)
            break
        elif ch == "2":
            test_tech_tags(url, detected)
            break
        elif ch == "3":
            print("Mevcut CVE'ler:")
            for idx, cid in enumerate(all_cve_ids, 1):
                print(f"  {idx}. {cid}")
            nums = input("Numaralar (örn: 1 3 5): ").strip()
            try:
                for i in [int(x)-1 for x in nums.split()]:
                    if 0 <= i < len(all_cve_ids):
                        test_cve(url, all_cve_ids[i])
            except:
                print("[!] Hatalı giriş.")
            break
        elif ch == "4":
            print("[*] Test yapılmadı.")
            break
        else:
            print("[!] Geçersiz seçim.")

def main():
    while True:
        print("\n" + "="*50)
        print("   GELİŞMİŞ CVE SORGULAMA & TEST PANELİ")
        print("="*50)
        print("1. Anahtar kelime ile ara")
        print("2. Üretici/ürün adı ile ara")
        print("3. CVE ID'si ile detay sorgula")
        print("4. Son 7 günün kritik CVE'leri")
        print("5. Site Tara (teknoloji + CVE + Nuclei test)")
        print("6. Çıkış")
        secim = input("Seçiminiz (1-6): ").strip()
        if secim == "1": search_by_keyword()
        elif secim == "2": search_by_vendor()
        elif secim == "3": search_by_id()
        elif secim == "4": search_critical_recent()
        elif secim == "5": scan_site_for_cves()
        elif secim == "6": sys.exit(0)
        else: print("[!] Geçersiz seçim.")

if __name__ == "__main__":
    main()