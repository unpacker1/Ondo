from flask import Flask, request
import threading
import os
import time
import cv2
import numpy as np

app = Flask(__name__)

BOT_RUNNING = False
MODE = "auto"  # auto / farm / build / stop

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
    return cv2.imread("/sdcard/screen.png")

# ----------------
# BASİT AI
# ----------------
def analyze(img):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(gray, 100, 200)

    yoğunluk = np.count_nonzero(edges)

    if yoğunluk > 25000:
        return "upgrade"
    elif yoğunluk > 10000:
        return "build"
    else:
        return "farm"

# ----------------
# BOT LOOP
# ----------------
def bot_loop():
    global BOT_RUNNING, MODE

    print("BOT BASLADI")

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
    <h2>BOT PANEL</h2>
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