#!/usr/bin/env python3
import requests
import re
import subprocess
import sys
from datetime import datetime, timedelta

NVD_API_URL = "https://services.nvd.nist.gov/rest/json/cves/2.0"

def fetch_cves(params):
    headers = {"User-Agent": "Termux-CVE-Tool/3.0"}
    try:
        response = requests.get(NVD_API_URL, params=params, headers=headers, timeout=30)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"\n[!] Bağlantı hatası: {e}")
        return None

def display_results(data, limit=10, return_ids=False):
    """Sonuçları gösterir, istenirse CVE ID listesini döndürür."""
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
        # ... (önceki görüntüleme kodunun aynısı)
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
    if return_ids:
        return cve_ids

def test_cve(target, cve_id):
    """Nuclei ile belirli bir CVE'yi test eder."""
    print(f"\n[*] {cve_id} test ediliyor...")
    cmd = f"nuclei -target {target} -id {cve_id} -silent -stats"
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
        if result.returncode == 0 and result.stdout:
            print(f"[+] Zafiyet doğrulandı:\n{result.stdout}")
        else:
            print(f"[-] {cve_id} doğrulanamadı veya hedef erişilemez.")
            if result.stderr:
                print(f"    Hata: {result.stderr.strip()}")
    except subprocess.TimeoutExpired:
        print("[!] Test zaman aşımına uğradı.")
    except Exception as e:
        print(f"[!] Test çalıştırılamadı: {e}")

def scan_site_for_cves():
    url = input("Taranacak site adresi (örnek: https://example.com): ").strip()
    if not url:
        print("[!] Adres boş olamaz.")
        return
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url

    print(f"[*] {url} adresine bağlanılıyor...")
    headers = {"User-Agent": "Mozilla/5.0 (Linux; Android 12; Mobile) AppleWebKit/537.36"}
    try:
        response = requests.get(url, headers=headers, timeout=15, verify=False)
    except requests.exceptions.SSLError:
        import urllib3
        urllib3.disable_warnings()
        response = requests.get(url, headers=headers, timeout=15, verify=False)
    except Exception as e:
        print(f"[!] Siteye bağlanılamadı: {e}")
        return

    if response.status_code != 200:
        print(f"[!] HTTP {response.status_code} hatası alındı.")
        return

    print(f"[*] Bağlantı başarılı. Teknolojiler taranıyor...")
    detected_tech = set()
    server = response.headers.get('Server', '').lower()
    powered_by = response.headers.get('X-Powered-By', '').lower()
    if server:
        detected_tech.add(server.split('/')[0].strip())
    if powered_by:
        detected_tech.add(powered_by.split('/')[0].strip())

    content = response.text.lower()
    if 'wp-content' in content: detected_tech.add('wordpress')
    if 'joomla' in content: detected_tech.add('joomla')
    if 'drupal' in content: detected_tech.add('drupal')
    if 'magento' in content: detected_tech.add('magento')
    if 'shopify' in content: detected_tech.add('shopify')
    if re.search(r'jquery[.-]?([\d.]+)', content): detected_tech.add('jquery')
    if 'bootstrap' in content: detected_tech.add('bootstrap')
    if 'react' in content: detected_tech.add('react')
    if 'apache' in server or 'apache' in powered_by: detected_tech.add('apache')
    if 'nginx' in server: detected_tech.add('nginx')
    if 'iis' in server or 'microsoft-iis' in server: detected_tech.add('iis')
    if 'tomcat' in server or 'tomcat' in content: detected_tech.add('tomcat')

    if not detected_tech and server:
        detected_tech.add(server.split('/')[0].strip())

    if not detected_tech:
        print("[!] Herhangi bir teknoloji tespit edilemedi.")
        return

    print(f"[+] Tespit edilen teknolojiler: {', '.join(detected_tech)}")

    all_cve_ids = []
    for tech in detected_tech:
        print(f"\n--- {tech} için CVE'ler aranıyor ---")
        params = {"keywordSearch": tech, "resultsPerPage": 10}
        data = fetch_cves(params)
        ids = display_results(data, limit=10, return_ids=True)
        all_cve_ids.extend(ids)

    if not all_cve_ids:
        print("[!] Test edilecek CVE bulunamadı.")
        return

    # Test seçeneği sun
    print("\n======== Test Seçenekleri ========")
    print("1. Tespit edilen tüm CVE'leri test et")
    print("2. İstediğim CVE'leri seçerek test et")
    print("3. Test yapmadan ana menüye dön")
    choice = input("Seçiminiz: ").strip()

    if choice == "1":
        for cve_id in all_cve_ids:
            test_cve(url, cve_id)
    elif choice == "2":
        print("Mevcut CVE'ler:")
        for idx, cid in enumerate(all_cve_ids, 1):
            print(f"  {idx}. {cid}")
        nums = input("Test etmek istediğiniz CVE numaralarını boşlukla ayırarak girin (örn: 1 3 5): ")
        try:
            selected_indices = [int(x) - 1 for x in nums.split()]
            for i in selected_indices:
                if 0 <= i < len(all_cve_ids):
                    test_cve(url, all_cve_ids[i])
        except:
            print("[!] Geçersiz giriş.")
    else:
        print("[*] Test yapılmadı.")

# Diğer fonksiyonlar (search_by_keyword, vs.) aynı kalabilir
# main_menu da aynı