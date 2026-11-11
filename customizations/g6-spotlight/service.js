'use strict';
/*
 * Spotlight View for Glasshouse: keeps the overlay applied across Glasshouse
 * updates, and stores and serves its settings.
 *
 * Glasshouse's updater replaces every file a release ships and leaves the rest
 * alone, so the overlay's own files (assets/g6, the extra fonts) survive, but
 * home.html comes back stock. Every 30 s this puts back:
 *   1. the one line in home.html that loads assets/g6/spotlight.{css,js};
 *   2. Guide-first: a one-line swap in how Home adds the Guide tile. If a
 *      release changes that line, the swap is skipped and Guide stays last.
 * It also restores assets/g6 and the fonts if they ever go missing.
 *
 * Glasshouse keeps every asset in memory once served (ASSET_CACHE in
 * lib/routes.js), so after changing any of them this restarts Glasshouse, then
 * reloads Home if it is on screen. Settings do not go through Glasshouse: Home
 * reads them from this service, so changing them only reloads Home.
 *
 * Settings page and API on port 8090:
 *   GET  /          the settings page
 *   GET  /settings  { on, font }
 *   POST /settings  { on?, font? }
 */
const fs = require('fs');
const path = require('path');
const http = require('http');
const { execFile } = require('child_process');

const HERE = __dirname;
const TVWEB = '/var/lib/tvweb';
const ASSETS = path.join(TVWEB, 'assets');
const HOME = path.join(ASSETS, 'home.html');
const UPDATE_STAGE = path.join(TVWEB, '.update');
const OVERLAY_SRC = path.join(HERE, 'overlay');
const OVERLAY_DST = path.join(ASSETS, 'g6');
const FONTS_SRC = path.join(HERE, 'fonts');
const FONTS_DST = path.join(ASSETS, 'fonts');
const SETTINGS = path.join(HERE, 'settings.json');
const PAGE = path.join(HERE, 'settings.html');
const PORT = 8090;
const TVWEBCTL = path.join(TVWEB, 'tvwebctl');
const EVERY_MS = 30000;

const MARK = '<!-- g6-spotlight -->';
const TAG = MARK + '<link rel="stylesheet" href="/assets/g6/spotlight.css"><script src="/assets/g6/spotlight.js"></script>';
const GUIDE_STOCK = "out.push({ id: GUIDE_TILE, guide: true, name: t('home.tv.guide', 'Guide') });";
const GUIDE_G6 = "((window.G6 && G6.guideFirst()) ? out.unshift : out.push).call(out, { id: GUIDE_TILE, guide: true, name: t('home.tv.guide', 'Guide') }); /* g6-spotlight */";
const FONTS = ['default', 'system', 'geist', 'inter'];

let guideWarned = false;

function log(m) { console.log(new Date().toISOString() + ' ' + m); }

function readSettings() {
  try {
    const s = JSON.parse(fs.readFileSync(SETTINGS, 'utf8'));
    return { on: s.on === true, font: FONTS.includes(s.font) ? s.font : 'system' };
  } catch (e) {
    return { on: false, font: 'system' };
  }
}

function writeAtomic(file, text) {
  const tmp = file + '.g6tmp';
  fs.writeFileSync(tmp, text);
  fs.renameSync(tmp, file);
}

function same(a, b) {
  try { return fs.readFileSync(a).equals(fs.readFileSync(b)); } catch (e) { return false; }
}

// Copies what is missing or different; true when anything was copied.
function syncDir(src, dst) {
  let changed = false;
  fs.mkdirSync(dst, { recursive: true });
  for (const f of fs.readdirSync(src)) {
    const s = path.join(src, f), d = path.join(dst, f);
    if (!same(s, d)) { fs.copyFileSync(s, d); changed = true; }
  }
  return changed;
}

function luna(uri, payload, cb) {
  execFile('luna-send', ['-n', '1', '-w', '5000', uri, JSON.stringify(payload)], { timeout: 8000 },
    (err, out) => cb && cb(err, String(out || '')));
}

// Reloads Home only while it is on screen, so an update never pulls the TV
// away from what is being watched. A Home in the background picks the overlay
// up the next time it loads.
function reloadHomeIfShown() {
  luna('luna://com.webos.applicationManager/getForegroundAppInfo', {}, (err, out) => {
    if (!err && /"appId"\s*:\s*"com\.webos\.app\.home"/.test(out)) {
      luna('luna://com.webos.applicationManager/launch', { id: 'com.webos.app.home' });
      log('reloaded Home');
    }
  });
}


// Glasshouse serves assets from memory, so it has to restart to see changed files.
function restartGlasshouse() {
  log('restarting Glasshouse to serve the changed files');
  execFile(TVWEBCTL, ['restart'], { timeout: 60000 }, err => {
    if (err) log('tvwebctl restart: ' + err.message);
    setTimeout(reloadHomeIfShown, 5000);
  });
}

function ensure() {
  try {
    if (fs.existsSync(UPDATE_STAGE)) return; // the updater is mid-install
    let changed = syncDir(OVERLAY_SRC, OVERLAY_DST);
    changed = syncDir(FONTS_SRC, FONTS_DST) || changed;

    // Leave a file that was written moments ago alone; the updater may still be at it.
    if (Date.now() - fs.statSync(HOME).mtimeMs < 10000) return;
    let html = fs.readFileSync(HOME, 'utf8');
    const before = html;
    if (!html.includes(MARK)) {
      if (html.includes('</head>')) html = html.replace('</head>', TAG + '\n</head>');
      else log('home.html has no </head>: overlay not loaded');
    }
    if (!html.includes(GUIDE_G6)) {
      if (html.includes(GUIDE_STOCK)) html = html.replace(GUIDE_STOCK, GUIDE_G6);
      else if (!guideWarned) { log('Guide-first skipped: Home adds the Guide tile differently in this release'); guideWarned = true; }
    }
    if (html !== before) {
      writeAtomic(HOME, html);
      log('reapplied the overlay to home.html');
      changed = true;
    }
    if (changed) restartGlasshouse();
  } catch (e) {
    log('check failed: ' + e.message);
  }
}

function send(res, code, type, body) {
  res.writeHead(code, { 'Content-Type': type, 'Cache-Control': 'no-store' });
  res.end(body);
}

http.createServer((req, res) => {
  const url = req.url.split('?')[0];
  if (req.method === 'GET' && url === '/') {
    return fs.readFile(PAGE, (err, buf) => err ? send(res, 500, 'text/plain', 'settings page missing')
      : send(res, 200, 'text/html; charset=utf-8', buf));
  }
  if (req.method === 'GET' && url === '/settings') {
    // Read by Home, which is served from Glasshouse's port.
    res.setHeader('Access-Control-Allow-Origin', '*');
    return send(res, 200, 'application/json', JSON.stringify(readSettings()));
  }
  if (req.method === 'POST' && url === '/settings') {
    let body = '';
    req.on('data', d => { body += d; if (body.length > 1024) req.destroy(); });
    req.on('end', () => {
      let j;
      try { j = JSON.parse(body); } catch (e) { return send(res, 400, 'application/json', '{"ok":false,"error":"malformed JSON"}'); }
      const s = readSettings();
      if (typeof j.on === 'boolean') s.on = j.on;
      if (FONTS.includes(j.font)) s.font = j.font;
      try { writeAtomic(SETTINGS, JSON.stringify(s)); } catch (e) {
        return send(res, 500, 'application/json', JSON.stringify({ ok: false, error: e.message }));
      }
      reloadHomeIfShown();
      log('settings: ' + JSON.stringify(s));
      send(res, 200, 'application/json', JSON.stringify(Object.assign({ ok: true }, s)));
    });
    return;
  }
  send(res, 404, 'text/plain', 'not found');
}).on('error', e => { log('settings server: ' + e.message); process.exit(1); })
  .listen(PORT, () => log('running; settings on port ' + PORT));

ensure();
setInterval(ensure, EVERY_MS);
