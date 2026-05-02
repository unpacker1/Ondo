#!/usr/bin/env python3
import requests
import json
import sys
from datetime import datetime, timedelta

# NVD API 2.0 temel adresi
NVD_API_URL = "https://services.nvd.nist.gov/rest/json/cves/2.0"

def fetch_cves(params):
    """NVD API'ye istek atar ve sonuçları döndürür."""
    headers = {"User-Agent": "Termux-CVE-Panel/1.0"}
    try:
        response = requests.get(NVD_API_URL, params=params, headers=headers, timeout=30)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"\n[!] Bağlantı hatası: {e}")
        return None

def display_results(data, limit=10):
    """Gelen JSON verisini okunabilir şekilde ekrana basar."""
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
        
        # Açıklamayı al
        descriptions = cve.get("descriptions", [])
        desc = "Açıklama yok"
        for d in descriptions:
            if d.get("lang") == "en":
                desc = d.get("value", desc)
                break
        
        # CVSS puanını al (eğer varsa)
        metrics = cve.get("metrics", {})
        cvss_score = "N/A"
        severity = "N/A"
        
        # CVSS v3.1'i dene
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

        # Yayınlanma tarihi
        published = cve.get("published", "Tarih yok")
        
        print(f"{i+1}. {cve_id} ({severity} - {cvss_score})")
        print(f"   Tarih: {published}")
        print(f"   {desc[:150]}...\n")

def search_by_keyword():
    """Anahtar kelime ile arama yapar."""
    keyword = input("Aranacak anahtar kelime: ")
    if not keyword:
        print("[!] Anahtar kelime boş olamaz.")
        return
    
    print(f"[*] '{keyword}' için arama yapılıyor...")
    params = {
        "keywordSearch": keyword,
        "resultsPerPage": 20
    }
    data = fetch_cves(params)
    display_results(data, limit=20)

def search_by_vendor():
    """Üretici ve ürün ismine göre arama yapar."""
    vendor = input("Üretici adı (örnek: microsoft, apache): ")
    product = input("Ürün adı (opsiyonel, boş bırakılabilir): ")
    
    if not vendor:
        print("[!] En az üretici adı gereklidir.")
        return
    
    cpe_name = f"cpe:2.3:*:{vendor}"
    if product:
        cpe_name += f":{product}"
    
    print(f"[*] '{vendor}' ürünleri için arama yapılıyor...")
    params = {
        "cpeName": cpe_name,
        "resultsPerPage": 20
    }
    data = fetch_cves(params)
    display_results(data, limit=20)

def search_by_id():
    """Belirli bir CVE ID'sine göre ayrıntı getirir."""
    cve_id = input("CVE ID (örnek: CVE-2021-44228): ").upper()
    if not cve_id.startswith("CVE-"):
        print("[!] Geçerli bir CVE ID'si girin (CVE- formatında).")
        return
    
    print(f"[*] '{cve_id}' için ayrıntılar getiriliyor...")
    url = f"{NVD_API_URL}?cveId={cve_id}"
    headers = {"User-Agent": "Termux-CVE-Panel/1.0"}
    try:
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        data = response.json()
        
        if data.get("vulnerabilitiesCount", 0) == 0:
            print(f"[!] '{cve_id}' bulunamadı.")
            return
            
        display_results(data, limit=1)
        
        # Ek detaylar: referanslar
        vulns = data.get("vulnerabilities", [])
        if vulns:
            references = vulns[0].get("cve", {}).get("references", [])
            if references:
                print("=== Referans Linkler ===")
                for ref in references[:5]:  # İlk 5 referans
                    print(f"  - {ref.get('url')}")
                print()
    except Exception as e:
        print(f"[!] Hata: {e}")

def search_critical_recent():
    """Son 7 gündeki kritik ve yüksek öneme sahip CVE'leri getirir."""
    print("[*] Son 7 günün kritik CVE'leri getiriliyor...")
    end_date = datetime.now().strftime("%Y-%m-%dT%H:%M:%S.000")
    start_date = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%dT%H:%M:%S.000")
    
    params = {
        "pubStartDate": start_date,
        "pubEndDate": end_date,
        "severity": "CRITICAL",  # Sadece kritik
        "resultsPerPage": 15
    }
    data = fetch_cves(params)
    display_results(data, limit=15)

def main_menu():
    """Ana menüyü gösterir ve kullanıcı seçimini yönetir."""
    while True:
        print("\n" + "="*50)
        print("   🔍 CVE SORGULAMA PANELİ (NVD API)")
        print("="*50)
        print("1. Anahtar kelime ile ara")
        print("2. Üretici/ürün adı ile ara")
        print("3. CVE ID'si ile detay sorgula")
        print("4. Son 7 günün kritik CVE'leri")
        print("5. Çıkış")
        print("-"*50)
        
        choice = input("Seçiminiz (1-5): ").strip()
        
        if choice == "1":
            search_by_keyword()
        elif choice == "2":
            search_by_vendor()
        elif choice == "3":
            search_by_id()
        elif choice == "4":
            search_critical_recent()
        elif choice == "5":
            print("[*] Çıkış yapılıyor, güvende kalın!")
            sys.exit(0)
        else:
            print("[!] Geçersiz seçim. Tekrar deneyin.")

if __name__ == "__main__":
    main_menu()