from flask import Flask, render_template_string, jsonify
import random
import threading
import time
import requests
import xml.etree.ElementTree as ET

app = Flask(__name__)

data_store = {
    "news": []
}

def fetch_news():
    while True:
        try:
            url = "https://news.google.com/rss?hl=tr&gl=TR&ceid=TR:tr"
            res = requests.get(url, timeout=5)

            root = ET.fromstring(res.content)
            items = []

            for item in root.findall("./channel/item")[:20]:
                title_el = item.find("title")
                date_el = item.find("pubDate")

                title = title_el.text if title_el is not None else ""
                date = date_el.text if date_el is not None else ""

                items.append({
                    "title": title,
                    "date": date
                })

            data_store["news"] = items

        except Exception as e:
            data_store["news"] = [{"title": f"Hata: {str(e)}", "date": ""}]

        time.sleep(60)

threading.Thread(target=fetch_news, daemon=True).start()

HTML_PAGE = """
<!DOCTYPE html>
<html>
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
            max-width: 800px;
            margin: auto;
        }
        .news-item {
            border-bottom: 1px solid #334155;
            padding: 10px 0;
        }
        .title {
            font-size: 16px;
        }
        .date {
            font-size: 12px;
            color: #94a3b8;
        }
    </style>
</head>
<body>

<div class="card">
    <h1>📰 Canlı Haberler</h1>
    <div id="news">Yükleniyor...</div>
</div>

<script>
    async function loadNews() {
        const res = await fetch('/news');
        const data = await res.json();

        const container = document.getElementById("news");
        container.innerHTML = "";

        data.news.forEach(item => {
            const div = document.createElement("div");
            div.className = "news-item";

            div.innerHTML =
                "<div class='title'>" + item.title + "</div>" +
                "<div class='date'>" + item.date + "</div>";

            container.appendChild(div);
        });
    }

    loadNews();
    setInterval(loadNews, 60000);
</script>

</body>
</html>
"""

@app.route("/")
def index():
    return render_template_string(HTML_PAGE)

@app.route("/news")
def get_news():
    return jsonify(data_store)

if __name__ == "__main__":
    port = random.randint(5000, 9000)
    print(f"Server running on http://127.0.0.1:{port}")
    app.run(host="0.0.0.0", port=port)