#!/usr/bin/env python3
import requests
import re
import subprocess
import sys
import urllib3
from datetime import datetime, timedelta

# SSL uyarılarını kapat (kendi sitende test için)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

NVD_API_URL = "https://services.nvd.nist.gov/rest/json/cves/2.0"

def fetch_cves(params):
    """NVD API'den CVE verisi çeker."""
    headers = {"User-Agent": "Termux-CVE-Tool/3.0"}
    try:
        resp = requests.get(NVD_API_URL, params=params, headers=headers, timeout=30)
        resp.raise_for_status()
        return resp.json()
    except requests.exceptions.RequestException as e:
        print(f"\n[!] Bağlantı hatası: {e}")
        return None

def display_results(data, limit=10, return_ids=False):
    """
    CVE sonuçlarını ekrana basar.
    return_ids=True ise bulunan CVE ID'lerinin listesini döndürür.
    """
    cve_ids = []
    if not data or "vulnerabilities" not in data:
        print("[!] Sonuç bulunamadı veya API yanıt vermedi.")
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

        # İngilizce açıklamayı al
        desc = "Açıklama yok"
        for d in cve.get("descriptions", []):
            if d.get("lang") == "en":
                desc = d.get("value", desc)
                break

        # CVSS puanı ve önem derecesi
        metrics = cve.get("metrics", {})
        cvss_score = "N/A"
        severity = "N/A"
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

    if return_ids:
        return cve_ids

def test_cve(target, cve_id):
    """Nuclei kullanarak tek bir CVE'yi hedefe karşı test eder."""
    print(f"\n[*] {cve_id} test ediliyor...")
    cmd = f"nuclei -target {target} -id {cve_id} -silent -stats"
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
        if result.returncode == 0 and result.stdout.strip():
            print(f"[+] Zafiyet doğrulandı:\n{result.stdout}")
        else:
            print(f"[-] {cve_id} doğrulanamadı veya hedef erişilemez.")
            if result.stderr:
                print(f"    Hata: {result.stderr.strip()}")
    except subprocess.TimeoutExpired:
        print("[!] Test zaman aşımına uğradı (120 saniye).")
    except Exception as e:
        print(f"[!] Test çalıştırılamadı: {e}")

# ---------- Sorgulama Fonksiyonları ----------
def search_by_keyword():
    kw = input("Anahtar kelime: ").strip()
    if not kw:
        print("[!] Boş olamaz.")
        return
    print(f"[*] '{kw}' aranıyor...")
    data = fetch_cves({"keywordSearch": kw, "resultsPerPage": 20})
    display_results(data, limit=20)

def search_by_vendor():
    vendor = input("Üretici adı (örn: apache, microsoft): ").strip()
    product = input("Ürün adı (opsiyonel): ").strip()
    if not vendor:
        print("[!] En az üretici adı gereklidir.")
        return
    query = f"{vendor} {product}" if product else vendor
    print(f"[*] '{query}' aranıyor...")
    data = fetch_cves({"keywordSearch": query, "resultsPerPage": 20})
    display_results(data, limit=20)

def search_by_id():
    cve_id = input("CVE ID (örn: CVE-2021-44228): ").strip().upper()
    if not cve_id.startswith("CVE-"):
        print("[!] Geçerli bir CVE ID girin.")
        return
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
        # Referansları göster
        vulns = data.get("vulnerabilities", [])
        if vulns:
            refs = vulns[0].get("cve", {}).get("references", [])
            if refs:
                print("=== Referans Linkler ===")
                for ref in refs[:5]:
                    print(f"  - {ref.get('url')}")
                print()
    except Exception as e:
        print(f"[!] Hata: {e}")

def search_critical_recent():
    print("[*] Son 7 günün kritik CVE'leri getiriliyor...")
    end_date = datetime.now().strftime("%Y-%m-%dT%H:%M:%S.000")
    start_date = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%dT%H:%M:%S.000")
    params = {
        "pubStartDate": start_date,
        "pubEndDate": end_date,
        "severity": "CRITICAL",
        "resultsPerPage": 15
    }
    data = fetch_cves(params)
    display_results(data, limit=15)

# ---------- Site Tara + Test ----------
def scan_site_for_cves():
    url = input("Taranacak site adresi (https:// ile başlamalı): ").strip()
    if not url:
        print("[!] Adres boş olamaz.")
        return
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url

    print(f"[*] {url} adresine bağlanılıyor...")
    headers = {"User-Agent": "Mozilla/5.0 (Linux; Android 12; Mobile) AppleWebKit/537.36"}
    try:
        resp = requests.get(url, headers=headers, timeout=15, verify=False)
    except Exception as e:
        print(f"[!] Siteye bağlanılamadı: {e}")
        return

    if resp.status_code != 200:
        print(f"[!] HTTP {resp.status_code} hatası alındı.")
        return

    print("[*] Bağlantı başarılı. Teknolojiler tespit ediliyor...")
    detected = set()
    server = resp.headers.get('Server', '').lower()
    powered = resp.headers.get('X-Powered-By', '').lower()
    if server:
        detected.add(server.split('/')[0].strip())
    if powered:
        detected.add(powered.split('/')[0].strip())

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
        print("[!] Herhangi bir teknoloji tespit edilemedi.")
        return

    print(f"[+] Tespit edilen teknolojiler: {', '.join(detected)}")

    all_cve_ids = []
    for tech in detected:
        print(f"\n--- {tech} için CVE'ler aranıyor ---")
        data = fetch_cves({"keywordSearch": tech, "resultsPerPage": 10})
        ids = display_results(data, limit=10, return_ids=True)
        all_cve_ids.extend(ids)

    if not all_cve_ids:
        print("[!] Test edilecek CVE bulunamadı.")
        return

    # Test menüsü
    print("\n======== Test Seçenekleri ========")
    print("1. Tespit edilen TÜM CVE'leri test et")
    print("2. İstediğim CVE'leri seçerek test et")
    print("3. Test yapmadan ana menüye dön")
    choice = input("Seçiminiz: ").strip()

    if choice == "1":
        for cid in all_cve_ids:
            test_cve(url, cid)
    elif choice == "2":
        print("Mevcut CVE'ler:")
        for idx, cid in enumerate(all_cve_ids, 1):
            print(f"  {idx}. {cid}")
        nums = input("Test edilecek numaraları boşlukla ayırarak girin (örn: 1 3 5): ").strip()
        try:
            selected = [int(x) - 1 for x in nums.split()]
            for i in selected:
                if 0 <= i < len(all_cve_ids):
                    test_cve(url, all_cve_ids[i])
                else:
                    print(f"[!] {i+1} geçersiz.")
        except:
            print("[!] Hatalı giriş.")
    else:
        print("[*] Test yapılmadı.")

# ---------- Ana Menü ----------
def main():
    while True:
        print("\n" + "=" * 50)
        print("   GELİŞMİŞ CVE SORGULAMA & TEST PANELİ")
        print("=" * 50)
        print("1. Anahtar kelime ile ara")
        print("2. Üretici/ürün adı ile ara")
        print("3. CVE ID'si ile detay sorgula")
        print("4. Son 7 günün kritik CVE'leri")
        print("5. Site Tara (CVE tespiti + Nuclei test)")
        print("6. Çıkış")
        print("-" * 50)
        secim = input("Seçiminiz (1-6): ").strip()
        if secim == "1":
            search_by_keyword()
        elif secim == "2":
            search_by_vendor()
        elif secim == "3":
            search_by_id()
        elif secim == "4":
            search_critical_recent()
        elif secim == "5":
            scan_site_for_cves()
        elif secim == "6":
            print("[*] Çıkış yapılıyor, güvende kalın!")
            sys.exit(0)
        else:
            print("[!] Geçersiz seçim.")

if __name__ == "__main__":
    main()