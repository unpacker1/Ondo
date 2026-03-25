from flask import Flask,render_template_string,jsonify import random import threading import time import requests import xml.etree.ElementTree as ET

app = Flask(name)

-----------------------------

News store (categorized + scored)

-----------------------------

data_store = { "news": {} }

NEWS_SOURCES = [ "https://news.google.com/rss?hl=tr&gl=TR&ceid=TR:tr", "https://feeds.bbci.co.uk/news/rss.xml", "https://rss.nytimes.com/services/xml/rss/nyt/World.xml", "https://rss.cnn.com/rss/edition.rss", "https://www.aljazeera.com/xml/rss/all.xml", "https://www.theguardian.com/world/rss", "https://www.reuters.com/world/rss", "https://www.hurriyet.com.tr/rss/anasayfa", "https://www.sabah.com.tr/rss/gundem.xml" ]

-----------------------------

Categorization

-----------------------------

def categorize(title): t = title.lower()

if any(k in t for k in ["economy", "ekonomi", "finance", "market", "dolar", "euro", "faiz"]):
    return "Economy"
elif any(k in t for k in ["sport", "football", "basketball", "spor", "maç"]):
    return "Sports"
elif any(k in t for k in ["technology", "tech", "ai", "yazılım", "teknoloji"]):
    return "Technology"
elif any(k in t for k in ["turkey", "türkiye", "istanbul", "ankara", "kayseri"]):
    return "Turkey"
elif any(k in t for k in ["world", "global", "usa", "uk", "china", "russia"]):
    return "World"
else:
    return "Other"

-----------------------------

Critical scoring algorithm

-----------------------------

def score(title): t = title.lower() s = 0

keywords = {
    "war": 5, "attack": 5, "crisis": 4, "breaking": 5,
    "earthquake": 5, "deprem": 5, "explosion": 5,
    "president": 3, "government": 3, "policy": 2,
    "economy": 3, "inflation": 4, "faiz": 4,
    "bitcoin": 3, "ai": 3, "technology": 2
}

for k, v in keywords.items():
    if k in t:
        s += v

# extra boost for uppercase / breaking style headlines
if "breaking" in t:
    s += 5

return s

-----------------------------

Fetch live news

-----------------------------

def fetch_news(): while True: categorized = { "World": [], "Turkey": [], "Technology": [], "Economy": [], "Sports": [], "Other": [] }

for url in NEWS_SOURCES:
        try:
            res = requests.get(url, timeout=5)
            root = ET.fromstring(res.content)

            for item in root.findall("./channel/item")[:10]:
                title_el = item.find("title")
                date_el = item.find("pubDate")

                title = title_el.text if title_el is not None else ""
                date = date_el.text if date_el is not None else ""

                cat = categorize(title)
                s = score(title)

                categorized[cat].append({
                    "title": title,
                    "date": date,
                    "score": s
                })

        except Exception as e:
            categorized["Other"].append({
                "title": f"Kaynak hatası: {str(e)}",
                "date": url,
                "score": 0
            })

    # Sort each category by score (critical first)
    for cat in categorized:
        categorized[cat] = sorted(categorized[cat], key=lambda x: x["score"], reverse=True)

    data_store["news"] = categorized
    time.sleep(10)  # faster refresh for near real-time feel

threading.Thread(target=fetch_news, daemon=True).start()

-----------------------------

UI

-----------------------------

HTML_PAGE = """

<!DOCTYPE html><html>
<head>
    <title>Termux News Panel</title>
    <style>
        body {
            background: #0f172a;
            color: #e2e8f0;
            font-family: Arial;
            margin: 0;
            padding: 20px;
        }
        .card {
            background: #1e293b;
            padding: 20px;
            border-radius: 12px;
            max-width: 900px;
            margin: auto;
        }
        .category {
            margin-top: 20px;
        }
        .category h2 {
            border-bottom: 1px solid #334155;
            padding-bottom: 5px;
        }
        .news-item {
            padding: 8px 0;
            border-bottom: 1px solid #334155;
        }
        .critical {
            color: #f87171;
            font-weight: bold;
        }
        .title {
            font-size: 14px;
        }
        .date {
            font-size: 12px;
            color: #94a3b8;
        }
        .score {
            font-size: 11px;
            color: #38bdf8;
        }
    </style>
</head>
<body><div class="card">
    <h1>📰 Kritik + Canlı Haberler</h1>
    <div id="news">Yükleniyor...</div>
</div><script>
async function loadNews() {
    const res = await fetch('/news');
    const data = await res.json();

    const container = document.getElementById("news");
    container.innerHTML = "";

    for (const category in data.news) {
        const section = document.createElement("div");
        section.className = "category";

        const title = document.createElement("h2");
        title.innerText = category;
        section.appendChild(title);

        data.news[category].forEach(item => {
            const div = document.createElement("div");
            div.className = "news-item";

            const isCritical = item.score >= 6;

            div.innerHTML =
                "<div class='title " + (isCritical ? "critical" : "") + "'>" + item.title + "</div>" +
                "<div class='date'>" + item.date + "</div>" +
                "<div class='score'>Score: " + item.score + "</div>";

            section.appendChild(div);
        });

        container.appendChild(section);
    }
}

loadNews();
setInterval(loadNews, 10000);
</script></body>
</html>
"""@app.route("/") def index(): return render_template_string(HTML_PAGE)

@app.route("/news") def get_news(): return jsonify(data_store)

if name == "main": port = random.randint(5000, 9000) print(f"Server running on http://127.0.0.1:{port}") app.run(host="0.0.0.0", port=port)