from flask import Flask
import threading
import os
import time
import numpy as np
from PIL import Image

app = Flask(__name__)

BOT_RUNNING = False
MODE = "auto"

# ----------------
# TOUCH
# ----------------
def tap(x, y):
    os.system(f"input tap {x} {y}")

# ----------------
# SCREENSHOT
# ----------------
def screenshot():
    os.system("screencap -p /sdcard/screen.png")
    img = np.array(Image.open("/sdcard/screen.png"))
    return img

# ----------------
# BASİT ANALİZ (AI yerine hafif sistem)
# ----------------
def analyze(img):
    # parlaklık ortalaması (çok basit ama hızlı)
    brightness = np.mean(img)

    if brightness > 180:
        return "upgrade"
    elif brightness > 130:
        return "build"
    else:
        return "farm"

# ----------------
# BOT LOOP
# ----------------
def bot_loop():
    global BOT_RUNNING, MODE

    print("LITE BOT BASLADI")

    while BOT_RUNNING:
        img = screenshot()

        if MODE == "auto":
            action = analyze(img)
        else:
            action = MODE

        print("MODE:", action)

        if action == "build":
            tap(500, 1800)
            time.sleep(0.3)
            tap(800, 1000)

        elif action == "upgrade":
            tap(800, 1000)
            time.sleep(0.3)
            tap(900, 1700)

        elif action == "farm":
            for _ in range(5):
                tap(700, 1200)
                time.sleep(0.1)

        time.sleep(1)

    print("BOT DURDU")

# ----------------
# WEB PANEL
# ----------------
@app.route("/")
def home():
    return """
    <h2>LITE BOT PANEL</h2>
    <a href="/start">START</a><br>
    <a href="/stop">STOP</a><br><br>

    <a href="/mode/auto">AUTO</a><br>
    <a href="/mode/build">BUILD</a><br>
    <a href="/mode/upgrade">UPGRADE</a><br>
    <a href="/mode/farm">FARM</a><br>
    """

@app.route("/start")
def start():
    global BOT_RUNNING
    if not BOT_RUNNING:
        BOT_RUNNING = True
        threading.Thread(target=bot_loop).start()
    return "BOT STARTED"

@app.route("/stop")
def stop():
    global BOT_RUNNING
    BOT_RUNNING = False
    return "BOT STOPPED"

@app.route("/mode/<m>")
def mode(m):
    global MODE
    MODE = m
    return f"MODE: {m}"

# ----------------
# RUN
# ----------------
app.run(host="0.0.0.0", port=5000)