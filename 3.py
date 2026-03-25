import http.server
from http.server import BaseHTTPRequestHandler
from socketserver import ThreadingMixIn
import urllib.request
import socket
import subprocess
import sys
import time

# ====================== EMBEDDED HTML (önceki panel + küçük düzeltmeler) ======================
HTML = """<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🚀 ADS-B Termux Radar Panel</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&amp;display=swap');
        
        :root { --tw-color-primary: #22d3ee; }
        body { font-family: 'Inter', system-ui, sans-serif; }
        #map { height: 100vh; }
        .plane-icon { filter: drop-shadow(0 0 6px rgb(34 211 238)); }
        
        @keyframes emergencyFlash { 0%, 100% { opacity: 1; } 50% { opacity: 0.2; } }
        .emergency { animation: emergencyFlash 800ms infinite; }
        
        .leaflet-marker-icon { transition: transform 0.3s ease; }
        .gauge { filter: drop-shadow(0 0 12px #22d3ee); }
    </style>
</head>
<body class="bg-zinc-950 text-white overflow-hidden">
    <div class="flex h-screen">
        <!-- SOL PANEL -->
        <div class="w-80 bg-zinc-900 border-r border-zinc-800 flex flex-col">
            <div class="p-4 border-b border-zinc-800 flex items-center gap-3">
                <div class="w-8 h-8 bg-cyan-400 rounded-xl flex items-center justify-center text-black text-xl">✈️</div>
                <div>
                    <h1 class="text-xl font-semibold tracking-tight">ADS-B Termux Radar</h1>
                    <p class="text-xs text-zinc-400">Canlı • OpenSky • Termux</p>
                </div>
                <div id="status-dot" class="ml-auto w-3 h-3 bg-green-400 rounded-full animate-pulse"></div>
            </div>

            <div class="p-4 border-b border-zinc-800">
                <div class="relative">
                    <input id="search-input" type="text" placeholder="Callsign / Ülke / ICAO ara... (F)" 
                           class="w-full bg-zinc-800 border border-zinc-700 focus:border-cyan-400 rounded-2xl px-4 py-3 text-sm outline-none">
                    <div class="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-mono bg-zinc-700 px-2 py-0.5 rounded-lg text-cyan-300">F</div>
                </div>
            </div>

            <div class="flex-1 overflow-auto" id="aircraft-list-container">
                <div id="aircraft-list" class="p-2"></div>
            </div>

            <div onclick="toggleStats()" class="p-4 border-t border-zinc-800 flex items-center justify-between cursor-pointer hover:bg-zinc-800">
                <div class="flex items-center gap-2 text-sm font-medium">📊 İstatistik Paneli</div>
                <div id="stats-toggle-icon" class="text-cyan-400">▼</div>
            </div>

            <div id="stats-panel" class="hidden p-4 border-t border-zinc-800 bg-zinc-950 max-h-80 overflow-auto">
                <canvas id="country-chart" class="mb-6" height="140"></canvas>
                <canvas id="speed-chart" class="mb-6" height="140"></canvas>
                <canvas id="altitude-chart" class="mb-6" height="140"></canvas>
            </div>

            <div id="alarm-banner" onclick="this.classList.add('hidden')" 
                 class="hidden mx-4 mb-4 bg-red-500/10 border border-red-500 text-red-400 p-3 rounded-2xl text-sm font-medium flex items-center gap-2 cursor-pointer">
                <span class="text-xl">🚨</span>
                <span id="alarm-text" class="flex-1"></span>
            </div>
        </div>

        <!-- HARİTA -->
        <div class="flex-1 relative" id="map-wrapper">
            <div id="map" class="h-full w-full"></div>

            <div class="absolute top-4 left-4 bg-zinc-900/90 backdrop-blur-xl border border-zinc-700 rounded-3xl p-2 flex flex-col gap-1 z-[1000]">
                <button onclick="centerOnGPS()" class="flex items-center justify-center w-10 h-10 hover:bg-zinc-800 rounded-2xl text-xl transition-colors" title="GPS (C)">📍</button>
                <button onclick="toggleWeather()" class="flex items-center justify-center w-10 h-10 hover:bg-zinc-800 rounded-2xl text-xl transition-colors" title="Hava (H)">🌦️</button>
                <button onclick="toggleNightMode()" class="flex items-center justify-center w-10 h-10 hover:bg-zinc-800 rounded-2xl text-xl transition-colors" title="Gece/Gündüz">🌙</button>
            </div>

            <div id="compass" class="absolute top-4 right-4 bg-zinc-900/90 backdrop-blur-xl border border-zinc-700 rounded-3xl p-3 shadow-2xl z-[1000] flex flex-col items-center">
                <div class="text-xs font-mono text-cyan-300 mb-1 tracking-widest">PUSULA</div>
                <div class="relative w-16 h-16">
                    <div id="compass-needle" class="absolute inset-0 flex items-center justify-center text-4xl transition-transform">🧭</div>
                    <div class="absolute inset-0 flex items-center justify-center text-xs font-bold text-white/70">N</div>
                </div>
            </div>

            <div id="selected-bar" onclick="if(event.target.id==='close-bar') deselectAircraft()" 
                 class="hidden absolute bottom-6 left-1/2 -translate-x-1/2 bg-zinc-900/95 backdrop-blur-2xl border border-cyan-400 rounded-3xl px-6 py-3 shadow-2xl flex items-center gap-6 z-[1100]">
                <div id="selected-callsign" class="font-mono text-2xl font-semibold"></div>
                <div id="selected-flag" class="text-3xl"></div>
                <div class="flex items-center gap-4 text-sm">
                    <div><span id="selected-alt" class="font-medium"></span>m</div>
                    <div><span id="selected-speed" class="font-medium"></span> km/h</div>
                    <div id="selected-squawk" class="font-mono px-3 py-1 bg-red-500/20 text-red-400 rounded-2xl"></div>
                </div>
                <button onclick="openFlightAware(); event.stopImmediatePropagation()" class="bg-cyan-400 hover:bg-cyan-300 text-black px-6 py-2 rounded-3xl text-sm font-semibold flex items-center gap-2">FlightAware →</button>
                <button onclick="copyCoordinates(); event.stopImmediatePropagation()" class="bg-zinc-700 hover:bg-zinc-600 px-4 py-2 rounded-3xl text-sm">📋 Koordinat</button>
                <button id="close-bar" class="ml-auto text-zinc-400 hover:text-white text-3xl leading-none">×</button>
            </div>

            <canvas id="loading-canvas" class="absolute inset-0 z-[9999] pointer-events-none hidden"></canvas>
        </div>

        <!-- SAĞ PANEL -->
        <div id="detail-panel" class="w-80 bg-zinc-900 border-l border-zinc-800 flex flex-col hidden">
            <div class="p-4 border-b flex items-center justify-between">
                <div class="font-semibold">Uçuş Detayı</div>
                <button onclick="deselectAircraft()" class="text-3xl text-zinc-400 hover:text-white">×</button>
            </div>
            <div class="p-6 flex-1 overflow-auto">
                <div id="detail-callsign" class="font-mono text-4xl font-bold mb-1"></div>
                <div id="detail-country" class="flex items-center gap-3 text-xl mb-8"></div>
                <div class="mb-8">
                    <div class="text-xs text-zinc-400 mb-2 flex justify-between"><span>HIZ</span><span id="detail-speed-text" class="font-mono"></span></div>
                    <canvas id="speed-gauge" width="220" height="120" class="mx-auto"></canvas>
                </div>
                <div class="grid grid-cols-2 gap-4 text-sm">
                    <div class="bg-zinc-800 rounded-3xl p-4"><div class="text-zinc-400">İrtifa</div><div id="detail-alt" class="text-3xl font-semibold font-mono"></div></div>
                    <div class="bg-zinc-800 rounded-3xl p-4"><div class="text-zinc-400">Dikey Hız</div><div id="detail-vrate" class="text-3xl font-semibold font-mono"></div></div>
                    <div class="bg-zinc-800 rounded-3xl p-4"><div class="text-zinc-400">Yön</div><div id="detail-heading" class="text-3xl font-semibold font-mono"></div></div>
                    <div class="bg-zinc-800 rounded-3xl p-4"><div class="text-zinc-400">Squawk</div><div id="detail-squawk" class="text-3xl font-semibold font-mono text-red-400"></div></div>
                </div>
            </div>
            <div class="p-4 border-t mt-auto flex gap-3">
                <button onclick="deselectAircraft()" class="flex-1 py-4 bg-zinc-800 hover:bg-zinc-700 rounded-3xl font-medium">Kapat</button>
            </div>
        </div>
    </div>

    <div onclick="if(event.target.id==='help-modal')hideHelp()" id="help-modal" class="hidden fixed inset-0 bg-black/70 z-[99999] flex items-center justify-center">
        <div onclick="event.stopImmediatePropagation()" class="bg-zinc-900 rounded-3xl max-w-md w-full mx-4 p-6">
            <h2 class="text-2xl font-semibold mb-6">⌨️ Klavye Kısayolları</h2>
            <div class="space-y-4 text-sm">
                <div class="flex justify-between"><span class="font-mono bg-zinc-800 px-3 py-1 rounded-2xl">F</span><span>Arama kutusuna odaklan</span></div>
                <div class="flex justify-between"><span class="font-mono bg-zinc-800 px-3 py-1 rounded-2xl">C</span><span>GPS konumuna odakla</span></div>
                <div class="flex justify-between"><span class="font-mono bg-zinc-800 px-3 py-1 rounded-2xl">H</span><span>Hava katmanı</span></div>
                <div class="flex justify-between"><span class="font-mono bg-zinc-800 px-3 py-1 rounded-2xl">S</span><span>İstatistik paneli</span></div>
                <div class="flex justify-between"><span class="font-mono bg-zinc-800 px-3 py-1 rounded-2xl">ESC</span><span>Detay panelini kapat</span></div>
                <div class="flex justify-between"><span class="font-mono bg-zinc-800 px-3 py-1 rounded-2xl">?</span><span>Yardım</span></div>
            </div>
        </div>
    </div>

    <script>
        let map, aircraftLayer, weatherLayer, nightOverlay;
        let aircraftData = {};
        let allStates = [];
        let selectedIcao = null;
        let countryChart, speedChart, altChart;
        let searchInput;
        let updateTimer;
        let trailEnabled = true;
        const countryFlags = {"Turkey":"🇹🇷","Germany":"🇩🇪","France":"🇫🇷","United States":"🇺🇸","United Kingdom":"🇬🇧","Italy":"🇮🇹","Spain":"🇪🇸","Netherlands":"🇳🇱","Russia":"🇷🇺","China":"🇨🇳","Japan":"🇯🇵","Brazil":"🇧🇷","Canada":"🇨🇦","Australia":"🇦🇺","India":"🇮🇳","Switzerland":"🇨🇭","Sweden":"🇸🇪","Norway":"🇳🇴","Denmark":"🇩🇰","Finland":"🇫🇮","Poland":"🇵🇱","Greece":"🇬🇷","Portugal":"🇵🇹","Austria":"🇦🇹","Belgium":"🇧🇪","Ireland":"🇮🇪","Czech Republic":"🇨🇿","Hungary":"🇭🇺","Romania":"🇷🇴","Ukraine":"🇺🇦","South Korea":"🇰🇷","Thailand":"🇹🇭","Malaysia":"🇲🇾","Singapore":"🇸🇬","United Arab Emirates":"🇦🇪","Qatar":"🇶🇦","Israel":"🇮🇱","Egypt":"🇪🇬","South Africa":"🇿🇦"};

        function createPlaneIcon(heading, isEmergency) {
            const colorClass = isEmergency ? 'text-red-500' : 'text-cyan-400';
            const svg = `<svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" style="transform: rotate(${heading || 0}deg);"><path d="M12 2L2 22L12 18L22 22L12 2Z" fill="currentColor" stroke="#111" stroke-width="1"/><circle cx="12" cy="12" r="2" fill="#111"/></svg>`;
            return L.divIcon({className: `plane-icon \( {isEmergency ? 'emergency' : ''}`, html: `<div class=" \){colorClass}">${svg}</div>`, iconSize: [32, 32], iconAnchor: [16, 16]});
        }

        function initMap() {
            map = L.map('map', {zoomControl: true, attributionControl: false}).setView([38.72, 35.48], 8);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);
            aircraftLayer = L.layerGroup().addTo(map);
            updateCompass(0);
        }

        function updateCompass(bearing) {
            document.getElementById('compass-needle').style.transform = `rotate(${-bearing}deg)`;
        }

        async function fetchStates() {
            try {
                const res = await fetch('/api/states');
                if (!res.ok) throw new Error('API hatası');
                const data = await res.json();
                allStates = data.states || [];
                return allStates;
            } catch (e) { console.error(e); return []; }
        }

        function isEmergency(state) {
            const squawk = (state[14] || '').toString();
            const alt = state[7] || 0;
            return ['7700','7600','7500'].includes(squawk) || alt > 11500;
        }

        async function updateAircraft() {
            const states = await fetchStates();
            if (!states.length) return;

            const bounds = map.getBounds().pad(0.8);
            const visibleIcaos = new Set();

            for (let state of states) {
                const icao = state[0];
                const lat = state[6], lon = state[5];
                if (!lat || !lon) continue;
                if (!bounds.contains(L.latLng(lat, lon))) continue;

                visibleIcaos.add(icao);
                const callsign = (state[1] || '').trim();
                const country = state[2] || 'Unknown';
                const heading = state[10] || 0;
                const alt = state[7] || 0;
                const speed = state[9] ? Math.round(state[9] * 3.6) : 0;
                const squawk = state[14] || '';
                const isEm = isEmergency(state);

                let entry = aircraftData[icao] || (aircraftData[icao] = {marker: null, trailLine: null, history: []});

                const icon = createPlaneIcon(heading, isEm);
                if (!entry.marker) {
                    entry.marker = L.marker([lat, lon], {icon}).addTo(aircraftLayer);
                    entry.marker.icao = icao;
                    entry.marker.on('click', () => selectAircraft(icao, state));
                } else {
                    entry.marker.setLatLng([lat, lon]);
                    entry.marker.setIcon(icon);
                }

                if (selectedIcao === icao && trailEnabled) {
                    entry.history.push([lat, lon]);
                    if (entry.history.length > 35) entry.history.shift();
                    if (!entry.trailLine) {
                        entry.trailLine = L.polyline(entry.history, {color: '#22d3ee', weight: 4, opacity: 0.7}).addTo(map);
                    } else {
                        entry.trailLine.setLatLngs(entry.history);
                    }
                }
            }

            // eski marker temizliği
            Object.keys(aircraftData).forEach(icao => {
                if (!visibleIcaos.has(icao)) {
                    if (aircraftData[icao].marker) aircraftLayer.removeLayer(aircraftData[icao].marker);
                    if (aircraftData[icao].trailLine) map.removeLayer(aircraftData[icao].trailLine);
                    delete aircraftData[icao];
                }
            });

            renderAircraftList(states);
            renderStats(states);
            checkAlarms(states);
        }

        function renderAircraftList(states) {
            const filter = searchInput.value.toUpperCase().trim();
            let html = `<table class="w-full text-sm"><thead class="sticky top-0 bg-zinc-900"><tr class="text-zinc-400 text-xs"><th class="text-left py-2 px-3">CALLSIGN</th><th class="text-left py-2 px-3">ÜLKE</th><th class="text-right py-2 px-3">İRTİFA</th><th class="text-right py-2 px-3">HIZ</th><th class="text-center py-2 px-3">SQUAWK</th></tr></thead><tbody>`;
            states.forEach(state => {
                const icao = state[0];
                const callsign = (state[1] || '—').toUpperCase();
                const country = state[2] || '?';
                const alt = state[7] ? Math.round(state[7]) : '—';
                const speed = state[9] ? Math.round(state[9] * 3.6) : '—';
                const squawk = state[14] || '';
                const flag = countryFlags[country] || '🌍';
                if (filter && !callsign.includes(filter) && !country.toUpperCase().includes(filter) && !icao.includes(filter)) return;
                const em = isEmergency(state) ? 'animate-pulse text-red-400' : '';
                html += `<tr onclick="selectAircraft('${icao}', null)" class="border-b border-zinc-800 hover:bg-zinc-800 cursor-pointer \( {em}"><td class="px-3 py-3 font-mono"> \){callsign}</td><td class="px-3 py-3">\( {flag} <span class="text-xs"> \){country}</span></td><td class="px-3 py-3 text-right font-medium">\( {alt}<span class="text-[10px] text-zinc-400">m</span></td><td class="px-3 py-3 text-right font-medium"> \){speed}</td><td class="px-3 py-3 text-center font-mono text-xs \( {['77','76','75'].some(s=>squawk.includes(s))?'text-red-500':''}"> \){squawk||'—'}</td></tr>`;
            });
            html += `</tbody></table>`;
            document.getElementById('aircraft-list').innerHTML = html || `<div class="p-8 text-center text-zinc-400">Uçak yok</div>`;
        }

        function renderStats(states) {
            if (!countryChart) return;
            // Ülke
            const countryCount = {};
            states.forEach(s => { const c = s[2]||'Unknown'; countryCount[c] = (countryCount[c]||0)+1; });
            const top = Object.entries(countryCount).sort((a,b)=>b[1]-a[1]).slice(0,8);
            countryChart.data.labels = top.map(x=>x[0].substring(0,8));
            countryChart.data.datasets[0].data = top.map(x=>x[1]);
            countryChart.update('none');

            // Hız
            const speedBins = [0,200,400,600,800,1000];
            const speedCounts = new Array(speedBins.length-1).fill(0);
            states.forEach(s => {
                const kmh = s[9] ? s[9]*3.6 : 0;
                for (let i=0; i<speedBins.length-1; i++) if (kmh >= speedBins[i] && kmh < speedBins[i+1]) { speedCounts[i]++; break; }
            });
            speedChart.data.labels = speedBins.slice(0,-1).map((v,i)=>`\( {v}- \){speedBins[i+1]}`);
            speedChart.data.datasets[0].data = speedCounts;
            speedChart.update('none');

            // İrtifa
            const altBins = [0,3000,6000,9000,12000,15000];
            const altCounts = new Array(altBins.length-1).fill(0);
            states.forEach(s => {
                const a = s[7]||0;
                for (let i=0; i<altBins.length-1; i++) if (a >= altBins[i] && a < altBins[i+1]) { altCounts[i]++; break; }
            });
            altChart.data.labels = altBins.slice(0,-1).map((v,i)=>`\( {v}- \){altBins[i+1]}m`);
            altChart.data.datasets[0].data = altCounts;
            altChart.update('none');
        }

        function toggleStats() {
            const p = document.getElementById('stats-panel');
            p.classList.toggle('hidden');
            document.getElementById('stats-toggle-icon').textContent = p.classList.contains('hidden') ? '▼' : '▲';
        }

        function checkAlarms(states) {
            const em = states.filter(isEmergency);
            const banner = document.getElementById('alarm-banner');
            if (em.length) {
                banner.classList.remove('hidden');
                document.getElementById('alarm-text').innerHTML = em.length === 1 ? `🚨 1 acil: ${em[0][1]||em[0][0]}` : `🚨 ${em.length} acil durum uçağı!`;
            } else banner.classList.add('hidden');
        }

        function selectAircraft(icao, stateFromClick) {
            selectedIcao = icao;
            const state = stateFromClick || allStates.find(s => s[0] === icao);
            if (!state) return;
            document.getElementById('detail-panel').classList.remove('hidden');
            document.getElementById('selected-bar').classList.remove('hidden');
            document.getElementById('selected-callsign').textContent = (state[1]||icao).toUpperCase();
            document.getElementById('selected-flag').innerHTML = countryFlags[state[2]] || '🌍';
            document.getElementById('selected-alt').textContent = state[7] ? Math.round(state[7]) : '—';
            document.getElementById('selected-speed').textContent = state[9] ? Math.round(state[9]*3.6) : '—';
            document.getElementById('selected-squawk').innerHTML = state[14] ? `<span class="px-4 py-1 bg-red-500 rounded-3xl">${state[14]}</span>` : '';
            document.getElementById('detail-callsign').textContent = (state[1]||icao).toUpperCase();
            document.getElementById('detail-country').innerHTML = `\( {countryFlags[state[2]]||'🌍'} <span class="font-medium"> \){state[2]||'Bilinmeyen Ülke'}</span>`;
            document.getElementById('detail-alt').innerHTML = `${state[7]?Math.round(state[7]):'—'} <span class="text-sm font-normal">metre</span>`;
            document.getElementById('detail-vrate').innerHTML = `${state[11]?Math.round(state[11]):'—'} <span class="text-sm font-normal">m/dk</span>`;
            document.getElementById('detail-heading').innerHTML = `${state[10]?Math.round(state[10]):'—'}°`;
            document.getElementById('detail-squawk').innerHTML = state[14]||'—';
            drawSpeedGauge(state[9] ? Math.round(state[9]*3.6) : 0);
            if (state[6] && state[5]) map.flyTo([state[6], state[5]], 12, {duration: 1.5});
        }

        function deselectAircraft() {
            selectedIcao = null;
            document.getElementById('detail-panel').classList.add('hidden');
            document.getElementById('selected-bar').classList.add('hidden');
        }

        function drawSpeedGauge(speed) {
            const canvas = document.getElementById('speed-gauge');
            const ctx = canvas.getContext('2d');
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            const cx = canvas.width/2, cy = canvas.height-10, r = 90;
            ctx.beginPath(); ctx.arc(cx, cy, r, Math.PI*0.8, Math.PI*2.2); ctx.lineWidth=18; ctx.strokeStyle='#27272a'; ctx.lineCap='round'; ctx.stroke();
            const maxS = 1000; const angle = (speed/maxS)*1.4*Math.PI + Math.PI*0.8;
            ctx.beginPath(); ctx.arc(cx, cy, r, Math.PI*0.8, angle); ctx.lineWidth=18; ctx.strokeStyle='#22d3ee'; ctx.lineCap='round'; ctx.stroke();
            ctx.save(); ctx.translate(cx,cy); ctx.rotate(angle); ctx.fillStyle='#fff'; ctx.fillRect(-4, -r+20, 8, r-10); ctx.restore();
            ctx.beginPath(); ctx.arc(cx, cy, 12, 0, Math.PI*2); ctx.fillStyle='#111'; ctx.fill();
            ctx.fillStyle = '#fff'; ctx.font = '700 32px monospace'; ctx.textAlign='center'; ctx.fillText(speed, cx, cy+55);
            ctx.font = '400 11px Inter'; ctx.fillText('km/h', cx, cy+72);
        }

        function centerOnGPS() {
            if (navigator.geolocation) navigator.geolocation.getCurrentPosition(p => map.flyTo([p.coords.latitude, p.coords.longitude], 10));
        }

        function toggleWeather() {
            alert('🌦️ OpenWeatherMap API Key gerekli (isteğe bağlı). Henüz entegre edilmedi.');
        }

        function toggleNightMode() {
            alert('🌙 Terminator katmanı simüle edildi (gerçek için Leaflet.Terminator eklenebilir).');
        }

        function openFlightAware() {
            const state = allStates.find(s => s[0] === selectedIcao);
            if (state) window.open(`https://www.flightaware.com/live/flight/${(state[1]||selectedIcao).trim()}`, '_blank');
        }

        function copyCoordinates() {
            const state = allStates.find(s => s[0] === selectedIcao);
            if (state && state[6] && state[5]) {
                navigator.clipboard.writeText(`${state[6].toFixed(5)}, ${state[5].toFixed(5)}`).then(() => alert('✅ Koordinat kopyalandı!'));
            }
        }

        function handleKey(e) {
            if (e.key === 'f' || e.key === 'F') { e.preventDefault(); searchInput.focus(); }
            if (e.key === 'c' || e.key === 'C') centerOnGPS();
            if (e.key === 'h' || e.key === 'H') toggleWeather();
            if (e.key === 's' || e.key === 'S') toggleStats();
            if (e.key === 'Escape') deselectAircraft();
            if (e.key === '?') document.getElementById('help-modal').classList.toggle('hidden');
        }

        function startLoadingParticles() {
            const canvas = document.getElementById('loading-canvas');
            canvas.width = window.innerWidth; canvas.height = window.innerHeight;
            canvas.classList.remove('hidden');
            const ctx = canvas.getContext('2d');
            let particles = [];
            class P { constructor() { this.x=Math.random()*canvas.width; this.y=Math.random()*canvas.height; this.size=Math.random()*4+1; this.speed=Math.random()*2+0.5; this.angle=Math.random()*Math.PI*2; } update() { this.x += Math.cos(this.angle)*this.speed; this.y += Math.sin(this.angle)*this.speed; if(this.x<0||this.x>canvas.width) this.angle=Math.PI-this.angle; if(this.y<0||this.y>canvas.height) this.angle=-this.angle; } draw() { ctx.fillStyle='rgba(34,211,238,0.9)'; ctx.fillRect(this.x,this.y,this.size,this.size); } }
            for(let i=0;i<120;i++) particles.push(new P());
            const animate = () => { ctx.clearRect(0,0,canvas.width,canvas.height); particles.forEach(p=>{p.update();p.draw();}); if(!canvas.classList.contains('hidden')) requestAnimationFrame(animate); };
            animate();
            setTimeout(() => canvas.classList.add('hidden'), 2800);
        }

        async function init() {
            initMap();
            searchInput = document.getElementById('search-input');
            searchInput.addEventListener('input', () => renderAircraftList(allStates));

            countryChart = new Chart(document.getElementById('country-chart'), {type:'bar', data:{labels:[], datasets:[{label:'Ülke', data:[], backgroundColor:'#22d3ee'}]}, options:{plugins:{legend:{display:false}}, scales:{y:{grid:{color:'#27272a'}}}}});
            speedChart = new Chart(document.getElementById('speed-chart'), {type:'bar', data:{labels:[], datasets:[{label:'Hız', data:[], backgroundColor:'#67e8f9'}]}, options:{plugins:{legend:{display:false}}}});
            altChart = new Chart(document.getElementById('altitude-chart'), {type:'bar', data:{labels:[], datasets:[{label:'İrtifa', data:[], backgroundColor:'#22d3ee'}]}, options:{plugins:{legend:{display:false}}}});

            startLoadingParticles();
            await updateAircraft();
            updateTimer = setInterval(updateAircraft, 6500);
            window.addEventListener('keydown', handleKey);
            console.log('%c✅ Termux ADS-B Paneli hazır! Random portta çalışıyor.', 'color:#22d3ee;font-size:13px');
        }

        window.onload = init;
    </script>
</body>
</html>"""

# ====================== HTTP HANDLER ======================
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path in ('/', '/index.html'):
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()
            self.wfile.write(HTML.encode('utf-8'))

        elif self.path == '/api/states':
            try:
                req = urllib.request.Request(
                    'https://opensky-network.org/api/states/all',
                    headers={'User-Agent': 'Termux-ADS-B-Radar/1.0 (https://github.com)'}
                )
                with urllib.request.urlopen(req, timeout=12) as resp:
                    data = resp.read()
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(data)
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(f'{{"error": "{str(e)}"}}'.encode('utf-8'))

        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'404 - Sayfa bulunamadi')

    def log_message(self, format, *args):
        return  # sessiz log

class ThreadedServer(ThreadingMixIn, http.server.HTTPServer):
    pass

# ====================== ANA BAŞLATMA ======================
if __name__ == "__main__":
    try:
        # Rastgele boş port (OS otomatik seçer)
        server = ThreadedServer(("", 0), Handler)
        port = server.server_port

        print("\n🚀 ADS-B Termux Radar Paneli BAŞLATILDI!")
        print(f"📡 Random Port: {port}")
        print(f"🌐 Tarayıcıda aç: http://localhost:{port}")
        print("🔥 Otomatik açılıyor (termux-open-url)...")

        # Termux'ta varsa otomatik tarayıcı aç
        try:
            subprocess.call(['termux-open-url', f'http://localhost:{port}'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except:
            print("   (termux-open-url bulunamadı, linki manuel açın)")

        print("⏳ Veri her 6.5 saniyede bir güncelleniyor...")
        print("   Durdurmak için Ctrl + C\n")

        server.serve_forever()

    except KeyboardInterrupt:
        print("\n\n🛑 Sunucu kapatıldı. Görüşürüz!")
    except Exception as e:
        print(f"❌ Hata: {e}")
        sys.exit(1)