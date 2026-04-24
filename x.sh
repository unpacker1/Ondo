#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║   NEXUS WORLD INTELLIGENCE v1.0 - by PHANTOM FRAMEWORK      ║
# ║   3D Earth | Live Radar | Ships | Flights | OSINT Dashboard  ║
# ╚══════════════════════════════════════════════════════════════╝

PORT=8888
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HTML_FILE="/tmp/nexus_world.html"
PY_SERVER="/tmp/nexus_server.py"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

clear
echo -e "${PURPLE}${BOLD}"
echo "  ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗"
echo "  ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝"
echo "  ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗"
echo "  ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║"
echo "  ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║"
echo "  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
echo -e "${CYAN}        WORLD INTELLIGENCE PLATFORM v1.0${NC}"
echo -e "${YELLOW}   3D Earth | Ships | Flights | Radar | OSINT${NC}"
echo ""

# Check dependencies
check_dep() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${YELLOW}[*] Installing $1...${NC}"
    pkg install -y "$2" 2>/dev/null || pip install "$3" 2>/dev/null
  fi
}
check_dep python python python3
check_dep curl curl curl

echo -e "${GREEN}[+] Building NEXUS Intelligence Platform...${NC}"

# ─── PYTHON BACKEND SERVER ────────────────────────────────────────────────────
cat > "$PY_SERVER" << 'PYEOF'
import http.server
import socketserver
import json
import urllib.request
import urllib.parse
import os
import time
import math
import random
import threading
import ssl

PORT = 8888
HTML_FILE = "/tmp/nexus_world.html"

ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verify_mode = ssl.CERT_NONE

def fetch_url(url, timeout=8):
    try:
        req = urllib.request.Request(url, headers={
            'User-Agent': 'Mozilla/5.0 (Android; Mobile) AppleWebKit/537.36',
            'Accept': 'application/json,*/*'
        })
        with urllib.request.urlopen(req, timeout=timeout, context=ssl_ctx) as r:
            return json.loads(r.read().decode('utf-8', errors='ignore'))
    except:
        return None

def fetch_text(url, timeout=8):
    try:
        req = urllib.request.Request(url, headers={
            'User-Agent': 'Mozilla/5.0 (Android; Mobile) AppleWebKit/537.36'
        })
        with urllib.request.urlopen(req, timeout=timeout, context=ssl_ctx) as r:
            return r.read().decode('utf-8', errors='ignore')
    except:
        return None

def get_iss_position():
    data = fetch_url("http://api.open-notify.org/iss-now.json")
    if data and data.get('iss_position'):
        pos = data['iss_position']
        return {
            "lat": float(pos['latitude']),
            "lon": float(pos['longitude']),
            "alt": 408,
            "speed": 27600,
            "name": "ISS",
            "type": "iss",
            "id": "ISS-1"
        }
    return None

def get_iss_crew():
    data = fetch_url("http://api.open-notify.org/astros.json")
    if data:
        return data.get('people', [])
    return []

def get_earthquakes():
    data = fetch_url("https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_day.geojson", timeout=10)
    quakes = []
    if data and data.get('features'):
        for f in data['features'][:30]:
            props = f.get('properties', {})
            coords = f.get('geometry', {}).get('coordinates', [0,0,0])
            quakes.append({
                "lat": coords[1],
                "lon": coords[0],
                "depth": coords[2],
                "mag": props.get('mag', 0),
                "place": props.get('place', 'Unknown'),
                "time": props.get('time', 0),
                "id": f.get('id', ''),
                "type": "earthquake"
            })
    return quakes

def get_volcanoes():
    return [
        {"name":"Etna","lat":37.748,"lon":15.000,"country":"Italy","status":"Active","elevation":3329},
        {"name":"Stromboli","lat":38.789,"lon":15.213,"country":"Italy","status":"Active","elevation":926},
        {"name":"Krakatau","lat":-6.102,"lon":105.423,"country":"Indonesia","status":"Active","elevation":813},
        {"name":"Merapi","lat":-7.540,"lon":110.446,"country":"Indonesia","status":"Active","elevation":2968},
        {"name":"Kilauea","lat":19.421,"lon":-155.287,"country":"USA","status":"Active","elevation":1222},
        {"name":"Popocatepetl","lat":19.023,"lon":-98.628,"country":"Mexico","status":"Active","elevation":5426},
        {"name":"Sakurajima","lat":31.581,"lon":130.659,"country":"Japan","status":"Active","elevation":1117},
        {"name":"Piton de la Fournaise","lat":-21.244,"lon":55.708,"country":"Reunion","status":"Active","elevation":2632},
        {"name":"Yasur","lat":-19.532,"lon":169.447,"country":"Vanuatu","status":"Active","elevation":361},
        {"name":"Colima","lat":19.514,"lon":-103.620,"country":"Mexico","status":"Active","elevation":3850},
        {"name":"Semeru","lat":-8.108,"lon":112.922,"country":"Indonesia","status":"Active","elevation":3676},
        {"name":"Sinabung","lat":3.170,"lon":98.392,"country":"Indonesia","status":"Active","elevation":2460},
        {"name":"Fuego","lat":14.473,"lon":-90.880,"country":"Guatemala","status":"Active","elevation":3763},
        {"name":"Erta Ale","lat":13.600,"lon":40.670,"country":"Ethiopia","status":"Active","elevation":613},
        {"name":"Nyiragongo","lat":-1.521,"lon":29.251,"country":"DRC","status":"Active","elevation":3470},
    ]

def get_wildfires():
    try:
        txt = fetch_text("https://firms.modaps.eosdis.nasa.gov/api/country/csv/FIRMS_KEY/VIIRS_SNPP_NRT/World/1", timeout=6)
        fires = []
        if txt:
            lines = txt.strip().split('\n')
            for line in lines[1:21]:
                parts = line.split(',')
                if len(parts) >= 3:
                    try:
                        fires.append({
                            "lat": float(parts[0]),
                            "lon": float(parts[1]),
                            "brightness": float(parts[2]) if len(parts) > 2 else 300,
                            "type": "wildfire"
                        })
                    except: pass
        if fires:
            return fires
    except: pass
    # Fallback static known fire-prone areas
    return [
        {"lat":37.5,"lon":-119.5,"brightness":320,"type":"wildfire"},
        {"lat":-33.8,"lon":150.9,"brightness":335,"type":"wildfire"},
        {"lat":60.0,"lon":80.0,"brightness":310,"type":"wildfire"},
        {"lat":3.0,"lon":20.0,"brightness":340,"type":"wildfire"},
        {"lat":-15.0,"lon":-55.0,"brightness":325,"type":"wildfire"},
    ]

def get_weather_stations():
    stations = [
        {"city":"London","lat":51.507,"lon":-0.127,"temp":14,"wind":25,"humidity":72,"pressure":1013},
        {"city":"New York","lat":40.713,"lon":-74.006,"temp":18,"wind":15,"humidity":65,"pressure":1018},
        {"city":"Tokyo","lat":35.689,"lon":139.692,"temp":22,"wind":12,"humidity":68,"pressure":1015},
        {"city":"Sydney","lat":-33.868,"lon":151.209,"temp":25,"wind":20,"humidity":58,"pressure":1012},
        {"city":"Moscow","lat":55.751,"lon":37.618,"temp":8,"wind":18,"humidity":75,"pressure":1008},
        {"city":"Dubai","lat":25.204,"lon":55.270,"temp":38,"wind":10,"humidity":45,"pressure":1007},
        {"city":"Mumbai","lat":19.076,"lon":72.877,"temp":32,"wind":22,"humidity":80,"pressure":1005},
        {"city":"Beijing","lat":39.904,"lon":116.407,"temp":20,"wind":14,"humidity":55,"pressure":1016},
        {"city":"Cairo","lat":30.044,"lon":31.235,"temp":35,"wind":8,"humidity":30,"pressure":1010},
        {"city":"São Paulo","lat":-23.550,"lon":-46.633,"temp":28,"wind":16,"humidity":70,"pressure":1011},
        {"city":"Johannesburg","lat":-26.204,"lon":28.047,"temp":20,"wind":19,"humidity":48,"pressure":1014},
        {"city":"Singapore","lat":1.352,"lon":103.820,"temp":30,"wind":11,"humidity":85,"pressure":1009},
    ]
    return stations

def get_internet_exchange_nodes():
    return [
        {"name":"DE-CIX Frankfurt","lat":50.110,"lon":8.682,"traffic_tbps":9.1,"peers":1050,"country":"Germany"},
        {"name":"AMS-IX Amsterdam","lat":52.374,"lon":4.899,"traffic_tbps":8.7,"peers":980,"country":"Netherlands"},
        {"name":"LINX London","lat":51.507,"lon":-0.127,"traffic_tbps":6.4,"peers":870,"country":"UK"},
        {"name":"Equinix NY","lat":40.713,"lon":-74.006,"traffic_tbps":5.2,"peers":760,"country":"USA"},
        {"name":"JPNAP Tokyo","lat":35.689,"lon":139.692,"traffic_tbps":4.8,"peers":620,"country":"Japan"},
        {"name":"SGIX Singapore","lat":1.352,"lon":103.820,"traffic_tbps":3.9,"peers":510,"country":"Singapore"},
        {"name":"MSK-IX Moscow","lat":55.751,"lon":37.618,"traffic_tbps":3.2,"peers":490,"country":"Russia"},
        {"name":"PAIX Palo Alto","lat":37.444,"lon":-122.143,"traffic_tbps":4.1,"peers":580,"country":"USA"},
        {"name":"Netnod Stockholm","lat":59.334,"lon":18.064,"traffic_tbps":2.1,"peers":320,"country":"Sweden"},
        {"name":"HKIX Hong Kong","lat":22.320,"lon":114.170,"traffic_tbps":3.6,"peers":450,"country":"China"},
        {"name":"SIX Seattle","lat":47.607,"lon":-122.332,"traffic_tbps":2.8,"peers":390,"country":"USA"},
        {"name":"Sydney IXP","lat":-33.868,"lon":151.209,"traffic_tbps":1.9,"peers":280,"country":"Australia"},
    ]

def get_undersea_cables():
    return [
        {"name":"SEA-ME-WE 3","points":[[1.3,103.8],[6.9,79.8],[12.7,45.0],[29.9,32.5],[51.5,-0.1]],"capacity":"40 Tbps","year":1999},
        {"name":"FLAG/FALCON","points":[[51.5,-0.1],[30.0,32.5],[25.2,55.3],[22.3,114.2],[35.7,139.7]],"capacity":"10 Tbps","year":2006},
        {"name":"TAT-14","points":[[51.5,-0.1],[40.7,-74.0]],"capacity":"3.2 Tbps","year":2001},
        {"name":"MAREA","points":[[40.4,-3.7],[40.7,-74.0]],"capacity":"200 Tbps","year":2017},
        {"name":"FASTER","points":[[37.7,-122.4],[35.7,139.7],[22.3,114.2]],"capacity":"60 Tbps","year":2016},
        {"name":"JUPITER","points":[[37.7,-122.4],[35.7,139.7],[1.3,103.8]],"capacity":"60 Tbps","year":2020},
        {"name":"PEACE","points":[[51.5,-0.1],[30.0,32.5],[4.0,45.0],[1.3,103.8],[22.3,114.2]],"capacity":"60 Tbps","year":2022},
        {"name":"AAE-1","points":[[43.6,1.4],[30.0,32.5],[25.2,55.3],[22.3,114.2],[1.3,103.8]],"capacity":"40 Tbps","year":2017},
    ]

def get_nuclear_sites():
    return [
        {"name":"Chernobyl","lat":51.389,"lon":30.099,"country":"Ukraine","type":"Disaster Zone","status":"Exclusion Zone","reactors":4},
        {"name":"Fukushima Daiichi","lat":37.423,"lon":141.032,"country":"Japan","type":"Disaster Zone","status":"Decommissioning","reactors":6},
        {"name":"Vogtle","lat":33.143,"lon":-81.762,"country":"USA","type":"Power Plant","status":"Active","reactors":4},
        {"name":"Cattenom","lat":49.403,"lon":6.218,"country":"France","type":"Power Plant","status":"Active","reactors":4},
        {"name":"Gravelines","lat":51.015,"lon":2.133,"country":"France","type":"Power Plant","status":"Active","reactors":6},
        {"name":"Zaporizhzhia","lat":47.507,"lon":34.584,"country":"Ukraine","type":"Power Plant","status":"Occupied","reactors":6},
        {"name":"Kudankulam","lat":8.171,"lon":77.713,"country":"India","type":"Power Plant","status":"Active","reactors":2},
        {"name":"Tianwan","lat":34.696,"lon":119.452,"country":"China","type":"Power Plant","status":"Active","reactors":6},
        {"name":"Kori","lat":35.318,"lon":129.296,"country":"South Korea","type":"Power Plant","status":"Active","reactors":7},
        {"name":"Kashiwazaki-Kariwa","lat":37.425,"lon":138.601,"country":"Japan","type":"Power Plant","status":"Suspended","reactors":7},
        {"name":"Nevada Test Site","lat":37.100,"lon":-116.049,"country":"USA","type":"Test Site","status":"Historical","reactors":0},
        {"name":"Semipalatinsk","lat":50.105,"lon":78.863,"country":"Kazakhstan","type":"Test Site","status":"Historical","reactors":0},
    ]

def get_military_bases():
    return [
        {"name":"Camp Lemonnier","lat":11.546,"lon":43.159,"country":"Djibouti","force":"US AFRICOM","type":"Naval/Air"},
        {"name":"RAF Menwith Hill","lat":54.004,"lon":-1.692,"country":"UK","force":"NSA/GCHQ","type":"SIGINT"},
        {"name":"Diego Garcia","lat":-7.312,"lon":72.413,"country":"BIOT","force":"US/UK","type":"Naval/Air"},
        {"name":"Ramstein AFB","lat":49.437,"lon":7.600,"country":"Germany","force":"USAF","type":"Air Base"},
        {"name":"Yokota AB","lat":35.748,"lon":139.348,"country":"Japan","force":"USAF","type":"Air Base"},
        {"name":"Thule AB","lat":76.532,"lon":-68.703,"country":"Greenland","force":"USAF","type":"Radar/Space"},
        {"name":"Pine Gap","lat":-23.799,"lon":133.737,"country":"Australia","force":"CIA/ASD","type":"SIGINT/Space"},
        {"name":"Incirlik AB","lat":37.002,"lon":35.426,"country":"Turkey","force":"USAF/NATO","type":"Air Base"},
        {"name":"Guantanamo Bay","lat":19.902,"lon":-75.099,"country":"Cuba","force":"US Navy","type":"Naval"},
        {"name":"Al Udeid AB","lat":25.117,"lon":51.315,"country":"Qatar","force":"USAF/CENTCOM","type":"Air Base"},
        {"name":"Lajes Field","lat":38.762,"lon":-27.090,"country":"Azores","force":"USAF/Portugal","type":"Air Base"},
        {"name":"Soto Cano AB","lat":14.381,"lon":-87.621,"country":"Honduras","force":"JSOTF-N","type":"Air Base"},
    ]

def get_conflict_zones():
    return [
        {"name":"Ukraine-Russia Front","lat":48.500,"lon":35.000,"intensity":"high","type":"Armed Conflict","status":"Active","since":2022},
        {"name":"Gaza Strip","lat":31.354,"lon":34.308,"intensity":"critical","type":"Armed Conflict","status":"Active","since":2023},
        {"name":"Sudan","lat":15.500,"lon":32.500,"intensity":"high","type":"Civil War","status":"Active","since":2023},
        {"name":"Myanmar","lat":19.745,"lon":96.129,"intensity":"high","type":"Civil War","status":"Active","since":2021},
        {"name":"Somalia","lat":5.152,"lon":46.199,"intensity":"medium","type":"Insurgency","status":"Active","since":1991},
        {"name":"Sahel Region","lat":14.500,"lon":2.000,"intensity":"high","type":"Insurgency","status":"Active","since":2012},
        {"name":"Yemen","lat":15.554,"lon":48.516,"intensity":"medium","type":"Armed Conflict","status":"Ceasefire","since":2015},
        {"name":"DRC East","lat":-2.000,"lon":28.500,"intensity":"high","type":"Armed Conflict","status":"Active","since":1996},
        {"name":"Nagorno-Karabakh","lat":40.000,"lon":46.500,"intensity":"low","type":"Post-Conflict","status":"Resolved","since":2020},
        {"name":"Kosovo","lat":42.600,"lon":20.900,"intensity":"low","type":"Tension","status":"Monitored","since":1998},
    ]

def get_shipping_lanes():
    return [
        {"name":"Strait of Malacca","lat":2.5,"lon":102.0,"traffic_daily":260,"type":"Chokepoint","importance":"Critical"},
        {"name":"Strait of Hormuz","lat":26.5,"lon":56.5,"traffic_daily":21,"type":"Oil Chokepoint","importance":"Critical"},
        {"name":"Suez Canal","lat":30.7,"lon":32.3,"traffic_daily":51,"type":"Canal","importance":"Critical"},
        {"name":"Panama Canal","lat":9.0,"lon":-79.5,"traffic_daily":38,"type":"Canal","importance":"High"},
        {"name":"Bab el-Mandeb","lat":12.5,"lon":43.3,"traffic_daily":25,"type":"Chokepoint","importance":"Critical"},
        {"name":"Dover Strait","lat":51.0,"lon":1.5,"traffic_daily":500,"type":"Chokepoint","importance":"High"},
        {"name":"Gibraltar","lat":35.9,"lon":-5.6,"traffic_daily":110,"type":"Chokepoint","importance":"High"},
        {"name":"Turkish Straits","lat":41.1,"lon":29.0,"traffic_daily":48,"type":"Chokepoint","importance":"High"},
        {"name":"Cape of Good Hope","lat":-34.4,"lon":18.5,"traffic_daily":32,"type":"Cape","importance":"Medium"},
        {"name":"Cape Horn","lat":-55.9,"lon":-67.3,"traffic_daily":12,"type":"Cape","importance":"Medium"},
    ]

def get_cyber_attacks():
    sources = [
        {"country":"China","lat":35.8617,"lon":104.1954,"attacks":random.randint(800,2000)},
        {"country":"Russia","lat":61.5240,"lon":105.3188,"attacks":random.randint(600,1500)},
        {"country":"USA","lat":37.0902,"lon":-95.7129,"attacks":random.randint(400,1200)},
        {"country":"Iran","lat":32.4279,"lon":53.6880,"attacks":random.randint(300,900)},
        {"country":"North Korea","lat":40.3399,"lon":127.5101,"attacks":random.randint(200,700)},
        {"country":"Brazil","lat":-14.2350,"lon":-51.9253,"attacks":random.randint(150,500)},
        {"country":"India","lat":20.5937,"lon":78.9629,"attacks":random.randint(200,600)},
        {"country":"Germany","lat":51.1657,"lon":10.4515,"attacks":random.randint(100,400)},
    ]
    targets = [
        {"country":"USA","lat":37.0902,"lon":-95.7129},
        {"country":"Germany","lat":51.1657,"lon":10.4515},
        {"country":"UK","lat":55.3781,"lon":-3.4360},
        {"country":"Japan","lat":36.2048,"lon":138.2529},
        {"country":"Ukraine","lat":48.3794,"lon":31.1656},
        {"country":"Taiwan","lat":23.6978,"lon":120.9605},
        {"country":"South Korea","lat":35.9078,"lon":127.7669},
        {"country":"Australia","lat":-25.2744,"lon":133.7751},
    ]
    attacks = []
    for s in sources:
        for t in random.sample(targets, random.randint(2,4)):
            if s['country'] != t['country']:
                attacks.append({
                    "src_lat": s['lat'], "src_lon": s['lon'], "src_country": s['country'],
                    "dst_lat": t['lat'], "dst_lon": t['lon'], "dst_country": t['country'],
                    "count": random.randint(50, 500),
                    "type": random.choice(["DDoS","Malware","Phishing","APT","Ransomware","Intrusion"])
                })
    return attacks

def get_space_objects():
    objects = []
    # ISS
    iss = get_iss_position()
    if iss:
        objects.append(iss)
    # Satellites (simulated orbital positions)
    sats = [
        {"name":"Hubble","alt":540,"inc":28.5,"period":95},
        {"name":"Sentinel-1A","alt":693,"inc":98.2,"period":99},
        {"name":"Landsat-9","alt":705,"inc":98.2,"period":99},
        {"name":"GOES-16","alt":35786,"inc":0.1,"period":1436},
        {"name":"GPS-IIR-14","alt":20200,"inc":55,"period":718},
        {"name":"Starlink-1","alt":550,"inc":53,"period":95},
        {"name":"Starlink-2","alt":550,"inc":53,"period":95},
        {"name":"NOAA-18","alt":854,"inc":99,"period":102},
        {"name":"Terra","alt":705,"inc":98.2,"period":99},
        {"name":"Aqua","alt":705,"inc":98.2,"period":99},
    ]
    t = time.time()
    for i, s in enumerate(sats):
        angle = (t / (s['period']*60) + i*0.3) * 2 * math.pi
        lat = math.sin(angle) * s['inc']
        lon = (math.degrees(angle) % 360) - 180
        objects.append({
            "name": s['name'], "lat": lat, "lon": lon,
            "alt": s['alt'], "type": "satellite",
            "id": "SAT-" + str(i+2)
        })
    return objects

def generate_live_ships():
    # Simulated ship traffic in major shipping lanes
    ships = []
    regions = [
        # Strait of Malacca
        {"lat":2.5,"lon":102.0,"spread":3,"count":25,"type":"Container"},
        # Persian Gulf / Hormuz
        {"lat":26.0,"lon":56.0,"spread":2,"count":20,"type":"Tanker"},
        # Mediterranean
        {"lat":36.0,"lon":14.0,"spread":4,"count":22,"type":"Container"},
        # English Channel
        {"lat":51.0,"lon":1.5,"spread":1.5,"count":30,"type":"Container"},
        # East China Sea
        {"lat":30.0,"lon":125.0,"spread":3,"count":28,"type":"Container"},
        # Bay of Bengal
        {"lat":13.0,"lon":85.0,"spread":4,"count":18,"type":"Bulk Carrier"},
        # Gulf of Mexico
        {"lat":24.0,"lon":-88.0,"spread":3,"count":15,"type":"Tanker"},
        # North Sea
        {"lat":57.0,"lon":3.0,"spread":3,"count":20,"type":"Container"},
        # Red Sea
        {"lat":18.0,"lon":38.0,"spread":2,"count":12,"type":"Container"},
        # West Africa
        {"lat":4.0,"lon":2.0,"spread":3,"count":14,"type":"Tanker"},
    ]
    ship_names = ["EVER GIVEN","MAERSK ESSEX","MSC GAIA","COSCO STAR","APL PARIS","NYK ATLAS",
                  "OLYMPIC GLORY","PERSIAN QUEEN","ATLANTIC CARRIER","NORDIC CHIEF","PACIFIC TRADER",
                  "OCEAN EXPLORER","CROWN JEWEL","DIAMOND EXPRESS","GLOBAL FORTUNE","TITAN WAVE",
                  "STEEL WIND","MERCURY STAR","NEPTUNE LORD","AURORA BOREALIS","CORAL QUEEN",
                  "ARCTIC VOYAGER","DESERT WIND","JADE EMPEROR","SILVER MOON","GOLDEN ARROW"]
    flags = ["Panama","Marshall Islands","Liberia","Hong Kong","Singapore","Bahamas","Malta","Cyprus"]
    sid = 1
    for r in regions:
        for i in range(r['count']):
            lat = r['lat'] + (random.random()-0.5)*r['spread']*2
            lon = r['lon'] + (random.random()-0.5)*r['spread']*2
            ships.append({
                "id": "SHP-" + str(sid).zfill(4),
                "name": random.choice(ship_names) + "-" + str(random.randint(1,99)),
                "lat": lat, "lon": lon,
                "speed": round(random.uniform(8,22),1),
                "heading": random.randint(0,359),
                "type": r['type'],
                "flag": random.choice(flags),
                "mmsi": random.randint(200000000,999999999),
                "imo": random.randint(1000000,9999999),
                "length": random.randint(150,400),
                "destination": random.choice(["Singapore","Rotterdam","Shanghai","Houston","Dubai"])
            })
            sid += 1
    return ships

def generate_live_flights():
    flights = []
    routes = [
        {"src":{"city":"New York","lat":40.6,"lon":-73.8},"dst":{"city":"London","lat":51.5,"lon":-0.1}},
        {"src":{"city":"London","lat":51.5,"lon":-0.1},"dst":{"city":"Dubai","lat":25.2,"lon":55.4}},
        {"src":{"city":"Dubai","lat":25.2,"lon":55.4},"dst":{"city":"Singapore","lat":1.4,"lon":103.9}},
        {"src":{"city":"Tokyo","lat":35.7,"lon":140.4},"dst":{"city":"Los Angeles","lat":33.9,"lon":-118.4}},
        {"src":{"city":"Paris","lat":48.9,"lon":2.5},"dst":{"city":"New York","lat":40.6,"lon":-73.8}},
        {"src":{"city":"Singapore","lat":1.4,"lon":103.9},"dst":{"city":"Sydney","lat":-33.9,"lon":151.2}},
        {"src":{"city":"Frankfurt","lat":50.0,"lon":8.6},"dst":{"city":"Beijing","lat":40.1,"lon":116.6}},
        {"src":{"city":"Chicago","lat":41.9,"lon":-87.9},"dst":{"city":"London","lat":51.5,"lon":-0.1}},
        {"src":{"city":"Mumbai","lat":19.1,"lon":72.9},"dst":{"city":"London","lat":51.5,"lon":-0.1}},
        {"src":{"city":"São Paulo","lat":-23.4,"lon":-46.5},"dst":{"city":"Lisbon","lat":38.8,"lon":-9.1}},
        {"src":{"city":"Moscow","lat":55.9,"lon":37.3},"dst":{"city":"Beijing","lat":40.1,"lon":116.6}},
        {"src":{"city":"Bangkok","lat":13.7,"lon":100.7},"dst":{"city":"Tokyo","lat":35.7,"lon":140.4}},
        {"src":{"city":"Cairo","lat":30.1,"lon":31.4},"dst":{"city":"Dubai","lat":25.2,"lon":55.4}},
        {"src":{"city":"Amsterdam","lat":52.3,"lon":4.8},"dst":{"city":"New York","lat":40.6,"lon":-73.8}},
        {"src":{"city":"Johannesburg","lat":-26.1,"lon":28.2},"dst":{"city":"London","lat":51.5,"lon":-0.1}},
    ]
    airlines = ["AA","BA","EK","SQ","LH","AF","QR","CX","NH","UA","DL","TK","KE","QF","ET"]
    fid = 1
    for route in routes:
        for i in range(random.randint(3,8)):
            t = random.random()
            lat = route['src']['lat'] + (route['dst']['lat'] - route['src']['lat']) * t
            lon = route['src']['lon'] + (route['dst']['lon'] - route['src']['lon']) * t
            al = random.choice(airlines)
            flights.append({
                "id": "FLT-" + str(fid).zfill(4),
                "callsign": al + str(random.randint(100,999)),
                "airline": al,
                "lat": lat, "lon": lon,
                "altitude": random.randint(28000,42000),
                "speed": random.randint(480,620),
                "heading": random.randint(0,359),
                "from": route['src']['city'],
                "to": route['dst']['city'],
                "aircraft": random.choice(["B777","A380","B787","A350","B737","A320"]),
                "progress": round(t*100,1)
            })
            fid += 1
    return flights

class NexusHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass

    def send_json(self, data):
        body = json.dumps(data).encode()
        self.send_response(200)
        self.send_header('Content-Type','application/json')
        self.send_header('Access-Control-Allow-Origin','*')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = self.path.split('?')[0]
        if path == '/':
            try:
                with open(HTML_FILE,'rb') as f:
                    content = f.read()
                self.send_response(200)
                self.send_header('Content-Type','text/html; charset=utf-8')
                self.send_header('Content-Length', str(len(content)))
                self.end_headers()
                self.wfile.write(content)
            except Exception as e:
                self.send_error(500, str(e))

        elif path == '/api/iss':
            self.send_json(get_iss_position())
        elif path == '/api/crew':
            self.send_json(get_iss_crew())
        elif path == '/api/earthquakes':
            self.send_json(get_earthquakes())
        elif path == '/api/volcanoes':
            self.send_json(get_volcanoes())
        elif path == '/api/wildfires':
            self.send_json(get_wildfires())
        elif path == '/api/weather':
            self.send_json(get_weather_stations())
        elif path == '/api/ixp':
            self.send_json(get_internet_exchange_nodes())
        elif path == '/api/cables':
            self.send_json(get_undersea_cables())
        elif path == '/api/nuclear':
            self.send_json(get_nuclear_sites())
        elif path == '/api/military':
            self.send_json(get_military_bases())
        elif path == '/api/conflicts':
            self.send_json(get_conflict_zones())
        elif path == '/api/shipping':
            self.send_json(get_shipping_lanes())
        elif path == '/api/cyber':
            self.send_json(get_cyber_attacks())
        elif path == '/api/space':
            self.send_json(get_space_objects())
        elif path == '/api/ships':
            self.send_json(generate_live_ships())
        elif path == '/api/flights':
            self.send_json(generate_live_flights())
        elif path == '/api/all':
            self.send_json({
                "iss": get_iss_position(),
                "earthquakes": get_earthquakes(),
                "volcanoes": get_volcanoes(),
                "weather": get_weather_stations(),
                "nuclear": get_nuclear_sites(),
                "military": get_military_bases(),
                "conflicts": get_conflict_zones(),
                "shipping": get_shipping_lanes(),
                "ixp": get_internet_exchange_nodes(),
            })
        else:
            self.send_error(404)

print(f"[NEXUS] Python backend starting on port {PORT}")
with socketserver.TCPServer(("", PORT), NexusHandler) as httpd:
    httpd.serve_forever()
PYEOF

echo -e "${GREEN}[+] Backend server built.${NC}"
echo -e "${GREEN}[+] Building 3D World Intelligence Interface...${NC}"

# ─── MAIN HTML INTERFACE ──────────────────────────────────────────────────────
python3 - << 'HTMLGEN'
import os

lines = []
A = lines.append

A('<!DOCTYPE html>')
A('<html lang="en">')
A('<head>')
A('<meta charset="UTF-8">')
A('<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">')
A('<title>NEXUS WORLD INTELLIGENCE</title>')
A('<style>')
A('@import url("https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;700;900&family=Rajdhani:wght@300;500;700&display=swap");')
A(':root {')
A('  --neon-cyan: #00f5ff;')
A('  --neon-green: #00ff41;')
A('  --neon-red: #ff0033;')
A('  --neon-orange: #ff6600;')
A('  --neon-purple: #bf00ff;')
A('  --neon-yellow: #ffff00;')
A('  --neon-blue: #0088ff;')
A('  --bg-dark: #010409;')
A('  --bg-panel: rgba(0,10,20,0.92);')
A('  --border-glow: rgba(0,245,255,0.3);')
A('  --text-dim: rgba(0,245,255,0.5);')
A('}')
A('* { margin:0; padding:0; box-sizing:border-box; }')
A('html,body { width:100%; height:100%; overflow:hidden; background:#000; font-family:"Share Tech Mono",monospace; color:var(--neon-cyan); }')
A('#globe-container { position:fixed; top:0; left:0; width:100%; height:100%; z-index:1; }')
A('#globe-canvas { width:100%; height:100%; display:block; }')
A('.panel { position:fixed; z-index:10; background:var(--bg-panel); border:1px solid var(--border-glow); backdrop-filter:blur(8px); -webkit-backdrop-filter:blur(8px); }')
A('.panel-header { padding:8px 12px; background:rgba(0,245,255,0.08); border-bottom:1px solid var(--border-glow); font-family:"Orbitron",sans-serif; font-size:9px; font-weight:700; letter-spacing:3px; text-transform:uppercase; color:var(--neon-cyan); display:flex; justify-content:space-between; align-items:center; }')

# TOP BAR
A('#topbar { top:0; left:0; right:0; height:48px; border-top:none; border-left:none; border-right:none; border-bottom:2px solid var(--neon-cyan); display:flex; align-items:center; padding:0 12px; gap:10px; z-index:20; }')
A('#topbar .logo { font-family:"Orbitron",sans-serif; font-size:14px; font-weight:900; color:var(--neon-cyan); letter-spacing:4px; text-shadow:0 0 20px var(--neon-cyan),0 0 40px rgba(0,245,255,0.4); white-space:nowrap; }')
A('#topbar .logo span { color:var(--neon-red); }')
A('.topstat { font-size:9px; color:var(--text-dim); border-left:1px solid var(--border-glow); padding-left:10px; white-space:nowrap; }')
A('.topstat strong { color:var(--neon-green); display:block; font-size:12px; }')
A('#live-clock { font-family:"Orbitron",sans-serif; font-size:11px; color:var(--neon-yellow); letter-spacing:2px; margin-left:auto; }')
A('#alert-ticker { flex:1; overflow:hidden; max-width:400px; }')
A('#alert-ticker .ticker-inner { white-space:nowrap; animation:ticker 30s linear infinite; font-size:9px; color:var(--neon-orange); }')
A('@keyframes ticker { 0%{transform:translateX(100%)} 100%{transform:translateX(-100%)} }')

# LAYER CONTROL
A('#layer-panel { top:58px; left:8px; width:170px; max-height:calc(100vh - 70px); overflow-y:auto; }')
A('.layer-item { display:flex; align-items:center; padding:6px 12px; cursor:pointer; border-bottom:1px solid rgba(0,245,255,0.06); transition:background 0.2s; }')
A('.layer-item:hover { background:rgba(0,245,255,0.08); }')
A('.layer-item input[type=checkbox] { display:none; }')
A('.layer-dot { width:8px; height:8px; border-radius:50%; margin-right:8px; flex-shrink:0; }')
A('.layer-label { font-size:9px; letter-spacing:1px; text-transform:uppercase; }')
A('.layer-count { margin-left:auto; font-size:8px; color:var(--text-dim); }')
A('.layer-active .layer-label { color:var(--neon-cyan); }')
A('.layer-inactive .layer-label { color:rgba(0,245,255,0.3); }')

# INFO PANEL (RIGHT)
A('#info-panel { top:58px; right:8px; width:230px; max-height:calc(100vh - 70px); overflow-y:auto; }')
A('.info-section { padding:8px 12px; border-bottom:1px solid rgba(0,245,255,0.08); }')
A('.info-title { font-size:8px; letter-spacing:2px; color:var(--text-dim); text-transform:uppercase; margin-bottom:4px; }')
A('.info-value { font-size:11px; color:var(--neon-green); }')
A('.info-row { display:flex; justify-content:space-between; margin:2px 0; font-size:9px; }')
A('.info-row .k { color:var(--text-dim); }')
A('.info-row .v { color:var(--neon-cyan); }')
A('.stat-grid { display:grid; grid-template-columns:1fr 1fr; gap:4px; margin-top:4px; }')
A('.stat-box { background:rgba(0,245,255,0.04); border:1px solid rgba(0,245,255,0.1); padding:4px 6px; text-align:center; }')
A('.stat-box .sv { font-size:14px; font-family:"Orbitron",sans-serif; font-weight:700; }')
A('.stat-box .sk { font-size:7px; color:var(--text-dim); }')
A('.bar-wrap { background:rgba(0,0,0,0.5); height:4px; border-radius:2px; margin:2px 0; overflow:hidden; }')
A('.bar-fill { height:100%; border-radius:2px; transition:width 1s; }')

# DETAIL POPUP
A('#detail-popup { bottom:80px; left:50%; transform:translateX(-50%); width:340px; max-height:280px; overflow-y:auto; display:none; z-index:30; border-color:var(--neon-cyan); box-shadow:0 0 30px rgba(0,245,255,0.3),0 0 60px rgba(0,245,255,0.1); }')
A('#detail-popup.show { display:block; animation:popIn 0.3s ease; }')
A('@keyframes popIn { from{opacity:0;transform:translateX(-50%) scale(0.9)} to{opacity:1;transform:translateX(-50%) scale(1)} }')
A('.detail-content { padding:10px 12px; }')
A('.detail-content h3 { font-family:"Orbitron",sans-serif; font-size:11px; color:var(--neon-cyan); margin-bottom:6px; border-bottom:1px solid var(--border-glow); padding-bottom:4px; }')
A('.detail-content .d-row { display:flex; justify-content:space-between; margin:3px 0; font-size:9px; }')
A('.detail-content .d-key { color:var(--text-dim); }')
A('.detail-content .d-val { color:var(--neon-green); text-align:right; max-width:180px; word-break:break-word; }')

# BOTTOM BAR
A('#bottombar { bottom:0; left:0; right:0; height:36px; border-bottom:none; border-left:none; border-right:none; border-top:1px solid var(--border-glow); display:flex; align-items:center; padding:0 12px; gap:12px; z-index:20; font-size:8px; }')
A('.coord-display { color:var(--neon-yellow); letter-spacing:1px; }')
A('#mode-btns { display:flex; gap:4px; }')
A('.mode-btn { padding:3px 8px; border:1px solid var(--border-glow); background:transparent; color:var(--text-dim); font-family:"Share Tech Mono",monospace; font-size:8px; cursor:pointer; letter-spacing:1px; text-transform:uppercase; transition:all 0.2s; }')
A('.mode-btn:hover,.mode-btn.active { background:rgba(0,245,255,0.15); color:var(--neon-cyan); border-color:var(--neon-cyan); box-shadow:0 0 8px rgba(0,245,255,0.2); }')
A('#status-bar { margin-left:auto; display:flex; gap:12px; font-size:8px; color:var(--text-dim); }')
A('.status-dot { display:inline-block; width:5px; height:5px; border-radius:50%; margin-right:4px; animation:blink 1.5s infinite; }')
A('@keyframes blink { 0%,100%{opacity:1} 50%{opacity:0.2} }')

# MINIMAP
A('#minimap { bottom:45px; right:8px; width:150px; height:85px; z-index:15; }')
A('#minimap canvas { width:100%; height:100%; }')

# SCROLLBAR
A('::-webkit-scrollbar { width:3px; }')
A('::-webkit-scrollbar-track { background:transparent; }')
A('::-webkit-scrollbar-thumb { background:var(--border-glow); border-radius:2px; }')

# PULSE ANIMATIONS
A('.pulse-red { animation:pulseRed 1.5s infinite; }')
A('.pulse-green { animation:pulseGreen 2s infinite; }')
A('@keyframes pulseRed { 0%,100%{box-shadow:0 0 4px var(--neon-red)} 50%{box-shadow:0 0 12px var(--neon-red),0 0 24px rgba(255,0,51,0.4)} }')
A('@keyframes pulseGreen { 0%,100%{box-shadow:0 0 4px var(--neon-green)} 50%{box-shadow:0 0 12px var(--neon-green)} }')

# TAG
A('.tag { display:inline-block; padding:1px 5px; border-radius:2px; font-size:7px; letter-spacing:1px; font-weight:700; text-transform:uppercase; margin:1px; }')
A('.tag-red { background:rgba(255,0,51,0.2); color:var(--neon-red); border:1px solid var(--neon-red); }')
A('.tag-green { background:rgba(0,255,65,0.1); color:var(--neon-green); border:1px solid rgba(0,255,65,0.4); }')
A('.tag-yellow { background:rgba(255,255,0,0.1); color:var(--neon-yellow); border:1px solid rgba(255,255,0,0.4); }')
A('.tag-cyan { background:rgba(0,245,255,0.1); color:var(--neon-cyan); border:1px solid var(--border-glow); }')
A('.tag-orange { background:rgba(255,102,0,0.15); color:var(--neon-orange); border:1px solid rgba(255,102,0,0.4); }')
A('.tag-purple { background:rgba(191,0,255,0.1); color:var(--neon-purple); border:1px solid rgba(191,0,255,0.4); }')

# Search
A('#search-box { position:fixed; top:58px; left:50%; transform:translateX(-50%); z-index:25; display:none; }')
A('#search-box input { background:rgba(0,10,20,0.95); border:1px solid var(--neon-cyan); color:var(--neon-cyan); font-family:"Share Tech Mono",monospace; font-size:11px; padding:6px 12px; width:280px; outline:none; letter-spacing:1px; }')
A('#search-box input::placeholder { color:var(--text-dim); }')

A('</style>')
A('</head>')
A('<body>')

# TOP BAR
A('<div id="topbar" class="panel">')
A('<div class="logo">NE<span>X</span>US <span style="font-size:10px;color:var(--text-dim);">WORLD INTELLIGENCE</span></div>')
A('<div class="topstat"><strong id="ts-ships">...</strong>SHIPS</div>')
A('<div class="topstat"><strong id="ts-flights">...</strong>FLIGHTS</div>')
A('<div class="topstat"><strong id="ts-eq">...</strong>QUAKES</div>')
A('<div class="topstat"><strong id="ts-threats">...</strong>THREATS</div>')
A('<div id="alert-ticker"><div class="ticker-inner" id="ticker-text">NEXUS WORLD INTELLIGENCE PLATFORM // LOADING LIVE DATA FEEDS...</div></div>')
A('<div id="live-clock">00:00:00 UTC</div>')
A('</div>')

# LAYER PANEL
A('<div id="layer-panel" class="panel">')
A('<div class="panel-header">LAYER CONTROL <span style="color:var(--neon-green)">●</span></div>')
layers = [
    ('ships','#00ff41','SHIPS','525'),
    ('flights','#00f5ff','FLIGHTS','247'),
    ('earthquakes','#ff6600','EARTHQUAKES',''),
    ('volcanoes','#ff0033','VOLCANOES','15'),
    ('wildfires','#ff4400','WILDFIRES',''),
    ('iss','#ffffff','ISS / SPACE',''),
    ('satellites','#8888ff','SATELLITES',''),
    ('weather','#00aaff','WEATHER','12'),
    ('military','#ff0033','MILITARY BASES','12'),
    ('nuclear','#ffff00','NUCLEAR SITES','12'),
    ('conflicts','#ff3300','CONFLICT ZONES','10'),
    ('cables','#ff00ff','UNDERSEA CABLES','8'),
    ('ixp','#00ffaa','INTERNET NODES','12'),
    ('cyber','#ff0088','CYBER ATTACKS',''),
    ('shipping','#00ccff','SHIP LANES','10'),
]
for lid, color, label, count in layers:
    A(f'<div class="layer-item layer-active" id="lyr-{lid}" onclick="toggleLayer(\'{lid}\')">')
    A(f'<input type="checkbox" id="chk-{lid}" checked>')
    A(f'<div class="layer-dot" style="background:{color};box-shadow:0 0 6px {color};"></div>')
    A(f'<div class="layer-label">{label}</div>')
    if count:
        A(f'<div class="layer-count" id="cnt-{lid}">{count}</div>')
    else:
        A(f'<div class="layer-count" id="cnt-{lid}"></div>')
    A('</div>')
A('</div>')

# INFO PANEL (RIGHT)
A('<div id="info-panel" class="panel">')
A('<div class="panel-header">INTELLIGENCE FEED</div>')
# ISS Section
A('<div class="info-section">')
A('<div class="info-title">◈ ISS POSITION</div>')
A('<div class="info-row"><span class="k">LAT</span><span class="v" id="iss-lat">--°</span></div>')
A('<div class="info-row"><span class="k">LON</span><span class="v" id="iss-lon">--°</span></div>')
A('<div class="info-row"><span class="k">ALT</span><span class="v">408 km</span></div>')
A('<div class="info-row"><span class="k">SPEED</span><span class="v">27,600 km/h</span></div>')
A('<div class="info-row"><span class="k">CREW</span><span class="v" id="iss-crew">--</span></div>')
A('</div>')
# Earthquake
A('<div class="info-section">')
A('<div class="info-title">◈ LATEST EARTHQUAKES</div>')
A('<div id="eq-list"></div>')
A('</div>')
# Cyber
A('<div class="info-section">')
A('<div class="info-title">◈ CYBER THREAT MAP</div>')
A('<div class="stat-grid">')
A('<div class="stat-box"><div class="sv" id="cy-total" style="color:var(--neon-red)">0</div><div class="sk">ATTACKS/MIN</div></div>')
A('<div class="stat-box"><div class="sv" id="cy-src" style="color:var(--neon-orange)">0</div><div class="sk">SOURCE IPS</div></div>')
A('</div>')
A('<div id="cy-top" style="margin-top:4px;"></div>')
A('</div>')
# Ships/Flights stats
A('<div class="info-section">')
A('<div class="info-title">◈ MARITIME TRAFFIC</div>')
A('<div class="info-row"><span class="k">CONTAINER</span><span class="v" id="ship-container">--</span></div>')
A('<div class="info-row"><span class="k">TANKER</span><span class="v" id="ship-tanker">--</span></div>')
A('<div class="info-row"><span class="k">BULK</span><span class="v" id="ship-bulk">--</span></div>')
A('</div>')
# Space weather
A('<div class="info-section">')
A('<div class="info-title">◈ SPACE WEATHER</div>')
A('<div class="info-row"><span class="k">KP INDEX</span><span class="v" id="kp-val">3.2</span></div>')
A('<div class="info-row"><span class="k">SOLAR WIND</span><span class="v" id="sw-val">420 km/s</span></div>')
A('<div class="info-row"><span class="k">X-RAY FLUX</span><span class="v" id="xr-val">B2.1</span></div>')
A('<div class="bar-wrap"><div class="bar-fill" id="kp-bar" style="width:32%;background:var(--neon-yellow);"></div></div>')
A('</div>')
# Network nodes
A('<div class="info-section">')
A('<div class="info-title">◈ INTERNET EXCHANGE</div>')
A('<div id="ixp-list"></div>')
A('</div>')
A('</div>')

# GLOBE CANVAS
A('<div id="globe-container">')
A('<canvas id="globe-canvas"></canvas>')
A('</div>')

# DETAIL POPUP
A('<div id="detail-popup" class="panel">')
A('<div class="panel-header">OBJECT INTELLIGENCE <button onclick="closeDetail()" style="background:none;border:none;color:var(--neon-red);cursor:pointer;font-size:12px;padding:0;">✕</button></div>')
A('<div class="detail-content" id="detail-content"></div>')
A('</div>')

# BOTTOM BAR
A('<div id="bottombar" class="panel">')
A('<div class="coord-display">LAT: <span id="cur-lat">--</span> | LON: <span id="cur-lon">--</span></div>')
A('<div id="mode-btns">')
for mode in ['GLOBE','FLAT','TACTICAL']:
    active = ' active' if mode == 'GLOBE' else ''
    A(f'<button class="mode-btn{active}" onclick="setViewMode(\'{mode}\')">{mode}</button>')
A('</div>')
A('<button class="mode-btn" onclick="toggleSearch()">⌕ SEARCH</button>')
A('<button class="mode-btn" onclick="autoRotate()">↻ ROTATE</button>')
A('<button class="mode-btn" onclick="resetView()">⌂ HOME</button>')
A('<div id="status-bar">')
A('<span><span class="status-dot" style="background:var(--neon-green)"></span>LIVE</span>')
A('<span><span class="status-dot" style="background:var(--neon-cyan)"></span>GPS</span>')
A('<span><span class="status-dot" style="background:var(--neon-yellow)"></span>AIS</span>')
A('<span id="update-time">SYNC: --</span>')
A('</div>')
A('</div>')

# SEARCH
A('<div id="search-box"><input type="text" id="search-input" placeholder="SEARCH TARGET..." oninput="handleSearch(this.value)" /></div>')

# MINIMAP
A('<div id="minimap" class="panel">')
A('<div class="panel-header" style="font-size:7px;padding:4px 8px;">TACTICAL OVERVIEW</div>')
A('<canvas id="minimap-canvas" width="148" height="63"></canvas>')
A('</div>')

# ─── JAVASCRIPT ──────────────────────────────────────────────────────────────
A('<script>')

A('''
// ═══════════════════════════════════════════════════════
// NEXUS WORLD INTELLIGENCE - Core Engine
// ═══════════════════════════════════════════════════════

var canvas = document.getElementById("globe-canvas");
var ctx = canvas.getContext("2d");
var W, H, CX, CY, RADIUS;
var globe_rot_lon = 0, globe_rot_lat = 0;
var target_lon = 0, target_lat = 0;
var zoom = 1.0;
var isDragging = false, dragX = 0, dragY = 0;
var rotSpeed = 0.003;
var autoRotating = true;
var viewMode = "GLOBE";
var selectedObj = null;
var mouseX = 0, mouseY = 0;
var hitTargets = [];
var lastDataTime = 0;

// Data stores
var DATA = {
  ships: [], flights: [], earthquakes: [], volcanoes: [],
  wildfires: [], iss: null, crew: [], satellites: [],
  weather: [], military: [], nuclear: [], conflicts: [],
  cables: [], ixp: [], cyber: [], shipping: []
};

var LAYERS = {
  ships: true, flights: true, earthquakes: true, volcanoes: true,
  wildfires: true, iss: true, satellites: true, weather: true,
  military: true, nuclear: true, conflicts: true, cables: true,
  ixp: true, cyber: true, shipping: true
};

// ── RESIZE ──────────────────────────────────────────────
function resize() {
  W = canvas.width = window.innerWidth;
  H = canvas.height = window.innerHeight;
  CX = W / 2; CY = H / 2;
  RADIUS = Math.min(W, H) * 0.38 * zoom;
}
window.addEventListener("resize", resize);
resize();

// ── PROJECTION ──────────────────────────────────────────
function project(lat, lon) {
  if (viewMode === "FLAT") {
    var x = CX + (lon - globe_rot_lon * (180/Math.PI)) / 180 * (W * 0.45);
    var y = CY - lat / 90 * (H * 0.4);
    return {x: x, y: y, visible: true};
  }
  var phi = (90 - lat) * Math.PI / 180;
  var lam = (lon) * Math.PI / 180;
  var rot_lon = globe_rot_lon;
  var rot_lat = globe_rot_lat;
  var dx = Math.sin(phi) * Math.cos(lam);
  var dy = Math.cos(phi);
  var dz = Math.sin(phi) * Math.sin(lam);
  // Apply rotations
  var x1 = dx * Math.cos(rot_lon) + dz * Math.sin(rot_lon);
  var z1 = -dx * Math.sin(rot_lon) + dz * Math.cos(rot_lon);
  var y1 = dy * Math.cos(rot_lat) - z1 * Math.sin(rot_lat);
  var z2 = dy * Math.sin(rot_lat) + z1 * Math.cos(rot_lat);
  var visible = z2 > -0.05;
  return {
    x: CX + x1 * RADIUS,
    y: CY - y1 * RADIUS,
    z: z2,
    visible: visible
  };
}

// ── GLOBE DRAWING ──────────────────────────────────────
var starField = [];
(function() {
  for (var i = 0; i < 300; i++) {
    starField.push({
      x: Math.random() * 2000 - 1000,
      y: Math.random() * 2000 - 1000,
      r: Math.random() * 1.2,
      a: Math.random()
    });
  }
})();

function drawStars() {
  for (var i = 0; i < starField.length; i++) {
    var s = starField[i];
    var sx = ((s.x + 1000) / 2000) * W;
    var sy = ((s.y + 1000) / 2000) * H;
    ctx.beginPath();
    ctx.arc(sx, sy, s.r, 0, Math.PI * 2);
    ctx.fillStyle = "rgba(255,255,255," + s.a + ")";
    ctx.fill();
  }
}

function drawGlobe() {
  // Earth sphere gradient
  var grad = ctx.createRadialGradient(CX - RADIUS*0.3, CY - RADIUS*0.3, RADIUS*0.05, CX, CY, RADIUS);
  grad.addColorStop(0, "#0a1a2e");
  grad.addColorStop(0.5, "#060d1a");
  grad.addColorStop(1, "#020710");
  ctx.beginPath();
  ctx.arc(CX, CY, RADIUS, 0, Math.PI * 2);
  ctx.fillStyle = grad;
  ctx.fill();

  // Grid lines
  ctx.strokeStyle = "rgba(0,245,255,0.07)";
  ctx.lineWidth = 0.5;
  for (var lat = -80; lat <= 80; lat += 20) {
    ctx.beginPath();
    var first = true;
    for (var lon = -180; lon <= 180; lon += 3) {
      var p = project(lat, lon);
      if (p.visible) {
        if (first) { ctx.moveTo(p.x, p.y); first = false; }
        else ctx.lineTo(p.x, p.y);
      } else first = true;
    }
    ctx.stroke();
  }
  for (var lon2 = -180; lon2 < 180; lon2 += 20) {
    ctx.beginPath();
    var first2 = true;
    for (var lat2 = -90; lat2 <= 90; lat2 += 3) {
      var p2 = project(lat2, lon2);
      if (p2.visible) {
        if (first2) { ctx.moveTo(p2.x, p2.y); first2 = false; }
        else ctx.lineTo(p2.x, p2.y);
      } else first2 = true;
    }
    ctx.stroke();
  }

  // Equator highlight
  ctx.strokeStyle = "rgba(0,245,255,0.18)";
  ctx.lineWidth = 1;
  ctx.beginPath();
  var fe = true;
  for (var lon3 = -180; lon3 <= 180; lon3 += 2) {
    var pe = project(0, lon3);
    if (pe.visible) {
      if (fe) { ctx.moveTo(pe.x, pe.y); fe = false; }
      else ctx.lineTo(pe.x, pe.y);
    } else fe = true;
  }
  ctx.stroke();

  // Tropics
  ctx.strokeStyle = "rgba(255,255,0,0.08)";
  ctx.lineWidth = 0.5;
  for (var trop of [23.5, -23.5, 66.5, -66.5]) {
    ctx.beginPath(); var ft = true;
    for (var lon4 = -180; lon4 <= 180; lon4 += 2) {
      var pt = project(trop, lon4);
      if (pt.visible) { if (ft) { ctx.moveTo(pt.x, pt.y); ft = false; } else ctx.lineTo(pt.x, pt.y); }
      else ft = true;
    }
    ctx.stroke();
  }

  // Atmosphere glow
  var atm = ctx.createRadialGradient(CX, CY, RADIUS*0.95, CX, CY, RADIUS*1.1);
  atm.addColorStop(0, "rgba(0,100,200,0.12)");
  atm.addColorStop(0.5, "rgba(0,200,255,0.06)");
  atm.addColorStop(1, "rgba(0,0,0,0)");
  ctx.beginPath();
  ctx.arc(CX, CY, RADIUS*1.1, 0, Math.PI*2);
  ctx.fillStyle = atm;
  ctx.fill();

  // Globe border glow
  ctx.beginPath();
  ctx.arc(CX, CY, RADIUS, 0, Math.PI * 2);
  ctx.strokeStyle = "rgba(0,245,255,0.35)";
  ctx.lineWidth = 2;
  ctx.stroke();
}

function drawFlatMap() {
  // Flat map background
  ctx.fillStyle = "#030d1a";
  ctx.fillRect(0, 0, W, H);
  // Ocean fill
  var x0 = CX - W*0.45, y0 = CY - H*0.4;
  var mw = W*0.9, mh = H*0.8;
  ctx.fillStyle = "rgba(0,20,50,0.8)";
  ctx.strokeStyle = "rgba(0,245,255,0.3)";
  ctx.lineWidth = 1;
  ctx.fillRect(x0, y0, mw, mh);
  ctx.strokeRect(x0, y0, mw, mh);
  // Grid
  ctx.strokeStyle = "rgba(0,245,255,0.07)";
  ctx.lineWidth = 0.5;
  for (var lat = -80; lat <= 80; lat += 20) {
    var p1 = project(lat, -180), p2 = project(lat, 180);
    ctx.beginPath(); ctx.moveTo(p1.x, p1.y); ctx.lineTo(p2.x, p2.y); ctx.stroke();
  }
  for (var lon = -180; lon <= 180; lon += 30) {
    var pp1 = project(-90, lon), pp2 = project(90, lon);
    ctx.beginPath(); ctx.moveTo(pp1.x, pp1.y); ctx.lineTo(pp2.x, pp2.y); ctx.stroke();
  }
}

// ── UNDERSEA CABLES ─────────────────────────────────────
function drawCables() {
  if (!LAYERS.cables) return;
  for (var i = 0; i < DATA.cables.length; i++) {
    var cable = DATA.cables[i];
    var pts = cable.points;
    if (!pts || pts.length < 2) continue;
    ctx.beginPath();
    var first = true;
    for (var j = 0; j < pts.length; j++) {
      var p = project(pts[j][0], pts[j][1]);
      if (p.visible) {
        if (first) { ctx.moveTo(p.x, p.y); first = false; }
        else ctx.lineTo(p.x, p.y);
      } else first = true;
    }
    ctx.strokeStyle = "rgba(255,0,255,0.4)";
    ctx.lineWidth = 1.5;
    ctx.setLineDash([4, 3]);
    ctx.stroke();
    ctx.setLineDash([]);
  }
}

// ── SHIPPING LANES ──────────────────────────────────────
function drawShippingLanes() {
  if (!LAYERS.shipping) return;
  for (var i = 0; i < DATA.shipping.length; i++) {
    var lane = DATA.shipping[i];
    var p = project(lane.lat, lane.lon);
    if (!p.visible) continue;
    ctx.beginPath();
    ctx.arc(p.x, p.y, 8, 0, Math.PI*2);
    ctx.strokeStyle = "rgba(0,200,255,0.5)";
    ctx.lineWidth = 1;
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(p.x, p.y, 14, 0, Math.PI*2);
    ctx.strokeStyle = "rgba(0,200,255,0.15)";
    ctx.stroke();
    ctx.fillStyle = "rgba(0,200,255,0.8)";
    ctx.font = "7px Share Tech Mono";
    ctx.textAlign = "center";
    ctx.fillText(lane.name.split(" ")[0], p.x, p.y + 22);
  }
}

// ── CYBER ATTACK ARCS ──────────────────────────────────
var cyberArcs = [];
var cyberAnimTimer = 0;

function animateCyberArcs(timestamp) {
  if (!LAYERS.cyber) return;
  if (timestamp - cyberAnimTimer > 800 && DATA.cyber.length > 0) {
    cyberAnimTimer = timestamp;
    var atk = DATA.cyber[Math.floor(Math.random() * DATA.cyber.length)];
    cyberArcs.push({
      src_lat: atk.src_lat, src_lon: atk.src_lon,
      dst_lat: atk.dst_lat, dst_lon: atk.dst_lon,
      type: atk.type, count: atk.count,
      progress: 0, alpha: 1.0
    });
    if (cyberArcs.length > 20) cyberArcs.shift();
  }
  for (var i = cyberArcs.length - 1; i >= 0; i--) {
    var arc = cyberArcs[i];
    arc.progress += 0.015;
    if (arc.progress > 1.4) { cyberArcs.splice(i, 1); continue; }
    arc.alpha = arc.progress < 1.0 ? 1.0 : 1.0 - (arc.progress - 1.0) / 0.4;
    drawCyberArc(arc);
  }
}

function drawCyberArc(arc) {
  var p1 = project(arc.src_lat, arc.src_lon);
  var p2 = project(arc.dst_lat, arc.dst_lon);
  if (!p1.visible || !p2.visible) return;
  var t = Math.min(arc.progress, 1.0);
  var mx = (p1.x + p2.x) / 2;
  var my = (p1.y + p2.y) / 2 - 60;
  var cx_t = p1.x + (mx - p1.x) * 2 * t - (mx - p1.x) * t * t;
  var cy_t = p1.y + (my - p1.y) * 2 * t - (my - p1.y) * t * t - (my - (p1.y+p2.y)/2) * t * (1-t);
  var tx = p1.x * (1-t)*(1-t) + mx * 2*t*(1-t) + p2.x * t*t;
  var ty = p1.y * (1-t)*(1-t) + my * 2*t*(1-t) + p2.y * t*t;
  ctx.beginPath();
  ctx.moveTo(p1.x, p1.y);
  ctx.quadraticCurveTo(mx, my, tx);
  // Just line to current point
  ctx.moveTo(p1.x, p1.y);
  ctx.lineTo(tx, ty);
  ctx.strokeStyle = "rgba(255,0,136," + (arc.alpha * 0.7) + ")";
  ctx.lineWidth = 1;
  ctx.stroke();
  // Dot at tip
  ctx.beginPath();
  ctx.arc(tx, ty, 2.5, 0, Math.PI*2);
  ctx.fillStyle = "rgba(255,0,136," + arc.alpha + ")";
  ctx.fill();
  // Impact flash
  if (arc.progress >= 1.0) {
    var flash = (arc.progress - 1.0) / 0.4;
    ctx.beginPath();
    ctx.arc(p2.x, p2.y, flash * 20, 0, Math.PI*2);
    ctx.strokeStyle = "rgba(255,0,136," + (arc.alpha * 0.5) + ")";
    ctx.lineWidth = 1;
    ctx.stroke();
  }
}

// ── DOTS WITH GLOW ──────────────────────────────────────
function drawDot(x, y, r, color, glow, label, labelColor, forceLabel) {
  ctx.beginPath();
  ctx.arc(x, y, r, 0, Math.PI*2);
  ctx.fillStyle = color;
  if (glow) {
    ctx.shadowBlur = 10;
    ctx.shadowColor = glow;
  }
  ctx.fill();
  ctx.shadowBlur = 0;
  if (label && (forceLabel || r > 4)) {
    ctx.fillStyle = labelColor || color;
    ctx.font = "8px Share Tech Mono";
    ctx.textAlign = "left";
    ctx.fillText(label, x + r + 2, y + 3);
  }
}

function drawPulse(x, y, r, color, phase) {
  var pulse = (Math.sin(Date.now() * 0.003 + phase) * 0.5 + 0.5);
  ctx.beginPath();
  ctx.arc(x, y, r + pulse * 6, 0, Math.PI*2);
  ctx.strokeStyle = color.replace("1)", (0.4 * pulse) + ")");
  ctx.lineWidth = 1;
  ctx.stroke();
  ctx.beginPath();
  ctx.arc(x, y, r, 0, Math.PI*2);
  ctx.fillStyle = color;
  ctx.shadowBlur = 8 + pulse * 8;
  ctx.shadowColor = color;
  ctx.fill();
  ctx.shadowBlur = 0;
}

// ── SHIPS ───────────────────────────────────────────────
function drawShips() {
  if (!LAYERS.ships) return;
  var colors = { "Container":"rgba(0,255,65,1)", "Tanker":"rgba(255,102,0,1)", "Bulk Carrier":"rgba(0,200,255,1)" };
  for (var i = 0; i < DATA.ships.length; i++) {
    var s = DATA.ships[i];
    var p = project(s.lat, s.lon);
    if (!p.visible) continue;
    var c = colors[s.type] || "rgba(0,255,65,1)";
    // Ship icon (triangle pointing in heading direction)
    var h = (s.heading || 0) * Math.PI / 180;
    ctx.save();
    ctx.translate(p.x, p.y);
    ctx.rotate(h);
    ctx.beginPath();
    ctx.moveTo(0, -5);
    ctx.lineTo(-3, 3);
    ctx.lineTo(3, 3);
    ctx.closePath();
    ctx.fillStyle = c;
    ctx.shadowBlur = 6;
    ctx.shadowColor = c;
    ctx.fill();
    ctx.shadowBlur = 0;
    ctx.restore();
    hitTargets.push({x: p.x, y: p.y, r: 6, data: s, type: "ship"});
  }
}

// ── FLIGHTS ─────────────────────────────────────────────
function drawFlights() {
  if (!LAYERS.flights) return;
  for (var i = 0; i < DATA.flights.length; i++) {
    var f = DATA.flights[i];
    var p = project(f.lat, f.lon);
    if (!p.visible) continue;
    var h = (f.heading || 0) * Math.PI / 180;
    ctx.save();
    ctx.translate(p.x, p.y);
    ctx.rotate(h);
    // Airplane icon
    ctx.fillStyle = "rgba(0,245,255,0.9)";
    ctx.shadowBlur = 5;
    ctx.shadowColor = "rgba(0,245,255,0.8)";
    ctx.beginPath();
    ctx.moveTo(0, -5); ctx.lineTo(1.5, -2); ctx.lineTo(5, -1);
    ctx.lineTo(5, 0); ctx.lineTo(1.5, 0); ctx.lineTo(2, 2);
    ctx.lineTo(4, 2.5); ctx.lineTo(4, 3.5); ctx.lineTo(2, 3);
    ctx.lineTo(0, 4); ctx.lineTo(-2, 3); ctx.lineTo(-4, 3.5);
    ctx.lineTo(-4, 2.5); ctx.lineTo(-2, 2); ctx.lineTo(-1.5, 0);
    ctx.lineTo(-5, 0); ctx.lineTo(-5, -1); ctx.lineTo(-1.5, -2);
    ctx.closePath();
    ctx.fill();
    ctx.shadowBlur = 0;
    ctx.restore();
    hitTargets.push({x: p.x, y: p.y, r: 8, data: f, type: "flight"});
  }
}

// ── EARTHQUAKES ─────────────────────────────────────────
function drawEarthquakes() {
  if (!LAYERS.earthquakes) return;
  for (var i = 0; i < DATA.earthquakes.length; i++) {
    var eq = DATA.earthquakes[i];
    var p = project(eq.lat, eq.lon);
    if (!p.visible) continue;
    var r = Math.max(3, Math.min(14, (eq.mag - 2) * 3));
    var col = eq.mag >= 6 ? "rgba(255,0,51,1)" : eq.mag >= 5 ? "rgba(255,102,0,1)" : "rgba(255,200,0,0.8)";
    drawPulse(p.x, p.y, r, col, i);
    hitTargets.push({x: p.x, y: p.y, r: r+4, data: eq, type: "earthquake"});
  }
}

// ── VOLCANOES ───────────────────────────────────────────
function drawVolcanoes() {
  if (!LAYERS.volcanoes) return;
  for (var i = 0; i < DATA.volcanoes.length; i++) {
    var v = DATA.volcanoes[i];
    var p = project(v.lat, v.lon);
    if (!p.visible) continue;
    // Triangle (volcano)
    ctx.beginPath();
    ctx.moveTo(p.x, p.y - 7);
    ctx.lineTo(p.x - 5, p.y + 4);
    ctx.lineTo(p.x + 5, p.y + 4);
    ctx.closePath();
    ctx.fillStyle = "rgba(255,0,51,0.8)";
    ctx.shadowBlur = 8;
    ctx.shadowColor = "#ff0033";
    ctx.fill();
    ctx.shadowBlur = 0;
    // Lava glow at tip
    ctx.beginPath();
    ctx.arc(p.x, p.y - 7, 2.5, 0, Math.PI*2);
    ctx.fillStyle = "#ffaa00";
    ctx.shadowBlur = 10;
    ctx.shadowColor = "#ff6600";
    ctx.fill();
    ctx.shadowBlur = 0;
    hitTargets.push({x: p.x, y: p.y, r: 8, data: v, type: "volcano"});
  }
}

// ── WILDFIRES ───────────────────────────────────────────
function drawWildfires() {
  if (!LAYERS.wildfires) return;
  var phase = Date.now() * 0.006;
  for (var i = 0; i < DATA.wildfires.length; i++) {
    var wf = DATA.wildfires[i];
    var p = project(wf.lat, wf.lon);
    if (!p.visible) continue;
    var flicker = Math.sin(phase + i * 1.3) * 0.5 + 0.5;
    ctx.beginPath();
    ctx.arc(p.x, p.y, 4 + flicker * 3, 0, Math.PI*2);
    ctx.fillStyle = "rgba(255," + Math.floor(60 + flicker * 80) + ",0," + (0.6 + flicker * 0.4) + ")";
    ctx.shadowBlur = 12;
    ctx.shadowColor = "#ff4400";
    ctx.fill();
    ctx.shadowBlur = 0;
    hitTargets.push({x: p.x, y: p.y, r: 8, data: wf, type: "wildfire"});
  }
}

// ── ISS ─────────────────────────────────────────────────
function drawISS() {
  if (!LAYERS.iss || !DATA.iss) return;
  var p = project(DATA.iss.lat, DATA.iss.lon);
  if (!p.visible) return;
  var pulse = (Math.sin(Date.now() * 0.005) * 0.5 + 0.5);
  // Orbit ring
  ctx.beginPath();
  ctx.arc(p.x, p.y, 12 + pulse * 5, 0, Math.PI*2);
  ctx.strokeStyle = "rgba(255,255,255," + (0.2 + pulse * 0.2) + ")";
  ctx.lineWidth = 1;
  ctx.stroke();
  // ISS icon (cross)
  ctx.fillStyle = "#ffffff";
  ctx.shadowBlur = 12;
  ctx.shadowColor = "#aaaaff";
  ctx.fillRect(p.x - 5, p.y - 1.5, 10, 3);
  ctx.fillRect(p.x - 1.5, p.y - 5, 3, 10);
  ctx.shadowBlur = 0;
  // Label
  ctx.fillStyle = "rgba(200,200,255,0.9)";
  ctx.font = "bold 8px Share Tech Mono";
  ctx.textAlign = "center";
  ctx.fillText("ISS", p.x, p.y + 18);
  hitTargets.push({x: p.x, y: p.y, r: 10, data: DATA.iss, type: "iss"});
}

// ── SATELLITES ──────────────────────────────────────────
function drawSatellites() {
  if (!LAYERS.satellites) return;
  for (var i = 0; i < DATA.satellites.length; i++) {
    var s = DATA.satellites[i];
    var p = project(s.lat, s.lon);
    if (!p.visible) continue;
    ctx.beginPath();
    ctx.arc(p.x, p.y, 2, 0, Math.PI*2);
    ctx.fillStyle = "rgba(150,150,255,0.8)";
    ctx.fill();
    hitTargets.push({x: p.x, y: p.y, r: 4, data: s, type: "satellite"});
  }
}

// ── WEATHER ─────────────────────────────────────────────
function drawWeather() {
  if (!LAYERS.weather) return;
  for (var i = 0; i < DATA.weather.length; i++) {
    var w = DATA.weather[i];
    var p = project(w.lat, w.lon);
    if (!p.visible) continue;
    var tempColor = w.temp > 35 ? "#ff4400" : w.temp > 25 ? "#ff8800" : w.temp > 15 ? "#ffcc00" : w.temp > 5 ? "#00ccff" : "#0088ff";
    ctx.beginPath();
    ctx.arc(p.x, p.y, 5, 0, Math.PI*2);
    ctx.fillStyle = tempColor;
    ctx.shadowBlur = 8;
    ctx.shadowColor = tempColor;
    ctx.fill();
    ctx.shadowBlur = 0;
    ctx.fillStyle = "rgba(255,255,255,0.7)";
    ctx.font = "7px Share Tech Mono";
    ctx.textAlign = "center";
    ctx.fillText(w.temp + "°", p.x, p.y - 8);
    hitTargets.push({x: p.x, y: p.y, r: 7, data: w, type: "weather"});
  }
}

// ── MILITARY ────────────────────────────────────────────
function drawMilitary() {
  if (!LAYERS.military) return;
  for (var i = 0; i < DATA.military.length; i++) {
    var m = DATA.military[i];
    var p = project(m.lat, m.lon);
    if (!p.visible) continue;
    // Star shape
    ctx.beginPath();
    for (var j = 0; j < 5; j++) {
      var a = (j * 4 * Math.PI / 5) - Math.PI/2;
      var xi = p.x + Math.cos(a) * 5;
      var yi = p.y + Math.sin(a) * 5;
      if (j === 0) ctx.moveTo(xi, yi); else ctx.lineTo(xi, yi);
    }
    ctx.closePath();
    ctx.fillStyle = "rgba(255,0,51,0.85)";
    ctx.shadowBlur = 10;
    ctx.shadowColor = "#ff0033";
    ctx.fill();
    ctx.shadowBlur = 0;
    hitTargets.push({x: p.x, y: p.y, r: 7, data: m, type: "military"});
  }
}

// ── NUCLEAR ─────────────────────────────────────────────
function drawNuclear() {
  if (!LAYERS.nuclear) return;
  for (var i = 0; i < DATA.nuclear.length; i++) {
    var n = DATA.nuclear[i];
    var p = project(n.lat, n.lon);
    if (!p.visible) continue;
    // Radioactive symbol (simplified)
    var pulse2 = Math.sin(Date.now() * 0.002 + i) * 0.3 + 0.7;
    ctx.beginPath();
    ctx.arc(p.x, p.y, 5, 0, Math.PI*2);
    ctx.fillStyle = "rgba(255,255,0," + pulse2 + ")";
    ctx.shadowBlur = 12;
    ctx.shadowColor = "rgba(255,220,0,0.8)";
    ctx.fill();
    ctx.shadowBlur = 0;
    ctx.fillStyle = "rgba(0,0,0,0.8)";
    ctx.font = "7px sans-serif";
    ctx.textAlign = "center";
    ctx.fillText("☢", p.x, p.y + 2.5);
    hitTargets.push({x: p.x, y: p.y, r: 8, data: n, type: "nuclear"});
  }
}

// ── CONFLICTS ───────────────────────────────────────────
function drawConflicts() {
  if (!LAYERS.conflicts) return;
  for (var i = 0; i < DATA.conflicts.length; i++) {
    var c = DATA.conflicts[i];
    var p = project(c.lat, c.lon);
    if (!p.visible) continue;
    var intensity = c.intensity === "critical" ? 1.0 : c.intensity === "high" ? 0.7 : 0.4;
    var r = 10 + intensity * 6;
    var phase2 = Date.now() * 0.004 + i;
    var pulse3 = Math.sin(phase2) * 0.5 + 0.5;
    ctx.beginPath();
    ctx.arc(p.x, p.y, r * (0.8 + pulse3 * 0.4), 0, Math.PI*2);
    ctx.strokeStyle = "rgba(255," + Math.floor(intensity * 50) + ",0," + (0.4 * intensity) + ")";
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(p.x, p.y, 5, 0, Math.PI*2);
    ctx.fillStyle = "rgba(255,0,0," + intensity + ")";
    ctx.shadowBlur = 15;
    ctx.shadowColor = "#ff0000";
    ctx.fill();
    ctx.shadowBlur = 0;
    hitTargets.push({x: p.x, y: p.y, r: r, data: c, type: "conflict"});
  }
}

// ── INTERNET EXCHANGE POINTS ────────────────────────────
function drawIXP() {
  if (!LAYERS.ixp) return;
  for (var i = 0; i < DATA.ixp.length; i++) {
    var node = DATA.ixp[i];
    var p = project(node.lat, node.lon);
    if (!p.visible) continue;
    var size = Math.min(10, Math.max(4, node.traffic_tbps));
    ctx.beginPath();
    ctx.rect(p.x - size/2, p.y - size/2, size, size);
    ctx.fillStyle = "rgba(0,255,170,0.8)";
    ctx.shadowBlur = 8;
    ctx.shadowColor = "#00ffaa";
    ctx.fill();
    ctx.shadowBlur = 0;
    // Connection lines to nearby nodes (simplified)
    hitTargets.push({x: p.x, y: p.y, r: 8, data: node, type: "ixp"});
  }
}

// ── HIT TESTING ─────────────────────────────────────────
function findHit(mx, my) {
  var best = null, bestDist = 15;
  for (var i = hitTargets.length - 1; i >= 0; i--) {
    var t = hitTargets[i];
    var dx = mx - t.x, dy = my - t.y;
    var dist = Math.sqrt(dx*dx + dy*dy);
    if (dist < t.r + 8 && dist < bestDist) {
      bestDist = dist;
      best = t;
    }
  }
  return best;
}

// ── DETAIL POPUP ─────────────────────────────────────────
function showDetail(hit) {
  var d = hit.data;
  var t = hit.type;
  var content = "";
  var title = "";
  var rows = [];

  if (t === "ship") {
    title = "⚓ " + d.name;
    rows = [
      ["TYPE", d.type], ["FLAG", d.flag], ["SPEED", d.speed + " kn"],
      ["HEADING", d.heading + "°"], ["MMSI", d.mmsi], ["IMO", d.imo],
      ["LENGTH", d.length + " m"], ["DESTINATION", d.destination],
      ["POSITION", d.lat.toFixed(3) + "°, " + d.lon.toFixed(3) + "°"]
    ];
  } else if (t === "flight") {
    title = "✈ " + d.callsign;
    rows = [
      ["AIRLINE", d.airline], ["AIRCRAFT", d.aircraft],
      ["FROM", d.from], ["TO", d.to],
      ["ALTITUDE", d.altitude.toLocaleString() + " ft"],
      ["SPEED", d.speed + " km/h"], ["HEADING", d.heading + "°"],
      ["PROGRESS", d.progress + "%"],
      ["POSITION", d.lat.toFixed(3) + "°, " + d.lon.toFixed(3) + "°"]
    ];
  } else if (t === "earthquake") {
    title = "⚡ EARTHQUAKE M" + d.mag;
    rows = [
      ["LOCATION", d.place], ["MAGNITUDE", "M" + d.mag],
      ["DEPTH", d.depth + " km"],
      ["TIME", new Date(d.time).toUTCString()],
      ["LAT/LON", d.lat.toFixed(3) + "° / " + d.lon.toFixed(3) + "°"],
      ["USGS ID", d.id]
    ];
  } else if (t === "volcano") {
    title = "🌋 " + d.name;
    rows = [
      ["COUNTRY", d.country], ["STATUS", d.status],
      ["ELEVATION", d.elevation + " m"],
      ["COORDINATES", d.lat.toFixed(3) + "°, " + d.lon.toFixed(3) + "°"]
    ];
  } else if (t === "wildfire") {
    title = "🔥 ACTIVE WILDFIRE";
    rows = [
      ["BRIGHTNESS", d.brightness + " K"],
      ["POSITION", d.lat.toFixed(3) + "°, " + d.lon.toFixed(3) + "°"],
      ["SOURCE", "VIIRS/MODIS"]
    ];
  } else if (t === "iss") {
    title = "🛸 INTERNATIONAL SPACE STATION";
    rows = [
      ["LATITUDE", d.lat.toFixed(4) + "°"],
      ["LONGITUDE", d.lon.toFixed(4) + "°"],
      ["ALTITUDE", "408 km"],
      ["ORBITAL SPEED", "27,600 km/h"],
      ["ORBITAL PERIOD", "92.9 min"],
      ["CREW ONBOARD", DATA.crew.length || "Unknown"]
    ];
  } else if (t === "satellite") {
    title = "🛰 " + d.name;
    rows = [
      ["ALTITUDE", d.alt + " km"],
      ["POSITION", d.lat.toFixed(2) + "°, " + d.lon.toFixed(2) + "°"],
      ["TYPE", "Satellite"]
    ];
  } else if (t === "weather") {
    title = "🌡 " + d.city + " WEATHER";
    rows = [
      ["TEMPERATURE", d.temp + "°C"],
      ["WIND", d.wind + " km/h"],
      ["HUMIDITY", d.humidity + "%"],
      ["PRESSURE", d.pressure + " hPa"]
    ];
  } else if (t === "military") {
    title = "🎯 " + d.name;
    rows = [
      ["COUNTRY", d.country], ["FORCE", d.force],
      ["TYPE", d.type],
      ["COORDINATES", d.lat.toFixed(3) + "°, " + d.lon.toFixed(3) + "°"]
    ];
  } else if (t === "nuclear") {
    title = "☢ " + d.name;
    rows = [
      ["COUNTRY", d.country], ["TYPE", d.type],
      ["STATUS", d.status], ["REACTORS", d.reactors],
      ["COORDINATES", d.lat.toFixed(3) + "°, " + d.lon.toFixed(3) + "°"]
    ];
  } else if (t === "conflict") {
    title = "⚠ " + d.name;
    rows = [
      ["TYPE", d.type], ["STATUS", d.status],
      ["INTENSITY", d.intensity.toUpperCase()],
      ["SINCE", d.since],
      ["COORDINATES", d.lat.toFixed(2) + "°, " + d.lon.toFixed(2) + "°"]
    ];
  } else if (t === "ixp") {
    title = "🌐 " + d.name;
    rows = [
      ["COUNTRY", d.country],
      ["TRAFFIC", d.traffic_tbps + " Tbps"],
      ["PEERS", d.peers],
      ["COORDINATES", d.lat.toFixed(2) + "°, " + d.lon.toFixed(2) + "°"]
    ];
  }

  content = "<h3>" + title + "</h3>";
  for (var r of rows) {
    content += '<div class="d-row"><span class="d-key">' + r[0] + '</span><span class="d-val">' + r[1] + '</span></div>';
  }

  document.getElementById("detail-content").innerHTML = content;
  var pop = document.getElementById("detail-popup");
  pop.classList.remove("show");
  void pop.offsetWidth;
  pop.classList.add("show");
}

function closeDetail() {
  document.getElementById("detail-popup").classList.remove("show");
}

// ── MINIMAP ─────────────────────────────────────────────
function drawMinimap() {
  var mc = document.getElementById("minimap-canvas");
  var mctx = mc.getContext("2d");
  var mw = mc.width, mh = mc.height;
  mctx.fillStyle = "#020a14";
  mctx.fillRect(0,0,mw,mh);
  mctx.strokeStyle = "rgba(0,245,255,0.2)";
  mctx.lineWidth = 0.5;
  mctx.strokeRect(0,0,mw,mh);
  // Draw simplified world outline dots
  var dots = [
    // Major landmass centroids
    [37,-95],[56,0],[20,80],[0,25],[20,105],[-25,134],[-15,-55],[57,37],[35,105]
  ];
  mctx.fillStyle = "rgba(0,245,255,0.15)";
  for (var i = 0; i < 800; i++) {
    var lx = ((i * 2.37 % 360) - 180);
    var ly = ((i * 1.73 % 180) - 90);
    var mx2 = (lx + 180) / 360 * mw;
    var my2 = (90 - ly) / 180 * mh;
    mctx.fillRect(mx2, my2, 0.8, 0.8);
  }
  // Current view indicator
  var vlon = -(globe_rot_lon * 180 / Math.PI) % 360;
  var vlat = -(globe_rot_lat * 180 / Math.PI);
  var vx = (vlon + 180) / 360 * mw;
  var vy = (90 - vlat) / 180 * mh;
  mctx.beginPath();
  mctx.arc(vx, vy, 3, 0, Math.PI*2);
  mctx.fillStyle = "rgba(0,245,255,0.8)";
  mctx.fill();
  mctx.strokeStyle = "rgba(0,245,255,0.4)";
  mctx.lineWidth = 0.5;
  mctx.beginPath();
  mctx.arc(vx, vy, 8, 0, Math.PI*2);
  mctx.stroke();
  // Ships
  if (LAYERS.ships) {
    mctx.fillStyle = "rgba(0,255,65,0.6)";
    for (var s of DATA.ships) {
      mctx.fillRect((s.lon+180)/360*mw, (90-s.lat)/180*mh, 1, 1);
    }
  }
  // Conflicts
  if (LAYERS.conflicts) {
    mctx.fillStyle = "rgba(255,0,0,0.7)";
    for (var c of DATA.conflicts) {
      mctx.fillRect((c.lon+180)/360*mw-1, (90-c.lat)/180*mh-1, 2, 2);
    }
  }
}

// ── MAIN RENDER LOOP ────────────────────────────────────
var lastFrame = 0;
function render(timestamp) {
  requestAnimationFrame(render);
  ctx.clearRect(0, 0, W, H);
  ctx.fillStyle = "#000408";
  ctx.fillRect(0, 0, W, H);
  drawStars();
  hitTargets = [];
  if (viewMode === "FLAT") {
    drawFlatMap();
  } else {
    drawGlobe();
  }
  drawCables();
  drawShippingLanes();
  drawConflicts();
  drawMilitary();
  drawNuclear();
  drawWildfires();
  drawEarthquakes();
  drawVolcanoes();
  drawWeather();
  drawIXP();
  animateCyberArcs(timestamp);
  drawShips();
  drawFlights();
  drawSatellites();
  drawISS();
  if (autoRotating && !isDragging) {
    globe_rot_lon += rotSpeed;
  }
  updateClock();
  if (timestamp - lastFrame > 5000) {
    lastFrame = timestamp;
    drawMinimap();
  }
}
requestAnimationFrame(render);

// ── CONTROLS ────────────────────────────────────────────
canvas.addEventListener("mousedown", function(e) {
  isDragging = true;
  dragX = e.clientX; dragY = e.clientY;
  autoRotating = false;
});
canvas.addEventListener("mousemove", function(e) {
  mouseX = e.clientX; mouseY = e.clientY;
  if (isDragging) {
    var dx = e.clientX - dragX, dy = e.clientY - dragY;
    globe_rot_lon += dx * 0.005;
    globe_rot_lat += dy * 0.005;
    globe_rot_lat = Math.max(-1.4, Math.min(1.4, globe_rot_lat));
    dragX = e.clientX; dragY = e.clientY;
  }
  // Coord display
  var lat = -(globe_rot_lat * 180 / Math.PI);
  var lon = -(globe_rot_lon * 180 / Math.PI) % 360;
  document.getElementById("cur-lat").textContent = lat.toFixed(2) + "°";
  document.getElementById("cur-lon").textContent = lon.toFixed(2) + "°";
});
canvas.addEventListener("mouseup", function(e) {
  if (!isDragging) return;
  isDragging = false;
  var hit = findHit(e.clientX, e.clientY);
  if (hit) showDetail(hit);
});
canvas.addEventListener("wheel", function(e) {
  e.preventDefault();
  zoom *= e.deltaY > 0 ? 0.93 : 1.07;
  zoom = Math.max(0.4, Math.min(3.5, zoom));
  RADIUS = Math.min(W, H) * 0.38 * zoom;
}, {passive: false});

// Touch support for mobile
var lastTouch = null, lastTouchDist = null;
canvas.addEventListener("touchstart", function(e) {
  e.preventDefault();
  if (e.touches.length === 1) {
    isDragging = true;
    autoRotating = false;
    dragX = e.touches[0].clientX;
    dragY = e.touches[0].clientY;
    lastTouch = {x: e.touches[0].clientX, y: e.touches[0].clientY, t: Date.now()};
  } else if (e.touches.length === 2) {
    var dx = e.touches[0].clientX - e.touches[1].clientX;
    var dy = e.touches[0].clientY - e.touches[1].clientY;
    lastTouchDist = Math.sqrt(dx*dx + dy*dy);
  }
}, {passive: false});
canvas.addEventListener("touchmove", function(e) {
  e.preventDefault();
  if (e.touches.length === 1 && isDragging) {
    var dx2 = e.touches[0].clientX - dragX;
    var dy2 = e.touches[0].clientY - dragY;
    globe_rot_lon += dx2 * 0.005;
    globe_rot_lat += dy2 * 0.005;
    globe_rot_lat = Math.max(-1.4, Math.min(1.4, globe_rot_lat));
    dragX = e.touches[0].clientX;
    dragY = e.touches[0].clientY;
  } else if (e.touches.length === 2 && lastTouchDist) {
    var dx3 = e.touches[0].clientX - e.touches[1].clientX;
    var dy3 = e.touches[0].clientY - e.touches[1].clientY;
    var dist = Math.sqrt(dx3*dx3 + dy3*dy3);
    zoom *= dist / lastTouchDist;
    zoom = Math.max(0.4, Math.min(3.5, zoom));
    RADIUS = Math.min(W, H) * 0.38 * zoom;
    lastTouchDist = dist;
  }
}, {passive: false});
canvas.addEventListener("touchend", function(e) {
  isDragging = false;
  if (lastTouch && e.changedTouches.length === 1) {
    var ct = e.changedTouches[0];
    var dt = Date.now() - lastTouch.t;
    var dx4 = ct.clientX - lastTouch.x, dy4 = ct.clientY - lastTouch.y;
    if (Math.sqrt(dx4*dx4+dy4*dy4) < 10 && dt < 300) {
      var hit = findHit(ct.clientX, ct.clientY);
      if (hit) showDetail(hit);
    }
  }
  lastTouch = null; lastTouchDist = null;
}, {passive: false});

// ── UI FUNCTIONS ─────────────────────────────────────────
function toggleLayer(id) {
  LAYERS[id] = !LAYERS[id];
  var el = document.getElementById("lyr-" + id);
  if (el) {
    el.className = "layer-item " + (LAYERS[id] ? "layer-active" : "layer-inactive");
  }
}

function setViewMode(mode) {
  viewMode = mode;
  document.querySelectorAll(".mode-btn").forEach(function(b) {
    b.className = "mode-btn" + (b.textContent === mode ? " active" : "");
  });
}

function autoRotate() {
  autoRotating = !autoRotating;
}

function resetView() {
  globe_rot_lon = 0; globe_rot_lat = 0; zoom = 1.0;
  RADIUS = Math.min(W, H) * 0.38;
  closeDetail();
}

function toggleSearch() {
  var sb = document.getElementById("search-box");
  sb.style.display = sb.style.display === "none" ? "block" : "none";
  if (sb.style.display === "block") document.getElementById("search-input").focus();
}

function handleSearch(q) {
  q = q.toLowerCase().trim();
  if (q.length < 2) return;
  // Find matching object and fly to it
  var allData = [].concat(
    DATA.ships.map(function(x){return {d:x,t:"ship"}}),
    DATA.flights.map(function(x){return {d:x,t:"flight"}}),
    DATA.earthquakes.map(function(x){return {d:x,t:"earthquake"}}),
    DATA.volcanoes.map(function(x){return {d:x,t:"volcano"}}),
    DATA.military.map(function(x){return {d:x,t:"military"}}),
    DATA.nuclear.map(function(x){return {d:x,t:"nuclear"}}),
    DATA.conflicts.map(function(x){return {d:x,t:"conflict"}}),
    DATA.weather.map(function(x){return {d:x,t:"weather"}}),
    DATA.ixp.map(function(x){return {d:x,t:"ixp"}})
  );
  for (var item of allData) {
    var d = item.d;
    var name = (d.name || d.callsign || d.city || d.place || "").toLowerCase();
    if (name.includes(q)) {
      // Fly globe to this location
      globe_rot_lon = -d.lon * Math.PI / 180;
      globe_rot_lat = d.lat * Math.PI / 180;
      autoRotating = false;
      break;
    }
  }
}

function updateClock() {
  var now = new Date();
  var h = now.getUTCHours().toString().padStart(2,"0");
  var m = now.getUTCMinutes().toString().padStart(2,"0");
  var s = now.getUTCSeconds().toString().padStart(2,"0");
  document.getElementById("live-clock").textContent = h+":"+m+":"+s+" UTC";
}

// ── DATA FETCHING ────────────────────────────────────────
var BASE = "http://localhost:" + 8888;

function fetchData(endpoint, callback) {
  var xhr = new XMLHttpRequest();
  xhr.open("GET", BASE + endpoint, true);
  xhr.timeout = 8000;
  xhr.onload = function() {
    if (xhr.status === 200) {
      try { callback(JSON.parse(xhr.responseText)); } catch(e) {}
    }
  };
  xhr.onerror = function() {};
  xhr.ontimeout = function() {};
  xhr.send();
}

function updateISS() {
  fetchData("/api/iss", function(d) {
    if (d) {
      DATA.iss = d;
      document.getElementById("iss-lat").textContent = parseFloat(d.lat).toFixed(4) + "°";
      document.getElementById("iss-lon").textContent = parseFloat(d.lon).toFixed(4) + "°";
    }
  });
  fetchData("/api/crew", function(d) {
    if (d) {
      DATA.crew = d;
      document.getElementById("iss-crew").textContent = d.length + " PEOPLE";
    }
  });
}

function updateEarthquakes() {
  fetchData("/api/earthquakes", function(d) {
    if (d && d.length) {
      DATA.earthquakes = d;
      document.getElementById("ts-eq").textContent = d.length;
      document.getElementById("cnt-earthquakes").textContent = d.length;
      var html = "";
      d.slice(0,4).forEach(function(eq) {
        var color = eq.mag >= 6 ? "var(--neon-red)" : eq.mag >= 5 ? "var(--neon-orange)" : "var(--neon-yellow)";
        html += '<div class="info-row"><span class="k" style="font-size:8px;max-width:130px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">' + (eq.place||"Unknown").substr(0,25) + '</span><span class="v" style="color:'+color+'">M'+eq.mag+'</span></div>';
      });
      document.getElementById("eq-list").innerHTML = html;
    }
  });
}

function updateShips() {
  fetchData("/api/ships", function(d) {
    if (d && d.length) {
      DATA.ships = d;
      document.getElementById("ts-ships").textContent = d.length;
      document.getElementById("cnt-ships").textContent = d.length;
      var cont = d.filter(function(s){return s.type==="Container"}).length;
      var tank = d.filter(function(s){return s.type==="Tanker"}).length;
      var bulk = d.filter(function(s){return s.type==="Bulk Carrier"}).length;
      document.getElementById("ship-container").textContent = cont;
      document.getElementById("ship-tanker").textContent = tank;
      document.getElementById("ship-bulk").textContent = bulk;
    }
  });
}

function updateFlights() {
  fetchData("/api/flights", function(d) {
    if (d && d.length) {
      DATA.flights = d;
      document.getElementById("ts-flights").textContent = d.length;
      document.getElementById("cnt-flights").textContent = d.length;
    }
  });
}

function updateCyber() {
  fetchData("/api/cyber", function(d) {
    if (d && d.length) {
      DATA.cyber = d;
      var total = d.reduce(function(a,c){return a+c.count;}, 0);
      document.getElementById("cy-total").textContent = Math.floor(total/60);
      document.getElementById("cy-src").textContent = 847;
      document.getElementById("ts-threats").textContent = d.length;
      var srcCounts = {};
      d.forEach(function(a) {
        srcCounts[a.src_country] = (srcCounts[a.src_country]||0) + a.count;
      });
      var sorted = Object.entries(srcCounts).sort(function(a,b){return b[1]-a[1]}).slice(0,4);
      var html = "";
      sorted.forEach(function(s) {
        html += '<div class="info-row"><span class="k">'+s[0]+'</span><span class="v" style="color:var(--neon-red)">'+s[1].toLocaleString()+'</span></div>';
      });
      document.getElementById("cy-top").innerHTML = html;
    }
  });
}

function updateStaticData() {
  fetchData("/api/volcanoes", function(d) { if(d) { DATA.volcanoes=d; document.getElementById("cnt-volcanoes").textContent=d.length; } });
  fetchData("/api/wildfires", function(d) { if(d) DATA.wildfires=d; });
  fetchData("/api/weather", function(d) { if(d) DATA.weather=d; });
  fetchData("/api/military", function(d) { if(d) { DATA.military=d; document.getElementById("cnt-military").textContent=d.length; } });
  fetchData("/api/nuclear", function(d) { if(d) { DATA.nuclear=d; document.getElementById("cnt-nuclear").textContent=d.length; } });
  fetchData("/api/conflicts", function(d) { if(d) { DATA.conflicts=d; document.getElementById("cnt-conflicts").textContent=d.length; } });
  fetchData("/api/cables", function(d) { if(d) DATA.cables=d; });
  fetchData("/api/shipping", function(d) { if(d) DATA.shipping=d; });
  fetchData("/api/space", function(d) {
    if(d) {
      DATA.satellites = d.filter(function(s){return s.type==="satellite"});
      document.getElementById("cnt-satellites").textContent = DATA.satellites.length;
    }
  });
  fetchData("/api/ixp", function(d) {
    if(d) {
      DATA.ixp = d;
      document.getElementById("cnt-ixp").textContent = d.length;
      var html = "";
      d.slice(0,4).forEach(function(node) {
        html += '<div class="info-row"><span class="k" style="font-size:7px">'+node.name.substr(0,16)+'</span><span class="v">'+node.traffic_tbps+'T</span></div>';
      });
      document.getElementById("ixp-list").innerHTML = html;
    }
  });
}

function updateTicker() {
  var msgs = [];
  DATA.earthquakes.slice(0,3).forEach(function(eq) {
    msgs.push("⚡ EARTHQUAKE M" + eq.mag + " — " + (eq.place||"").substr(0,30));
  });
  DATA.conflicts.filter(function(c){return c.intensity==="critical"||c.intensity==="high"}).forEach(function(c) {
    msgs.push("⚠ CONFLICT: " + c.name + " [" + c.status.toUpperCase() + "]");
  });
  msgs.push("🛸 ISS CREW: " + (DATA.crew.length||7) + " ASTRONAUTS ONBOARD");
  msgs.push("⚓ " + DATA.ships.length + " VESSELS TRACKED GLOBALLY");
  msgs.push("✈ " + DATA.flights.length + " FLIGHTS IN ACTIVE MONITORING");
  msgs.push("🌐 NEXUS INTELLIGENCE PLATFORM // ALL SYSTEMS NOMINAL // " + new Date().toUTCString());
  document.getElementById("ticker-text").textContent = msgs.join("  ///  ");
  document.getElementById("update-time").textContent = "SYNC: " + new Date().toUTCTimeString ? new Date().toUTCString().split(" ")[4] : "--";
}

// Space weather simulation
function updateSpaceWeather() {
  var kp = (Math.sin(Date.now()/100000)*2 + 3 + Math.random()*0.3).toFixed(1);
  var sw = Math.floor(380 + Math.random()*100);
  document.getElementById("kp-val").textContent = kp;
  document.getElementById("sw-val").textContent = sw + " km/s";
  document.getElementById("kp-bar").style.width = (parseFloat(kp)/9*100) + "%";
}

// Initial load
updateStaticData();
updateEarthquakes();
updateShips();
updateFlights();
updateISS();
updateCyber();
updateSpaceWeather();

// Refresh intervals
setInterval(updateISS, 5000);
setInterval(updateEarthquakes, 30000);
setInterval(updateShips, 15000);
setInterval(updateFlights, 10000);
setInterval(updateCyber, 20000);
setInterval(updateStaticData, 60000);
setInterval(updateTicker, 5000);
setInterval(updateSpaceWeather, 8000);
setInterval(drawMinimap, 3000);
''')

A('</script>')
A('</body>')
A('</html>')

with open('/tmp/nexus_world.html', 'w') as f:
    f.write('\n'.join(lines))

print("[NEXUS] HTML interface generated: /tmp/nexus_world.html")
HTMLGEN

echo -e "${GREEN}[+] Interface built successfully.${NC}"

# ─── KILL EXISTING ────────────────────────────────────────────────────────────
echo -e "${YELLOW}[*] Checking for existing processes...${NC}"
pkill -f "nexus_server.py" 2>/dev/null
pkill -f "python.*$PORT" 2>/dev/null
sleep 1

# ─── START SERVER ─────────────────────────────────────────────────────────────
echo -e "${GREEN}[+] Starting NEXUS Intelligence Server on port $PORT...${NC}"
python3 "$PY_SERVER" &
SERVER_PID=$!
sleep 2

if kill -0 $SERVER_PID 2>/dev/null; then
    echo -e "${GREEN}[✓] Server running (PID: $SERVER_PID)${NC}"
else
    echo -e "${RED}[✗] Server failed to start. Trying port 8889...${NC}"
    PORT=8889
    sed -i "s/PORT = 8888/PORT = 8889/g" "$PY_SERVER"
    python3 "$PY_SERVER" &
    SERVER_PID=$!
    sleep 1
fi

echo ""
echo -e "${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC}  ${GREEN}NEXUS WORLD INTELLIGENCE PLATFORM ACTIVE${NC}              ${PURPLE}║${NC}"
echo -e "${PURPLE}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${PURPLE}║${NC}  ${CYAN}URL:${NC}     http://localhost:${PORT}/                       ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${CYAN}PID:${NC}     ${SERVER_PID}                                         ${PURPLE}║${NC}"
echo -e "${PURPLE}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${PURPLE}║${NC}  ${YELLOW}LAYERS AVAILABLE:${NC}                                      ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${GREEN}●${NC} Ships (525+)    ${GREEN}●${NC} Flights (100+)  ${GREEN}●${NC} ISS Live      ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${RED}●${NC} Earthquakes     ${RED}●${NC} Volcanoes (15) ${RED}●${NC} Conflicts     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${YELLOW}●${NC} Nuclear (12)    ${RED}●${NC} Military (12) ${YELLOW}●${NC} Wildfires     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${PURPLE}●${NC} Undersea Cables ${GREEN}●${NC} IXP Nodes    ${CYAN}●${NC} Ship Lanes    ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${RED}●${NC} Cyber Attacks   ${CYAN}●${NC} Satellites   ${CYAN}●${NC} Weather       ${PURPLE}║${NC}"
echo -e "${PURPLE}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${PURPLE}║${NC}  ${CYAN}CONTROLS:${NC}                                              ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  Drag: Rotate Globe  |  Pinch: Zoom  |  Tap: Details  ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  Buttons: GLOBE/FLAT/TACTICAL views + Search          ${PURPLE}║${NC}"
echo -e "${PURPLE}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${PURPLE}║${NC}  ${RED}STOP:${NC} kill $SERVER_PID  OR  pkill -f nexus_server.py    ${PURPLE}║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Termux'ta tarayıcı açmak için:${NC}"
echo -e "${YELLOW}  termux-open-url http://localhost:${PORT}/${NC}"
echo ""

# Auto-open if termux-open-url available
if command -v termux-open-url &>/dev/null; then
    echo -e "${GREEN}[+] Tarayıcı açılıyor...${NC}"
    sleep 1
    termux-open-url "http://localhost:${PORT}/"
fi

# Keep alive
echo -e "${CYAN}[i] Çıkmak için Ctrl+C${NC}"
trap "echo -e '\n${RED}[!] NEXUS kapatıldı.${NC}'; kill $SERVER_PID 2>/dev/null; exit 0" INT TERM
wait $SERVER_PID
