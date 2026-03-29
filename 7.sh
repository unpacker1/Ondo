#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║          PHANTOM OSINT PANEL — Termux Single-File           ║
# ║     Tüm OSINT kaynakları tek panelde — Cyberpunk HUD        ║
# ╚══════════════════════════════════════════════════════════════╝

# --- Bağımlılık kontrolü ---
for cmd in python3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "[!] $cmd bulunamadı. Yükleniyor..."
    pkg install python -y
  fi
done

# --- Random port seç ---
PORT=$((RANDOM % 40000 + 10000))
TMPDIR_PHANTOM=$(mktemp -d)
HTML_FILE="$TMPDIR_PHANTOM/index.html"

echo ""
echo "  ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗████████╗ ██████╗ ███╗   ███╗"
echo "  ██╔══██╗██║  ██║██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗████╗ ████║"
echo "  ██████╔╝███████║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║"
echo "  ██╔═══╝ ██╔══██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║"
echo "  ██║     ██║  ██║██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║"
echo "  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝"
echo ""
echo "  ╔═══════════════════════════════════════════════╗"
echo "  ║         PHANTOM OSINT INTELLIGENCE PANEL      ║"
echo "  ╚═══════════════════════════════════════════════╝"
echo ""
echo "  [*] Port: $PORT"
echo "  [*] URL: http://localhost:$PORT"
echo "  [*] Panel başlatılıyor..."
echo "  [!] Çıkmak için CTRL+C"
echo ""

# --- HTML dosyasını oluştur ---
cat > "$HTML_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>PHANTOM OSINT PANEL</title>
<link href="https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;700;900&family=Rajdhani:wght@300;400;600;700&display=swap" rel="stylesheet">
<style>
  :root {
    --cyan: #00fff7;
    --magenta: #ff00aa;
    --gold: #ffd700;
    --green: #00ff88;
    --red: #ff3355;
    --bg: #020a0f;
    --panel: rgba(0,255,247,0.04);
    --border: rgba(0,255,247,0.15);
    --text: #a0d8e0;
    --dim: rgba(0,255,247,0.5);
  }

  * { margin:0; padding:0; box-sizing:border-box; }
  html, body { height:100%; overflow:hidden; background:var(--bg); font-family:'Share Tech Mono',monospace; color:var(--text); }

  /* ─── SCANLINE OVERLAY ─── */
  body::before {
    content:''; position:fixed; inset:0; pointer-events:none; z-index:9999;
    background: repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0,0,0,0.08) 2px, rgba(0,0,0,0.08) 4px);
    animation: scanMove 8s linear infinite;
  }
  @keyframes scanMove { from{background-position:0 0} to{background-position:0 100%} }

  /* ─── GRID BACKGROUND ─── */
  body::after {
    content:''; position:fixed; inset:0; pointer-events:none; z-index:0;
    background-image:
      linear-gradient(rgba(0,255,247,0.03) 1px, transparent 1px),
      linear-gradient(90deg, rgba(0,255,247,0.03) 1px, transparent 1px);
    background-size: 40px 40px;
  }

  /* ══════════════════════ LOGIN SCREEN ══════════════════════ */
  #login-screen {
    position:fixed; inset:0; z-index:1000;
    display:flex; align-items:center; justify-content:center;
    background: radial-gradient(ellipse at center, rgba(0,20,30,0.98) 0%, #020a0f 100%);
    transition: opacity 0.8s ease, visibility 0.8s;
  }
  #login-screen.hidden { opacity:0; visibility:hidden; }

  .login-box {
    width: min(460px, 92vw);
    border: 1px solid var(--cyan);
    background: rgba(0,10,15,0.95);
    padding: 48px 40px;
    position:relative;
    box-shadow: 0 0 60px rgba(0,255,247,0.12), inset 0 0 30px rgba(0,255,247,0.03);
  }
  .login-box::before, .login-box::after {
    content:''; position:absolute; width:20px; height:20px; border-color:var(--magenta); border-style:solid;
  }
  .login-box::before { top:-1px; left:-1px; border-width:2px 0 0 2px; }
  .login-box::after  { bottom:-1px; right:-1px; border-width:0 2px 2px 0; }

  .login-logo {
    text-align:center; margin-bottom:36px;
  }
  .login-logo .logo-text {
    font-family:'Orbitron',sans-serif; font-size:28px; font-weight:900;
    color:var(--cyan); letter-spacing:6px; text-shadow:0 0 20px var(--cyan), 0 0 40px var(--cyan);
    display:block; margin-bottom:6px;
  }
  .login-logo .logo-sub {
    font-size:11px; letter-spacing:4px; color:var(--magenta);
    text-shadow:0 0 10px var(--magenta);
  }
  .login-logo .logo-eye {
    font-size:48px; display:block; margin-bottom:12px;
    filter: drop-shadow(0 0 12px var(--cyan));
    animation: eyePulse 3s ease-in-out infinite;
  }
  @keyframes eyePulse { 0%,100%{filter:drop-shadow(0 0 8px var(--cyan))} 50%{filter:drop-shadow(0 0 24px var(--cyan)) drop-shadow(0 0 40px var(--magenta))} }

  .login-label { font-size:11px; letter-spacing:3px; color:var(--dim); margin-bottom:8px; display:block; }
  .login-input {
    width:100%; padding:12px 16px; margin-bottom:20px;
    background:rgba(0,255,247,0.04); border:1px solid var(--border);
    color:var(--cyan); font-family:'Share Tech Mono',monospace; font-size:14px;
    outline:none; transition:all 0.3s; letter-spacing:2px;
  }
  .login-input:focus { border-color:var(--cyan); box-shadow:0 0 20px rgba(0,255,247,0.15); background:rgba(0,255,247,0.07); }
  .login-input::placeholder { color:rgba(0,255,247,0.2); }

  .login-btn {
    width:100%; padding:14px; margin-top:8px;
    background:transparent; border:1px solid var(--cyan);
    color:var(--cyan); font-family:'Orbitron',sans-serif; font-size:13px;
    letter-spacing:4px; cursor:pointer; position:relative; overflow:hidden;
    transition:all 0.3s;
  }
  .login-btn::before {
    content:''; position:absolute; top:0; left:-100%; width:100%; height:100%;
    background:linear-gradient(90deg, transparent, rgba(0,255,247,0.15), transparent);
    transition:left 0.4s;
  }
  .login-btn:hover::before { left:100%; }
  .login-btn:hover { background:rgba(0,255,247,0.08); box-shadow:0 0 30px rgba(0,255,247,0.2); text-shadow:0 0 10px var(--cyan); }

  .login-status { height:20px; margin-top:16px; text-align:center; font-size:11px; letter-spacing:2px; }
  .login-status.err { color:var(--red); }
  .login-status.ok  { color:var(--green); }

  .login-hints { margin-top:28px; border-top:1px solid var(--border); padding-top:20px; font-size:11px; color:rgba(0,255,247,0.3); letter-spacing:1px; }
  .login-hints span { color:var(--gold); }

  /* ══════════════════════ MAIN PANEL ══════════════════════ */
  #main-panel { display:flex; flex-direction:column; height:100vh; position:relative; z-index:1; }

  /* ─── TOP BAR ─── */
  .topbar {
    display:flex; align-items:center; justify-content:space-between;
    padding:10px 20px; border-bottom:1px solid var(--border);
    background:rgba(0,10,15,0.9); backdrop-filter:blur(10px);
    flex-shrink:0;
  }
  .topbar-logo { font-family:'Orbitron',sans-serif; font-size:16px; font-weight:900; color:var(--cyan); letter-spacing:4px; text-shadow:0 0 15px var(--cyan); }
  .topbar-logo span { color:var(--magenta); }
  .topbar-status { display:flex; gap:16px; align-items:center; font-size:11px; }
  .status-dot { width:8px; height:8px; border-radius:50%; animation:blink 2s infinite; }
  .status-dot.online { background:var(--green); box-shadow:0 0 6px var(--green); }
  @keyframes blink { 0%,100%{opacity:1} 50%{opacity:0.3} }
  .topbar-clock { font-size:12px; color:var(--gold); letter-spacing:2px; }
  .topbar-user { font-size:11px; color:var(--magenta); letter-spacing:2px; }

  /* ─── LAYOUT ─── */
  .layout { display:flex; flex:1; overflow:hidden; }

  /* ─── SIDEBAR ─── */
  .sidebar {
    width:220px; flex-shrink:0; border-right:1px solid var(--border);
    background:rgba(0,5,10,0.8); overflow-y:auto; padding:12px 0;
    scrollbar-width:thin; scrollbar-color:var(--border) transparent;
  }
  .sidebar-section { margin-bottom:6px; }
  .sidebar-cat {
    padding:8px 16px; font-size:10px; letter-spacing:3px; color:var(--magenta);
    text-transform:uppercase; opacity:0.7; display:flex; align-items:center; gap:8px;
  }
  .sidebar-cat::after { content:''; flex:1; height:1px; background:var(--border); }
  .sidebar-item {
    display:flex; align-items:center; gap:10px;
    padding:9px 16px 9px 20px; cursor:pointer;
    font-size:12px; letter-spacing:1px; color:var(--text);
    transition:all 0.2s; position:relative;
  }
  .sidebar-item:hover { background:rgba(0,255,247,0.06); color:var(--cyan); }
  .sidebar-item.active { background:rgba(0,255,247,0.1); color:var(--cyan); }
  .sidebar-item.active::before { content:''; position:absolute; left:0; top:0; bottom:0; width:2px; background:var(--cyan); box-shadow:0 0 8px var(--cyan); }
  .sidebar-icon { font-size:14px; flex-shrink:0; }
  .sidebar-count { margin-left:auto; font-size:10px; background:rgba(0,255,247,0.1); color:var(--cyan); padding:2px 7px; border-radius:2px; border:1px solid var(--border); }

  /* ─── CONTENT AREA ─── */
  .content { flex:1; overflow:hidden; display:flex; flex-direction:column; }

  /* ─── SEARCH BAR ─── */
  .search-bar {
    padding:14px 20px; border-bottom:1px solid var(--border);
    background:rgba(0,5,10,0.6); display:flex; gap:12px; align-items:center; flex-shrink:0;
  }
  .search-input {
    flex:1; padding:10px 16px; background:rgba(0,255,247,0.04);
    border:1px solid var(--border); color:var(--cyan);
    font-family:'Share Tech Mono',monospace; font-size:13px; outline:none;
    transition:all 0.3s; letter-spacing:1px;
  }
  .search-input:focus { border-color:var(--cyan); box-shadow:0 0 15px rgba(0,255,247,0.1); }
  .search-input::placeholder { color:rgba(0,255,247,0.25); }
  .search-btn {
    padding:10px 20px; background:rgba(0,255,247,0.08); border:1px solid var(--cyan);
    color:var(--cyan); font-family:'Orbitron',sans-serif; font-size:11px;
    letter-spacing:2px; cursor:pointer; transition:all 0.2s; white-space:nowrap;
  }
  .search-btn:hover { background:rgba(0,255,247,0.15); box-shadow:0 0 15px rgba(0,255,247,0.2); }
  .filter-select {
    padding:10px 12px; background:rgba(0,255,247,0.04); border:1px solid var(--border);
    color:var(--text); font-family:'Share Tech Mono',monospace; font-size:12px; outline:none;
  }
  .filter-select option { background:#020a0f; }

  /* ─── CARDS GRID ─── */
  .cards-container { flex:1; overflow-y:auto; padding:20px; scrollbar-width:thin; scrollbar-color:var(--border) transparent; }

  .category-header {
    display:flex; align-items:center; gap:14px;
    margin-bottom:16px; margin-top:4px;
  }
  .category-header h2 {
    font-family:'Orbitron',sans-serif; font-size:13px; letter-spacing:3px;
    color:var(--cyan); text-shadow:0 0 10px rgba(0,255,247,0.5);
  }
  .category-header .cat-line { flex:1; height:1px; background:linear-gradient(90deg,var(--border),transparent); }
  .category-header .cat-icon { font-size:18px; }
  .cat-count-badge { font-size:11px; padding:2px 8px; border:1px solid var(--magenta); color:var(--magenta); border-radius:2px; }

  .cards-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(280px,1fr)); gap:14px; margin-bottom:32px; }

  .card {
    border:1px solid var(--border); background:var(--panel);
    padding:18px 20px; cursor:pointer; position:relative; overflow:hidden;
    transition:all 0.25s; group:true;
    animation: cardIn 0.4s ease both;
  }
  @keyframes cardIn { from{opacity:0;transform:translateY(10px)} to{opacity:1;transform:translateY(0)} }
  .card::before {
    content:''; position:absolute; top:0; left:0; right:0; height:1px;
    background:linear-gradient(90deg,transparent,var(--cyan),transparent);
    opacity:0; transition:opacity 0.3s;
  }
  .card:hover { border-color:rgba(0,255,247,0.4); background:rgba(0,255,247,0.07); transform:translateY(-2px); box-shadow:0 8px 30px rgba(0,0,0,0.4), 0 0 20px rgba(0,255,247,0.08); }
  .card:hover::before { opacity:1; }

  .card-top { display:flex; align-items:flex-start; justify-content:space-between; margin-bottom:10px; }
  .card-icon { font-size:22px; }
  .card-badges { display:flex; gap:6px; flex-wrap:wrap; }
  .badge {
    font-size:9px; letter-spacing:2px; padding:2px 7px; border-radius:1px;
    font-family:'Orbitron',sans-serif;
  }
  .badge-free { border:1px solid var(--green); color:var(--green); }
  .badge-paid { border:1px solid var(--gold); color:var(--gold); }
  .badge-api  { border:1px solid var(--magenta); color:var(--magenta); }
  .badge-tor  { border:1px solid #9b59b6; color:#9b59b6; }

  .card-title { font-family:'Rajdhani',sans-serif; font-size:16px; font-weight:700; color:#e0f8ff; margin-bottom:4px; letter-spacing:1px; }
  .card-desc  { font-size:11px; color:rgba(160,216,224,0.7); line-height:1.6; margin-bottom:14px; }

  .card-footer { display:flex; align-items:center; justify-content:space-between; }
  .card-link {
    font-size:10px; letter-spacing:2px; color:var(--cyan); text-decoration:none;
    border:1px solid var(--border); padding:5px 12px;
    transition:all 0.2s; display:inline-flex; align-items:center; gap:6px;
  }
  .card-link:hover { border-color:var(--cyan); background:rgba(0,255,247,0.1); box-shadow:0 0 10px rgba(0,255,247,0.15); }
  .card-cat-tag { font-size:9px; color:var(--dim); letter-spacing:2px; }

  /* ─── STATS BAR ─── */
  .statsbar {
    padding:8px 20px; border-top:1px solid var(--border);
    background:rgba(0,5,10,0.9); display:flex; gap:24px; align-items:center;
    flex-shrink:0; font-size:11px; letter-spacing:1px;
  }
  .stat-item { display:flex; gap:6px; align-items:center; }
  .stat-val { color:var(--cyan); font-weight:bold; }
  .stat-label { color:rgba(160,216,224,0.4); }

  /* ─── TOOL MODAL ─── */
  .modal-overlay { position:fixed; inset:0; z-index:500; background:rgba(0,0,0,0.85); display:flex; align-items:center; justify-content:center; opacity:0; visibility:hidden; transition:all 0.3s; }
  .modal-overlay.open { opacity:1; visibility:visible; }
  .modal {
    width:min(600px,95vw); border:1px solid var(--cyan);
    background:rgba(2,10,15,0.98); padding:32px; position:relative;
    box-shadow:0 0 60px rgba(0,255,247,0.15);
    animation:modalIn 0.3s ease;
  }
  @keyframes modalIn { from{transform:scale(0.9) translateY(20px)} to{transform:scale(1) translateY(0)} }
  .modal-close { position:absolute; top:16px; right:16px; background:none; border:none; color:var(--dim); font-size:20px; cursor:pointer; transition:color 0.2s; }
  .modal-close:hover { color:var(--red); }
  .modal-title { font-family:'Orbitron',sans-serif; font-size:18px; color:var(--cyan); margin-bottom:6px; text-shadow:0 0 15px var(--cyan); }
  .modal-url { font-size:12px; color:var(--magenta); margin-bottom:20px; letter-spacing:1px; }
  .modal-desc { font-size:13px; color:var(--text); line-height:1.8; margin-bottom:24px; }
  .modal-tags { display:flex; gap:8px; flex-wrap:wrap; margin-bottom:24px; }
  .modal-tag { font-size:10px; padding:3px 10px; border:1px solid var(--border); color:var(--dim); letter-spacing:2px; }
  .modal-actions { display:flex; gap:12px; }
  .modal-btn {
    padding:12px 24px; border:1px solid var(--cyan); background:rgba(0,255,247,0.06);
    color:var(--cyan); font-family:'Orbitron',sans-serif; font-size:11px;
    letter-spacing:2px; cursor:pointer; text-decoration:none; display:inline-block;
    transition:all 0.2s;
  }
  .modal-btn:hover { background:rgba(0,255,247,0.15); box-shadow:0 0 20px rgba(0,255,247,0.2); }
  .modal-btn.secondary { border-color:var(--border); color:var(--dim); }
  .modal-btn.secondary:hover { border-color:var(--magenta); color:var(--magenta); }

  /* ─── SCROLLBAR ─── */
  ::-webkit-scrollbar { width:4px; }
  ::-webkit-scrollbar-track { background:transparent; }
  ::-webkit-scrollbar-thumb { background:var(--border); }
  ::-webkit-scrollbar-thumb:hover { background:var(--dim); }

  /* ─── FAVORITES STAR ─── */
  .fav-btn { background:none; border:none; cursor:pointer; font-size:14px; opacity:0.4; transition:all 0.2s; }
  .fav-btn:hover, .fav-btn.active { opacity:1; filter:drop-shadow(0 0 6px var(--gold)); }

  /* ─── RESPONSIVE ─── */
  @media(max-width:600px) {
    .sidebar { display:none; }
    .cards-grid { grid-template-columns:1fr; }
  }
</style>
</head>
<body>

<!-- ══════════════════ LOGIN SCREEN ══════════════════ -->
<div id="login-screen">
  <div class="login-box">
    <div class="login-logo">
      <span class="logo-eye">👁</span>
      <span class="logo-text">PHANTOM</span>
      <span class="logo-sub">OSINT INTELLIGENCE PANEL v2.0</span>
    </div>

    <label class="login-label">ACCESS CODE</label>
    <input class="login-input" type="text" id="login-user" placeholder="operator_id" autocomplete="off" spellcheck="false">

    <label class="login-label">CIPHER KEY</label>
    <input class="login-input" type="password" id="login-pass" placeholder="••••••••" autocomplete="off">

    <button class="login-btn" onclick="doLogin()">▶ AUTHENTICATE</button>
    <div class="login-status" id="login-status"></div>

    <div class="login-hints">
      <div>DEFAULT: <span>phantom</span> / <span>osint2024</span></div>
      <div style="margin-top:6px">GUEST: <span>guest</span> / <span>guest</span></div>
    </div>
  </div>
</div>

<!-- ══════════════════ MAIN PANEL ══════════════════ -->
<div id="main-panel" style="display:none">
  <!-- TOP BAR -->
  <div class="topbar">
    <div class="topbar-logo">PH<span>ANT</span>OM <span style="color:var(--gold);font-size:12px;letter-spacing:2px">OSINT</span></div>
    <div class="topbar-status">
      <div class="status-dot online"></div>
      <span style="color:var(--green);font-size:11px;letter-spacing:2px">ONLINE</span>
      <span class="topbar-clock" id="clock">--:--:--</span>
    </div>
    <div class="topbar-user" id="top-user">◈ OPERATOR</div>
  </div>

  <div class="layout">
    <!-- SIDEBAR -->
    <div class="sidebar" id="sidebar"></div>

    <!-- CONTENT -->
    <div class="content">
      <div class="search-bar">
        <input class="search-input" id="search-input" placeholder="🔍  OSINT araç veya URL ara..." oninput="filterCards()">
        <select class="filter-select" id="filter-type" onchange="filterCards()">
          <option value="all">TÜM TIPLER</option>
          <option value="free">ÜCRETSİZ</option>
          <option value="paid">ÜCRETLI</option>
          <option value="api">API</option>
          <option value="tor">TOR</option>
        </select>
        <button class="search-btn" onclick="filterCards()">⚡ TARA</button>
      </div>

      <div class="cards-container" id="cards-container"></div>

      <div class="statsbar">
        <div class="stat-item"><span class="stat-val" id="stat-total">0</span><span class="stat-label">TOPLAM ARAÇ</span></div>
        <div class="stat-item"><span class="stat-val" id="stat-shown">0</span><span class="stat-label">GÖRÜNTÜLENEN</span></div>
        <div class="stat-item"><span class="stat-val" id="stat-cats">0</span><span class="stat-label">KATEGORİ</span></div>
        <div class="stat-item"><span class="stat-val" id="stat-favs">0</span><span class="stat-label">FAVORİ</span></div>
        <div style="margin-left:auto;color:var(--dim);font-size:10px;letter-spacing:2px">PHANTOM OSINT PANEL</div>
      </div>
    </div>
  </div>
</div>

<!-- MODAL -->
<div class="modal-overlay" id="modal-overlay" onclick="closeModal(event)">
  <div class="modal" id="modal-box">
    <button class="modal-close" onclick="closeModal()">✕</button>
    <div class="modal-title" id="m-title"></div>
    <div class="modal-url" id="m-url"></div>
    <div class="modal-desc" id="m-desc"></div>
    <div class="modal-tags" id="m-tags"></div>
    <div class="modal-actions">
      <a class="modal-btn" id="m-link" href="#" target="_blank" rel="noopener">⬡ SİTEYE GİT</a>
      <button class="modal-btn secondary" onclick="closeModal()">◁ KAPAT</button>
    </div>
  </div>
</div>

<script>
// ══════════════════════════════════════════════
// OSINT VERİTABANI — 100+ Araç
// ══════════════════════════════════════════════
const OSINT_DATA = [
  // ── KİŞİ & KİMLİK ──
  { id:1, cat:"KİŞİ & KİMLİK", icon:"👤", name:"Pipl", url:"https://pipl.com", desc:"Dünyanın en kapsamlı kişi arama motoru. E-posta, isim, telefon ve sosyal medya üzerinden detaylı profil.", tags:["kişi","arama","sosyal","e-posta"], types:["paid"] },
  { id:2, cat:"KİŞİ & KİMLİK", icon:"👤", name:"Spokeo", url:"https://spokeo.com", desc:"ABD odaklı kişi arama; adres, telefon, e-posta ve sosyal medya bağlantıları.", tags:["kişi","adres","telefon"], types:["paid"] },
  { id:3, cat:"KİŞİ & KİMLİK", icon:"👤", name:"TruthFinder", url:"https://truthfinder.com", desc:"Arka plan kontrolü, suç sicili, aile kayıtları. ABD vatandaşları için.", tags:["arka plan","sicil"], types:["paid"] },
  { id:4, cat:"KİŞİ & KİMLİK", icon:"👤", name:"Intelius", url:"https://intelius.com", desc:"Adres, telefon, e-posta, suç sicili ve aile üyeleri dahil kişi raporları.", tags:["rapor","adres"], types:["paid"] },
  { id:5, cat:"KİŞİ & KİMLİK", icon:"👤", name:"Whitepages", url:"https://whitepages.com", desc:"Telefon, adres ve kişi bilgisi sorgulama. Temel arama ücretsiz.", tags:["telefon","adres"], types:["free","paid"] },
  { id:6, cat:"KİŞİ & KİMLİK", icon:"👤", name:"411.com", url:"https://411.com", desc:"ABD telefon defteri ve kişi arama hizmeti.", tags:["telefon","kişi"], types:["free"] },
  { id:7, cat:"KİŞİ & KİMLİK", icon:"👤", name:"ZabaSearch", url:"https://zabasearch.com", desc:"Ücretsiz kişi arama; isim, şehir, eyalet bazlı.", tags:["kişi","ücretsiz"], types:["free"] },

  // ── SOSYAL MEDYA ──
  { id:8, cat:"SOSYAL MEDYA", icon:"📱", name:"Sherlock", url:"https://github.com/sherlock-project/sherlock", desc:"Kullanıcı adını 300+ platformda sorgulayan açık kaynak araç. Python tabanlı.", tags:["kullanıcı adı","platform"], types:["free"] },
  { id:9, cat:"SOSYAL MEDYA", icon:"📱", name:"WhatsMyName", url:"https://whatsmyname.app", desc:"Kullanıcı adı araması — 500+ site, anlık sonuç, tarayıcı üzerinde.", tags:["kullanıcı adı","tarayıcı"], types:["free"] },
  { id:10, cat:"SOSYAL MEDYA", icon:"📱", name:"Social-Searcher", url:"https://social-searcher.com", desc:"Gerçek zamanlı sosyal medya izleme. Twitter, Facebook, Instagram, Reddit.", tags:["izleme","anahtar kelime"], types:["free","paid"] },
  { id:11, cat:"SOSYAL MEDYA", icon:"📱", name:"Namechk", url:"https://namechk.com", desc:"Kullanıcı adı ve alan adı müsaitlik kontrolü, 100+ platform.", tags:["kullanıcı adı","alan"], types:["free"] },
  { id:12, cat:"SOSYAL MEDYA", icon:"📱", name:"IntelX Social", url:"https://intelx.io", desc:"Sosyal medya, dark web ve veri sızıntılarını tek arayüzde tarayan premium araç.", tags:["dark web","sızıntı","sosyal"], types:["paid","api"] },
  { id:13, cat:"SOSYAL MEDYA", icon:"📱", name:"Mention", url:"https://mention.com", desc:"Marka ve kişi izleme; sosyal medya, haber ve blog takibi.", tags:["marka","izleme"], types:["paid"] },
  { id:14, cat:"SOSYAL MEDYA", icon:"📱", name:"TweetDeck", url:"https://tweetdeck.twitter.com", desc:"Twitter/X için gelişmiş izleme ve arama aracı.", tags:["twitter","x","izleme"], types:["free"] },
  { id:15, cat:"SOSYAL MEDYA", icon:"📱", name:"Aware Online", url:"https://www.aware-online.com/osint-tools", desc:"Sosyal medya OSINT araçları koleksiyonu ve kursları.", tags:["koleksiyon","kurs"], types:["free"] },

  // ── E-POSTA & KULLANICI ──
  { id:16, cat:"E-POSTA & KULLANICI", icon:"✉️", name:"Hunter.io", url:"https://hunter.io", desc:"Alan adına bağlı e-posta adreslerini bul, doğrula ve çıkar.", tags:["e-posta","alan adı","doğrulama"], types:["free","api"] },
  { id:17, cat:"E-POSTA & KULLANICI", icon:"✉️", name:"EmailRep", url:"https://emailrep.io", desc:"E-posta itibar skoru; spam, phishing, breach geçmişi.", tags:["itibar","spam","ihlal"], types:["free","api"] },
  { id:18, cat:"E-POSTA & KULLANICI", icon:"✉️", name:"HaveIBeenPwned", url:"https://haveibeenpwned.com", desc:"E-posta adresinin veri ihlallerine dahil olup olmadığını kontrol et.", tags:["ihlal","şifre","sızıntı"], types:["free","api"] },
  { id:19, cat:"E-POSTA & KULLANICI", icon:"✉️", name:"Epieos", url:"https://epieos.com", desc:"E-posta veya telefon ile Google ve sosyal medya hesaplarını bul.", tags:["google","hesap","telefon"], types:["free"] },
  { id:20, cat:"E-POSTA & KULLANICI", icon:"✉️", name:"Holehe", url:"https://github.com/megadose/holehe", desc:"E-posta adresinin hangi sitelere kayıtlı olduğunu test eder (Python).", tags:["kayıt","site"], types:["free"] },
  { id:21, cat:"E-POSTA & KULLANICI", icon:"✉️", name:"Snov.io", url:"https://snov.io", desc:"E-posta bulma, doğrulama ve soğuk e-posta otomasyonu.", tags:["bulma","doğrulama"], types:["paid","api"] },
  { id:22, cat:"E-POSTA & KULLANICI", icon:"✉️", name:"Clearbit", url:"https://clearbit.com", desc:"E-posta üzerinden şirket ve kişi bilgisi zenginleştirme API'si.", tags:["zenginleştirme","şirket"], types:["paid","api"] },

  // ── TELEFON & SMS ──
  { id:23, cat:"TELEFON & SMS", icon:"📞", name:"Truecaller", url:"https://truecaller.com", desc:"Telefon numarası arama, spam tespiti ve arayanı tanımlama.", tags:["numara","spam"], types:["free","paid"] },
  { id:24, cat:"TELEFON & SMS", icon:"📞", name:"NumLookup", url:"https://www.numlookup.com", desc:"Ücretsiz ters telefon arama; taşıyıcı, konum ve tip bilgisi.", tags:["ters arama","taşıyıcı"], types:["free"] },
  { id:25, cat:"TELEFON & SMS", icon:"📞", name:"PhoneInfoga", url:"https://github.com/sundowndev/phoneinfoga", desc:"Uluslararası telefon numarası istihbarat aracı. OSINT tabanlı.", tags:["uluslararası","istihbarat"], types:["free"] },
  { id:26, cat:"TELEFON & SMS", icon:"📞", name:"Sync.me", url:"https://sync.me", desc:"Sosyal medya entegrasyonlu ters telefon arama.", tags:["sosyal","ters arama"], types:["free"] },
  { id:27, cat:"TELEFON & SMS", icon:"📞", name:"SpyDialer", url:"https://spydialer.com", desc:"Ücretsiz ters telefon, e-posta ve kişi arama.", tags:["ters arama","e-posta"], types:["free"] },

  // ── IP & AĞ ──
  { id:28, cat:"IP & AĞ", icon:"🌐", name:"Shodan", url:"https://shodan.io", desc:"İnternete bağlı cihazları, servisleri ve açık portları tarayan OSINT motoru.", tags:["iot","port","servis","cihaz"], types:["free","paid","api"] },
  { id:29, cat:"IP & AĞ", icon:"🌐", name:"Censys", url:"https://censys.io", desc:"İnternet altyapısı arama — sertifikalar, IP'ler, domainler.", tags:["altyapı","sertifika"], types:["free","api"] },
  { id:30, cat:"IP & AĞ", icon:"🌐", name:"IPinfo", url:"https://ipinfo.io", desc:"IP coğrafi konum, ASN, taşıyıcı ve şirket bilgisi.", tags:["geo","asn","konum"], types:["free","api"] },
  { id:31, cat:"IP & AĞ", icon:"🌐", name:"GreyNoise", url:"https://greynoise.io", desc:"İnternet gürültüsü analizi; hangi IP'lerin tarama yaptığını takip et.", tags:["tarama","gürültü","tehdit"], types:["free","api"] },
  { id:32, cat:"IP & AĞ", icon:"🌐", name:"BGPView", url:"https://bgpview.io", desc:"ASN, IP prefix, BGP rota ve peer bilgilerini görselleştir.", tags:["asn","bgp","rota"], types:["free"] },
  { id:33, cat:"IP & AĞ", icon:"🌐", name:"MXToolbox", url:"https://mxtoolbox.com", desc:"DNS, MX, blacklist, SMTP ve ağ araçları süiti.", tags:["dns","mx","blacklist"], types:["free"] },
  { id:34, cat:"IP & AĞ", icon:"🌐", name:"Hurricane Electric BGP", url:"https://bgp.he.net", desc:"ASN ve IP prefix sorgulama, BGP topoloji haritası.", tags:["bgp","asn","harita"], types:["free"] },

  // ── ALAN ADI & DNS ──
  { id:35, cat:"ALAN ADI & DNS", icon:"🔗", name:"WHOIS (IANA)", url:"https://lookup.icann.org", desc:"Resmi ICANN WHOIS sorgulama; kayıt sahibi, NS ve tarihler.", tags:["whois","kayıt","ns"], types:["free"] },
  { id:36, cat:"ALAN ADI & DNS", icon:"🔗", name:"DomainTools", url:"https://domaintools.com", desc:"WHOIS geçmişi, DNS kayıtları ve domain risk skoru.", tags:["whois","geçmiş","risk"], types:["paid","api"] },
  { id:37, cat:"ALAN ADI & DNS", icon:"🔗", name:"SecurityTrails", url:"https://securitytrails.com", desc:"DNS ve domain geçmişi, WHOIS değişiklikleri, subdomainler.", tags:["dns","geçmiş","subdomain"], types:["free","api"] },
  { id:38, cat:"ALAN ADI & DNS", icon:"🔗", name:"DNSDumpster", url:"https://dnsdumpster.com", desc:"Alan adı keşfi; DNS kayıtları ve sunucu haritası.", tags:["dns","keşif","harita"], types:["free"] },
  { id:39, cat:"ALAN ADI & DNS", icon:"🔗", name:"crt.sh", url:"https://crt.sh", desc:"SSL/TLS sertifika şeffaflık logu araması; subdomainleri keşfet.", tags:["ssl","sertifika","subdomain"], types:["free"] },
  { id:40, cat:"ALAN ADI & DNS", icon:"🔗", name:"Amass (OWASP)", url:"https://github.com/owasp-amass/amass", desc:"Subdomain keşfi ve haritalama. OWASP destekli aktif/pasif OSINT.", tags:["subdomain","haritalama"], types:["free"] },
  { id:41, cat:"ALAN ADI & DNS", icon:"🔗", name:"ViewDNS", url:"https://viewdns.info", desc:"Ters IP, DNS, WHOIS, spam DB ve daha fazlası için ücretsiz araçlar.", tags:["ters ip","dns","spam"], types:["free"] },
  { id:42, cat:"ALAN ADI & DNS", icon:"🔗", name:"Sublist3r", url:"https://github.com/aboul3la/Sublist3r", desc:"Python tabanlı hızlı subdomain listeleme aracı.", tags:["subdomain","python"], types:["free"] },

  // ── GÖRSELARAma & YÜZLER ──
  { id:43, cat:"GÖRSEL & YÜZLER", icon:"🖼️", name:"Google Lens", url:"https://lens.google.com", desc:"Görsel arama, metin tanıma ve ürün tanımlama. En geniş indeks.", tags:["görsel","arama","ocr"], types:["free"] },
  { id:44, cat:"GÖRSEL & YÜZLER", icon:"🖼️", name:"TinEye", url:"https://tineye.com", desc:"Ters görsel arama; fotoğrafın internetteki tüm kullanımlarını bul.", tags:["ters görsel","kaynak"], types:["free","api"] },
  { id:45, cat:"GÖRSEL & YÜZLER", icon:"🖼️", name:"Yandex Görseller", url:"https://yandex.com/images", desc:"Yüz tanıma konusunda Google'dan üstün performans gösteren Rus arama.", tags:["yüz","görsel","rusya"], types:["free"] },
  { id:46, cat:"GÖRSEL & YÜZLER", icon:"🖼️", name:"PimEyes", url:"https://pimeyes.com", desc:"Yüz tanıma tabanlı ters arama; internetteki yüz eşleşmelerini bul.", tags:["yüz tanıma","eşleşme"], types:["paid"] },
  { id:47, cat:"GÖRSEL & YÜZLER", icon:"🖼️", name:"FaceCheck.ID", url:"https://facecheck.id", desc:"Yüz fotoğrafı ile sosyal medya ve web profili eşleştirme.", tags:["yüz","profil","sosyal"], types:["paid"] },
  { id:48, cat:"GÖRSEL & YÜZLER", icon:"🖼️", name:"Exif.tools", url:"https://exif.tools", desc:"Fotoğraf meta verisi (EXIF) okuma; GPS, kamera, tarih bilgisi.", tags:["exif","metadata","gps"], types:["free"] },

  // ── DARK WEB ──
  { id:49, cat:"DARK WEB & LEAK", icon:"🕵️", name:"IntelX", url:"https://intelx.io", desc:"Dark web, Tor, Pastebin ve sızıntı veritabanı araması. Profesyonel OSINT.", tags:["dark web","sızıntı","pastebin"], types:["paid","api"] },
  { id:50, cat:"DARK WEB & LEAK", icon:"🕵️", name:"Ahmia", url:"https://ahmia.fi", desc:"Tor ağındaki .onion sitelerini indeksleyen arama motoru.", tags:["tor","onion","arama"], types:["free","tor"] },
  { id:51, cat:"DARK WEB & LEAK", icon:"🕵️", name:"Breach Directory", url:"https://breachdirectory.org", desc:"E-posta ve kullanıcı adı bazlı veri ihlali araması.", tags:["ihlal","e-posta","şifre"], types:["free"] },
  { id:52, cat:"DARK WEB & LEAK", icon:"🕵️", name:"LeakCheck", url:"https://leakcheck.io", desc:"Kombolist ve veri ihlali arama; e-posta, kullanıcı adı, hash.", tags:["kombolist","hash","ihlal"], types:["free","paid"] },
  { id:53, cat:"DARK WEB & LEAK", icon:"🕵️", name:"DeHashed", url:"https://dehashed.com", desc:"Kapsamlı ihlal veritabanı arama; e-posta, IP, kullanıcı adı.", tags:["ihlal","ip","e-posta"], types:["paid"] },
  { id:54, cat:"DARK WEB & LEAK", icon:"🕵️", name:"SnusBase", url:"https://snusbase.com", desc:"Veri sızıntısı veritabanı araması; şifre hash ve plaintext.", tags:["sızıntı","şifre","hash"], types:["paid"] },
  { id:55, cat:"DARK WEB & LEAK", icon:"🕵️", name:"OnionSearch", url:"https://github.com/megadose/OnionSearch", desc:"Çoklu Tor arama motorlarını aynı anda sorgulayan Python aracı.", tags:["tor","python","çoklu"], types:["free","tor"] },

  // ── HARİTA & KONUM ──
  { id:56, cat:"HARİTA & KONUM", icon:"🗺️", name:"Google Earth Pro", url:"https://earth.google.com", desc:"Uydu görüntüleri, 3D arazi, geçmiş görüntüler ve coğrafi analiz.", tags:["uydu","3d","geçmiş"], types:["free"] },
  { id:57, cat:"HARİTA & KONUM", icon:"🗺️", name:"Sentinel Hub", url:"https://apps.sentinel-hub.com", desc:"ESA uydu görüntüleri; NDVI, değişim tespiti ve anlık izleme.", tags:["uydu","esa","değişim"], types:["free","paid"] },
  { id:58, cat:"HARİTA & KONUM", icon:"🗺️", name:"GeoHack", url:"https://geohack.toolforge.org", desc:"Koordinat tabanlı hızlı harita ve coğrafi bilgi kaynağı linki.", tags:["koordinat","harita"], types:["free"] },
  { id:59, cat:"HARİTA & KONUM", icon:"🗺️", name:"Overpass Turbo", url:"https://overpass-turbo.eu", desc:"OpenStreetMap veri sorgu arayüzü; gelişmiş coğrafi filtreleme.", tags:["osm","sorgu","coğrafi"], types:["free"] },
  { id:60, cat:"HARİTA & KONUM", icon:"🗺️", name:"Mapillary", url:"https://mapillary.com", desc:"Kalabalık kaynaklı sokak fotoğrafları; OSINT coğrafi doğrulama.", tags:["sokak","fotoğraf","doğrulama"], types:["free"] },
  { id:61, cat:"HARİTA & KONUM", icon:"🗺️", name:"SunCalc", url:"https://suncalc.org", desc:"Güneş açısı ve gölge analizi; fotoğraf zaman-konum tespiti.", tags:["güneş","gölge","zaman"], types:["free"] },
  { id:62, cat:"HARİTA & KONUM", icon:"🗺️", name:"GeoGuessr Radar", url:"https://geotips.net", desc:"Coğrafi ipuçları veritabanı; GeoGuessr ve OSINT konum tahmini.", tags:["coğrafi","ipucu"], types:["free"] },

  // ── ARAÇ TAKIP ──
  { id:63, cat:"ARAÇ & TAŞIMA", icon:"🚗", name:"MarineTraffic", url:"https://marinetraffic.com", desc:"Gerçek zamanlı gemi takibi, AIS verileri, liman istatistikleri.", tags:["gemi","ais","gerçek zamanlı"], types:["free","paid"] },
  { id:64, cat:"ARAÇ & TAŞIMA", icon:"🚗", name:"FlightAware", url:"https://flightaware.com", desc:"Uçuş takibi, rota geçmişi ve hava trafik verileri.", tags:["uçak","uçuş","rota"], types:["free","paid"] },
  { id:65, cat:"ARAÇ & TAŞIMA", icon:"🚗", name:"FlightRadar24", url:"https://flightradar24.com", desc:"Anlık uçuş takibi; 3D görünüm, hava aracı geçmişi.", tags:["uçak","3d","anlık"], types:["free","paid"] },
  { id:66, cat:"ARAÇ & TAŞIMA", icon:"🚗", name:"ADS-B Exchange", url:"https://globe.adsbexchange.com", desc:"Sansürsüz, gerçek zamanlı uçak takibi. Askeri dahil.", tags:["adsb","askeri","sansürsüz"], types:["free"] },
  { id:67, cat:"ARAÇ & TAŞIMA", icon:"🚗", name:"OpenRailwayMap", url:"https://openrailwaymap.org", desc:"Dünya demiryolu ağı haritası ve altyapı bilgisi.", tags:["tren","demiryolu","harita"], types:["free"] },
  { id:68, cat:"ARAÇ & TAŞIMA", icon:"🚗", name:"VesselFinder", url:"https://vesselfinder.com", desc:"Gemi takibi ve liman hareketleri; AIS tabanlı.", tags:["gemi","liman","ais"], types:["free"] },

  // ── ŞİRKET & FİNANS ──
  { id:69, cat:"ŞİRKET & FİNANS", icon:"🏢", name:"OpenCorporates", url:"https://opencorporates.com", desc:"140M+ şirket kaydı; küresel kurumsal veri tabanı.", tags:["şirket","kayıt","küresel"], types:["free","api"] },
  { id:70, cat:"ŞİRKET & FİNANS", icon:"🏢", name:"Crunchbase", url:"https://crunchbase.com", desc:"Startup, yatırım, girişimci ve yönetici verileri.", tags:["startup","yatırım","girişim"], types:["free","paid"] },
  { id:71, cat:"ŞİRKET & FİNANS", icon:"🏢", name:"SEC EDGAR", url:"https://efts.sec.gov/LATEST/search-index", desc:"ABD şirket finansal ifadeleri ve hisse bilgileri.", tags:["sec","finans","hisse"], types:["free"] },
  { id:72, cat:"ŞİRKET & FİNANS", icon:"🏢", name:"LinkedIn (OSINT)", url:"https://linkedin.com", desc:"Çalışan profilleri, şirket yapısı ve iş bağlantıları analizi.", tags:["çalışan","profil","iş"], types:["free"] },
  { id:73, cat:"ŞİRKET & FİNANS", icon:"🏢", name:"Glassdoor", url:"https://glassdoor.com", desc:"Şirket incelemeleri, maaş verileri ve çalışan yorumları.", tags:["maaş","inceleme","çalışan"], types:["free"] },
  { id:74, cat:"ŞİRKET & FİNANS", icon:"🏢", name:"ICIJ Offshore Leaks", url:"https://offshoreleaks.icij.org", desc:"Panama, Pandora, Paradise Papers sızıntı veritabanı araması.", tags:["offshore","sızıntı","vergi"], types:["free"] },

  // ── SİBER TEHDİT İSTİHBARAT ──
  { id:75, cat:"SİBER TEHDİT", icon:"⚠️", name:"VirusTotal", url:"https://virustotal.com", desc:"URL, dosya, IP ve domain üzerinde 70+ antivirüs ile analiz.", tags:["antivirüs","url","dosya","domain"], types:["free","api"] },
  { id:76, cat:"SİBER TEHDİT", icon:"⚠️", name:"AbuseIPDB", url:"https://abuseipdb.com", desc:"Kötücül IP adresleri raporlama ve sorgulama veritabanı.", tags:["ip","kötücül","rapor"], types:["free","api"] },
  { id:77, cat:"SİBER TEHDİT", icon:"⚠️", name:"AlienVault OTX", url:"https://otx.alienvault.com", desc:"Açık kaynak tehdit istihbarat paylaşım platformu.", tags:["tehdit","ioc","paylaşım"], types:["free","api"] },
  { id:78, cat:"SİBER TEHDİT", icon:"⚠️", name:"URLScan.io", url:"https://urlscan.io", desc:"URL tarama ve analiz; ekran görüntüsü, DOM, ağ istekleri.", tags:["url","tarama","dom"], types:["free","api"] },
  { id:79, cat:"SİBER TEHDİT", icon:"⚠️", name:"Any.run", url:"https://any.run", desc:"İnteraktif kötücül yazılım analiz sanal makinesi.", tags:["malware","sandbox","analiz"], types:["free","paid"] },
  { id:80, cat:"SİBER TEHDİT", icon:"⚠️", name:"Hybrid Analysis", url:"https://hybrid-analysis.com", desc:"Ücretsiz kötücül yazılım analiz hizmeti; Falcon Sandbox.", tags:["malware","falcon","sandbox"], types:["free","api"] },
  { id:81, cat:"SİBER TEHDİT", icon:"⚠️", name:"Maltiverse", url:"https://maltiverse.com", desc:"Tehdit istihbarat toplayıcı; IP, URL, domain ve hash sorgulama.", tags:["tehdit","ioc","hash"], types:["free","paid"] },
  { id:82, cat:"SİBER TEHDİT", icon:"⚠️", name:"ThreatFox", url:"https://threatfox.abuse.ch", desc:"IOC paylaşım platformu; malware hash, URL ve IP.", tags:["ioc","malware","hash"], types:["free","api"] },

  // ── WEB ARŞİV & CACHE ──
  { id:83, cat:"WEB ARŞİV & CACHE", icon:"📦", name:"Wayback Machine", url:"https://web.archive.org", desc:"İnternetin belleği; silinen ve değiştirilen sayfaları arşivlede bul.", tags:["arşiv","geçmiş","cache"], types:["free","api"] },
  { id:84, cat:"WEB ARŞİV & CACHE", icon:"📦", name:"CachedView", url:"https://cachedview.nl", desc:"Google, Wayback ve Bing cache kaynaklarını karşılaştır.", tags:["cache","google","bing"], types:["free"] },
  { id:85, cat:"WEB ARŞİV & CACHE", icon:"📦", name:"Archive.ph", url:"https://archive.ph", desc:"Sayfa anlık görüntüsü alma ve paylaşma; içerik değişimini izle.", tags:["anlık görüntü","paylaşma"], types:["free"] },
  { id:86, cat:"WEB ARŞİV & CACHE", icon:"📦", name:"CommonCrawl", url:"https://commoncrawl.org", desc:"8 yıllık web tarama arşivi; büyük veri analizi için.", tags:["tarama","arşiv","büyük veri"], types:["free"] },

  // ── DÖKÜMAN & METAVERİ ──
  { id:87, cat:"DÖKÜMAN & METAVERİ", icon:"📄", name:"FOCA", url:"https://www.elevenpaths.com/labstools/foca", desc:"Döküman meta verisi analizi; yazar, yazılım, yol bilgisi.", tags:["metadata","yazar","belge"], types:["free"] },
  { id:88, cat:"DÖKÜMAN & METAVERİ", icon:"📄", name:"MetaShield", url:"https://metashield.net", desc:"Online döküman metadata temizleme ve görüntüleme.", tags:["metadata","temizleme"], types:["free"] },
  { id:89, cat:"DÖKÜMAN & METAVERİ", icon:"📄", name:"PDF Examiner", url:"https://pdfexaminer.com", desc:"PDF dosyası güvenlik analizi; zararlı içerik tespiti.", tags:["pdf","analiz","güvenlik"], types:["free"] },
  { id:90, cat:"DÖKÜMAN & METAVERİ", icon:"📄", name:"Dorks (Google)", url:"https://dorksearch.com", desc:"Google dork sorguları veritabanı; gizli dosya ve dizin keşfi.", tags:["dork","google","keşif"], types:["free"] },

  // ── BLOCKCHAIN & KRİPTO ──
  { id:91, cat:"BLOCKCHAIN & KRİPTO", icon:"₿", name:"Blockchain Explorer", url:"https://blockchain.com/explorer", desc:"Bitcoin işlemleri, cüzdan ve blok analizi.", tags:["bitcoin","işlem","cüzdan"], types:["free"] },
  { id:92, cat:"BLOCKCHAIN & KRİPTO", icon:"₿", name:"Etherscan", url:"https://etherscan.io", desc:"Ethereum blok zinciri; işlem, sözleşme ve token takibi.", tags:["ethereum","sözleşme","token"], types:["free","api"] },
  { id:93, cat:"BLOCKCHAIN & KRİPTO", icon:"₿", name:"Chainalysis Reactor", url:"https://chainalysis.com", desc:"Kripto para akışı takibi ve kara para aklama tespiti.", tags:["kripto","akış","kara para"], types:["paid"] },
  { id:94, cat:"BLOCKCHAIN & KRİPTO", icon:"₿", name:"Crystal Blockchain", url:"https://crystalblockchain.com", desc:"Kripto uyumluluk ve risk değerlendirme platformu.", tags:["uyumluluk","risk","kripto"], types:["paid"] },

  // ── FRAMEWORK & TOPLAMA ──
  { id:95, cat:"FRAMEWORK & KOLEKSIYON", icon:"🛠️", name:"Maltego", url:"https://maltego.com", desc:"Görsel link analizi ve OSINT otomasyon platformu. Endüstri standardı.", tags:["link analizi","görsel","otomasyon"], types:["free","paid"] },
  { id:96, cat:"FRAMEWORK & KOLEKSIYON", icon:"🛠️", name:"SpiderFoot", url:"https://spiderfoot.net", desc:"Otomatik OSINT veri toplama framework'ü; 200+ modül.", tags:["otomasyon","modül","toplama"], types:["free"] },
  { id:97, cat:"FRAMEWORK & KOLEKSIYON", icon:"🛠️", name:"Recon-ng", url:"https://github.com/lanmaster53/recon-ng", desc:"Python tabanlı tam özellikli OSINT keşif framework'ü.", tags:["python","framework","keşif"], types:["free"] },
  { id:98, cat:"FRAMEWORK & KOLEKSIYON", icon:"🛠️", name:"theHarvester", url:"https://github.com/laramies/theHarvester", desc:"E-posta, domain, IP ve subdomain toplama aracı. Pentest klasiği.", tags:["e-posta","subdomain","pentest"], types:["free"] },
  { id:99, cat:"FRAMEWORK & KOLEKSIYON", icon:"🛠️", name:"OSINT Framework", url:"https://osintframework.com", desc:"OSINT araçlarının kategorize edilmiş interaktif ağacı.", tags:["koleksiyon","ağaç","kategori"], types:["free"] },
  { id:100, cat:"FRAMEWORK & KOLEKSIYON", icon:"🛠️", name:"Bellingcat Toolkit", url:"https://docs.google.com/spreadsheets/d/18rtqh8EG2q1xBo2cLNyhIDuK9jrPGwYr9DI2UncoqJQ", desc:"Bellingcat'ın araştırmacı gazeteciler için hazırladığı OSINT araç listesi.", tags:["gazetecilik","araştırma","koleksiyon"], types:["free"] },
  { id:101, cat:"FRAMEWORK & KOLEKSIYON", icon:"🛠️", name:"Hunchly", url:"https://hunch.ly", desc:"Otomatik web içeriği yakalama ve araştırma belgesi oluşturma.", tags:["yakalama","belgeleme","araştırma"], types:["paid"] },
  { id:102, cat:"FRAMEWORK & KOLEKSIYON", icon:"🛠️", name:"Start.me OSINT", url:"https://start.me/p/DPYPMz/the-ultimate-osint-collection", desc:"Binlerce OSINT kaynağını kategorize eden start.me sayfası.", tags:["koleksiyon","başlangıç","kapsamlı"], types:["free"] },
];

// ══════════ UYGULAMA DURUMU ══════════
let currentCat = "TÜMÜ";
let favorites = JSON.parse(localStorage.getItem("phantom_favs") || "[]");
let currentUser = "OPERATOR";

// ══════════ LOGIN ══════════
const CREDS = { "phantom":"osint2024", "admin":"phantom123", "guest":"guest" };

function doLogin() {
  const u = document.getElementById("login-user").value.trim();
  const p = document.getElementById("login-pass").value;
  const s = document.getElementById("login-status");
  s.className = "login-status";
  s.textContent = "[ AUTHENTICATING... ]";
  setTimeout(() => {
    if (CREDS[u] && CREDS[u] === p) {
      s.className = "login-status ok";
      s.textContent = "[ ACCESS GRANTED ]";
      currentUser = u.toUpperCase();
      setTimeout(() => {
        document.getElementById("login-screen").classList.add("hidden");
        document.getElementById("main-panel").style.display = "flex";
        initPanel();
      }, 600);
    } else {
      s.className = "login-status err";
      s.textContent = "[ ACCESS DENIED — INVALID CREDENTIALS ]";
      document.getElementById("login-pass").value = "";
    }
  }, 800);
}

document.addEventListener("keydown", e => {
  if (e.key === "Enter" && !document.getElementById("login-screen").classList.contains("hidden")) doLogin();
});

// ══════════ INIT ══════════
function initPanel() {
  document.getElementById("top-user").textContent = `◈ ${currentUser}`;
  updateClock();
  setInterval(updateClock, 1000);
  buildSidebar();
  renderCards("TÜMÜ");
}

function updateClock() {
  const now = new Date();
  document.getElementById("clock").textContent =
    now.toLocaleTimeString("tr-TR", {hour12:false}) + " | " +
    now.toLocaleDateString("tr-TR");
}

// ══════════ SIDEBAR ══════════
function buildSidebar() {
  const cats = ["TÜMÜ", ...new Set(OSINT_DATA.map(t => t.cat))];
  const sidebar = document.getElementById("sidebar");
  const catGroups = {
    "GENEL": ["TÜMÜ","FAVORİLER"],
    "KİŞİ": ["KİŞİ & KİMLİK","SOSYAL MEDYA","E-POSTA & KULLANICI","TELEFON & SMS"],
    "TEKNİK": ["IP & AĞ","ALAN ADI & DNS","SİBER TEHDİT","DARK WEB & LEAK"],
    "KEŞİF": ["GÖRSEL & YÜZLER","HARİTA & KONUM","ARAÇ & TAŞIMA","WEB ARŞİV & CACHE"],
    "ANALİZ": ["ŞİRKET & FİNANS","DÖKÜMAN & METAVERİ","BLOCKCHAIN & KRİPTO","FRAMEWORK & KOLEKSIYON"]
  };
  const icons = {
    "TÜMÜ":"🌐","FAVORİLER":"⭐","KİŞİ & KİMLİK":"👤","SOSYAL MEDYA":"📱",
    "E-POSTA & KULLANICI":"✉️","TELEFON & SMS":"📞","IP & AĞ":"🌐","ALAN ADI & DNS":"🔗",
    "SİBER TEHDİT":"⚠️","DARK WEB & LEAK":"🕵️","GÖRSEL & YÜZLER":"🖼️",
    "HARİTA & KONUM":"🗺️","ARAÇ & TAŞIMA":"🚗","WEB ARŞİV & CACHE":"📦",
    "ŞİRKET & FİNANS":"🏢","DÖKÜMAN & METAVERİ":"📄","BLOCKCHAIN & KRİPTO":"₿",
    "FRAMEWORK & KOLEKSIYON":"🛠️"
  };

  let html = "";
  for (const [group, items] of Object.entries(catGroups)) {
    html += `<div class="sidebar-section"><div class="sidebar-cat">${group}</div>`;
    for (const cat of items) {
      const count = cat === "TÜMÜ" ? OSINT_DATA.length : cat === "FAVORİLER" ? favorites.length : OSINT_DATA.filter(t => t.cat === cat).length;
      html += `<div class="sidebar-item ${cat===currentCat?'active':''}" onclick="selectCat('${cat}')" data-cat="${cat}">
        <span class="sidebar-icon">${icons[cat]||"◈"}</span>
        <span>${cat}</span>
        <span class="sidebar-count">${count}</span>
      </div>`;
    }
    html += "</div>";
  }
  sidebar.innerHTML = html;
}

function selectCat(cat) {
  currentCat = cat;
  document.querySelectorAll(".sidebar-item").forEach(el => {
    el.classList.toggle("active", el.dataset.cat === cat);
  });
  filterCards();
}

// ══════════ CARDS ══════════
function filterCards() {
  const q = document.getElementById("search-input").value.toLowerCase();
  const type = document.getElementById("filter-type").value;
  let data = currentCat === "TÜMÜ" ? OSINT_DATA : currentCat === "FAVORİLER" ? OSINT_DATA.filter(t => favorites.includes(t.id)) : OSINT_DATA.filter(t => t.cat === currentCat);
  if (q) data = data.filter(t => t.name.toLowerCase().includes(q) || t.desc.toLowerCase().includes(q) || t.tags.some(g => g.includes(q)));
  if (type !== "all") data = data.filter(t => t.types.includes(type));
  renderCards(null, data);
}

function renderCards(cat, data) {
  if (cat) { currentCat = cat; filterCards(); return; }
  const container = document.getElementById("cards-container");
  if (!data || data.length === 0) {
    container.innerHTML = `<div style="padding:60px;text-align:center;color:var(--dim);font-size:14px;letter-spacing:3px">[ SONUÇ BULUNAMADI ]</div>`;
    updateStats(0); return;
  }

  // Kategorilere göre grupla
  const groups = {};
  data.forEach(t => { if (!groups[t.cat]) groups[t.cat] = []; groups[t.cat].push(t); });

  let html = "";
  for (const [cat, tools] of Object.entries(groups)) {
    html += `<div class="category-header">
      <span class="cat-icon">${tools[0].icon}</span>
      <h2>${cat}</h2>
      <span class="cat-count-badge">${tools.length} ARAÇ</span>
      <div class="cat-line"></div>
    </div>
    <div class="cards-grid">`;
    tools.forEach((t, i) => {
      const isFav = favorites.includes(t.id);
      html += `<div class="card" style="animation-delay:${i*0.03}s" onclick="openModal(${t.id})">
        <div class="card-top">
          <span class="card-icon">${t.icon}</span>
          <div class="card-badges">
            ${t.types.map(ty => `<span class="badge badge-${ty}">${ty.toUpperCase()}</span>`).join("")}
          </div>
        </div>
        <div class="card-title">${t.name}</div>
        <div class="card-desc">${t.desc}</div>
        <div class="card-footer">
          <a class="card-link" href="${t.url}" target="_blank" rel="noopener" onclick="event.stopPropagation()">⬡ ZİYARET ET</a>
          <button class="fav-btn ${isFav?'active':''}" onclick="event.stopPropagation();toggleFav(${t.id},this)" title="Favorilere ekle">★</button>
        </div>
      </div>`;
    });
    html += "</div>";
  }
  container.innerHTML = html;
  updateStats(data.length);
}

function updateStats(shown) {
  document.getElementById("stat-total").textContent = OSINT_DATA.length;
  document.getElementById("stat-shown").textContent = shown;
  document.getElementById("stat-cats").textContent = new Set(OSINT_DATA.map(t=>t.cat)).size;
  document.getElementById("stat-favs").textContent = favorites.length;
}

// ══════════ MODAL ══════════
function openModal(id) {
  const t = OSINT_DATA.find(x => x.id === id);
  if (!t) return;
  document.getElementById("m-title").textContent = t.name;
  document.getElementById("m-url").textContent = t.url;
  document.getElementById("m-desc").textContent = t.desc;
  document.getElementById("m-link").href = t.url;
  document.getElementById("m-tags").innerHTML = t.tags.map(g => `<span class="modal-tag">${g.toUpperCase()}</span>`).join("") + t.types.map(ty => `<span class="badge badge-${ty}" style="padding:4px 10px">${ty.toUpperCase()}</span>`).join("");
  document.getElementById("modal-overlay").classList.add("open");
}

function closeModal(e) {
  if (!e || e.target === document.getElementById("modal-overlay"))
    document.getElementById("modal-overlay").classList.remove("open");
}

// ══════════ FAVORİLER ══════════
function toggleFav(id, btn) {
  if (favorites.includes(id)) {
    favorites = favorites.filter(f => f !== id);
    btn.classList.remove("active");
  } else {
    favorites.push(id);
    btn.classList.add("active");
  }
  localStorage.setItem("phantom_favs", JSON.stringify(favorites));
  document.getElementById("stat-favs").textContent = favorites.length;
  // Sidebar güncelle
  document.querySelectorAll("[data-cat='FAVORİLER'] .sidebar-count").forEach(el => el.textContent = favorites.length);
}
</script>
</body>
</html>
HTMLEOF

# --- Python HTTP sunucusu başlat ---
cd "$TMPDIR_PHANTOM"
python3 -m http.server "$PORT" --bind 127.0.0.1 2>/dev/null &
SERVER_PID=$!

# Yüklenme kontrolü
sleep 1
if kill -0 $SERVER_PID 2>/dev/null; then
  echo "  [✓] Sunucu çalışıyor: http://localhost:$PORT"
  echo "  [i] Eğer Android'de açmak istersen: http://127.0.0.1:$PORT"
  echo ""
else
  echo "  [✗] Sunucu başlatılamadı! Python3 kurulu mu?"
  exit 1
fi

# --- Temizlik fonksiyonu ---
cleanup() {
  echo ""
  echo "  [*] PHANTOM OSINT Panel kapatılıyor..."
  kill $SERVER_PID 2>/dev/null
  rm -rf "$TMPDIR_PHANTOM"
  echo "  [✓] Temizlik tamamlandı."
  exit 0
}
trap cleanup INT TERM

# --- Bekle ---
wait $SERVER_PID
HTMLEOF
