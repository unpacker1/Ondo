#!/usr/bin/env python3
import requests
import re
from urllib.parse import urlparse, urlunparse
import sys
from datetime import datetime, timedelta

NVD_API_URL = "https://services.nvd.nist.gov/rest/json/cves/2.0"

def fetch_cves(params):
    headers = {"User-Agent": "Termux-CVE-Tool/2.0"}
    try:
        response = requests.get(NVD_API_URL, params=params, headers=headers, timeout=30)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"\n[!] Bağlantı hatası: {e}")
        return None

def display_results(data, limit=10):
    if not data or "vulnerabilities" not in data:
        print("[!] Sonuç bulunamadı veya API yanıt vermedi.")
        return

    cves = data["vulnerabilities"]
    if not cves:
        print("[!] Bu kriterlere uygun CVE bulunamadı.")
        return

    print(f"\n=== Toplam {len(cves)} sonuçtan ilk {min(limit, len(cves))} tanesi gösteriliyor ===\n")

    for i, vuln in enumerate(cves[:limit]):
        cve = vuln.get("cve", {})
        cve_id = cve.get("id", "Bilinmiyor")
        descriptions = cve.get("descriptions", [])
        desc = "Açıklama yok"
        for d in descriptions:
            if d.get("lang") == "en":
                desc = d.get("value", desc)
                break

        metrics = cve.get("metrics", {})
        cvss_score = "N/A"
        severity = "N/A"
        if "cvssMetricV31" in metrics:
            cvss_data = metrics["cvssMetricV31"][0]["cvssData"]
            cvss_score = cvss_data.get("baseScore", "N/A")
            severity = cvss_data.get("baseSeverity", "N/A")
        elif "cvssMetricV30" in metrics:
            cvss_data = metrics["cvssMetricV30"][0]["cvssData"]
            cvss_score = cvss_data.get("baseScore", "N/A")
            severity = cvss_data.get("baseSeverity", "N/A")
        elif "cvssMetricV2" in metrics:
            cvss_data = metrics["cvssMetricV2"][0]["cvssData"]
            cvss_score = cvss_data.get("baseScore", "N/A")
            severity = cvss_data.get("baseSeverity", "N/A")

        published = cve.get("published", "Tarih yok")
        print(f"{i+1}. {cve_id} ({severity} - {cvss_score})")
        print(f"   Tarih: {published}")
        print(f"   {desc[:150]}...\n")

def search_by_keyword():
    keyword = input("Aranacak anahtar kelime: ")
    if not keyword:
        print("[!] Anahtar kelime boş olamaz.")
        return
    params = {"keywordSearch": keyword, "resultsPerPage": 20}
    data = fetch_cves(params)
    display_results(data, limit=20)

def search_by_vendor():
    vendor = input("Üretici adı (örnek: microsoft, apache): ")
    product = input("Ürün adı (opsiyonel, boş bırakılabilir): ")
    if not vendor:
        print("[!] En az üretici adı gereklidir.")
        return
    # Artık doğrudan anahtar kelime ile arama yapıyoruz (cpeName hatasını önlemek için)
    if product:
        query = f"{vendor} {product}"
    else:
        query = vendor
    print(f"[*] '{query}' için esnek arama yapılıyor...")
    params = {"keywordSearch": query, "resultsPerPage": 20}
    data = fetch_cves(params)
    display_results(data, limit=20)

def search_by_id():
    cve_id = input("CVE ID (örnek: CVE-2021-44228): ").upper()
    if not cve_id.startswith("CVE-"):
        print("[!] Geçerli bir CVE ID'si girin (CVE- formatında).")
        return
    url = f"{NVD_API_URL}?cveId={cve_id}"
    headers = {"User-Agent": "Termux-CVE-Tool/2.0"}
    try:
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        data = response.json()
        if data.get("vulnerabilitiesCount", 0) == 0:
            print(f"[!] '{cve_id}' bulunamadı.")
            return
        display_results(data, limit=1)
        vulns = data.get("vulnerabilities", [])
        if vulns:
            references = vulns[0].get("cve", {}).get("references", [])
            if references:
                print("=== Referans Linkler ===")
                for ref in references[:5]:
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

def scan_site_for_cves():
    """Verilen bir siteye ait teknolojileri bulup ilgili CVE'leri listeler."""
    url = input("Taranacak site adresi (örnek: https://example.com): ").strip()
    if not url:
        print("[!] Adres boş olamaz.")
        return

    # URL'i düzgün biçimlendir
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url

    print(f"[*] {url} adresine bağlanılıyor...")
    headers = {"User-Agent": "Mozilla/5.0 (Linux; Android 12; Mobile) AppleWebKit/537.36"}
    try:
        response = requests.get(url, headers=headers, timeout=15, verify=False)
    except requests.exceptions.SSLError:
        print("[!] SSL hatası, sertifika doğrulaması atlanıyor...")
        # SSL uyarısını kapat (sadece pasif tarama için)
        import urllib3
        urllib3.disable_warnings()
        response = requests.get(url, headers=headers, timeout=15, verify=False)
    except Exception as e:
        print(f"[!] Siteye bağlanılamadı: {e}")
        return

    if response.status_code != 200:
        print(f"[!] HTTP {response.status_code} hatası alındı.")
        return

    print(f"[*] Bağlantı başarılı (HTTP {response.status_code}). Teknolojiler taranıyor...")

    # Tespit edilecek teknoloji isimleri (ürün adayları)
    detected_tech = set()

    # 1. HTTP yanıt başlıklarından
    server = response.headers.get('Server', '').lower()
    powered_by = response.headers.get('X-Powered-By', '').lower()
    if server:
        detected_tech.add(server.split('/')[0].strip())
    if powered_by:
        detected_tech.add(powered_by.split('/')[0].strip())

    # 2. Sayfa içeriğinden basit regex'lerle
    content = response.text.lower()
    # Yaygın CMS / Framework ipuçları
    if 'wp-content' in content:
        detected_tech.add('wordpress')
    if 'joomla' in content:
        detected_tech.add('joomla')
    if 'drupal' in content:
        detected_tech.add('drupal')
    if 'magento' in content:
        detected_tech.add('magento')
    if 'shopify' in content:
        detected_tech.add('shopify')
    # JavaScript kütüphaneleri
    jquery_match = re.search(r'jquery[.-]?([\d.]+)', content)
    if jquery_match:
        detected_tech.add('jquery')
    if 'bootstrap' in content:
        detected_tech.add('bootstrap')
    if 'react' in content:
        detected_tech.add('react')
    # Sunucu ipuçları
    if 'apache' in server or 'apache' in powered_by:
        detected_tech.add('apache')
    if 'nginx' in server:
        detected_tech.add('nginx')
    if 'iis' in server or 'microsoft-iis' in server:
        detected_tech.add('iis')
    if 'tomcat' in server or 'tomcat' in content:
        detected_tech.add('tomcat')

    # Hiçbir şey bulunamadıysa genel sunucu adını kullan
    if not detected_tech and server:
        detected_tech.add(server.split('/')[0].strip())

    if not detected_tech:
        print("[!] Herhangi bir teknoloji tespit edilemedi.")
        return

    print(f"[+] Tespit edilen teknolojiler: {', '.join(detected_tech)}")

    # Her teknoloji için CVE ara
    for tech in detected_tech:
        print(f"\n--- {tech} için CVE'ler aranıyor ---")
        params = {"keywordSearch": tech, "resultsPerPage": 10}
        data = fetch_cves(params)
        if data:
            display_results(data, limit=10)
        else:
            print("[!] Sorgu başarısız.")

def main_menu():
    while True:
        print("\n" + "="*50)
        print("   🔍 GELİŞMİŞ CVE SORGULAMA PANELİ")
        print("="*50)
        print("1. Anahtar kelime ile ara")
        print("2. Üretici/ürün adı ile ara (esnek)")
        print("3. CVE ID'si ile detay sorgula")
        print("4. Son 7 günün kritik CVE'leri")
        print("5. Site Tara (Teknoloji + CVE tespiti)")
        print("6. Çıkış")
        print("-"*50)

        choice = input("Seçiminiz (1-6): ").strip()
        if choice == "1":
            search_by_keyword()
        elif choice == "2":
            search_by_vendor()
        elif choice == "3":
            search_by_id()
        elif choice == "4":
            search_critical_recent()
        elif choice == "5":
            scan_site_for_cves()
        elif choice == "6":
            print("[*] Çıkış yapılıyor, güvende kalın!")
            sys.exit(0)
        else:
            print("[!] Geçersiz seçim. Tekrar deneyin.")

if __name__ == "__main__":
    main_menu()