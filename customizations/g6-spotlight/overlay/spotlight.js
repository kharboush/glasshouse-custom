/*
 * Spotlight View for Glasshouse Home.
 *
 * Loaded from <head> by the one line the g6-spotlight service keeps in
 * home.html. It reads the settings from that service (port 8090), then:
 *  - keeps "g6-custom g6-font-<font>" on #stage while Spotlight View is on
 *    (Home rebuilds that class list itself on every change);
 *  - shows the date in its short form ("Wed, Nov 11");
 *  - tells the service's Guide-first edit whether to put Guide first.
 * Alternative View wins if both are on, as it did in the original patch.
 */
(function () {
  'use strict';
  var FONTS = ['default', 'system', 'geist', 'inter'];
  var CACHE = 'g6Spotlight';
  var settings = { on: false, font: 'system' };

  // Synchronous on purpose: a tiny local answer, read before Home builds its
  // rows, so Guide-first is right on the first render. If the service is not
  // up yet, the last settings seen are used.
  try {
    var x = new XMLHttpRequest();
    x.open('GET', location.protocol + '//' + (location.hostname || '127.0.0.1') + ':8090/settings', false);
    x.send();
    if (x.status !== 200) throw new Error('settings: HTTP ' + x.status);
    settings = JSON.parse(x.responseText);
    try { localStorage.setItem(CACHE, JSON.stringify(settings)); } catch (e) { /* no storage */ }
  } catch (e) {
    try { settings = JSON.parse(localStorage.getItem(CACHE)) || settings; } catch (e2) { /* stay off */ }
  }
  var on = settings.on === true;
  var font = FONTS.indexOf(settings.font) !== -1 ? settings.font : 'system';

  window.G6 = { guideFirst: function () { return on; } };

  function applyClass() {
    var st = document.getElementById('stage');
    if (!st) return;
    var cls = st.className.replace(/\s*\bg6-(?:custom|font-[a-z]+)\b/g, '');
    if (on && !/\balternative\b/.test(cls)) cls += ' g6-custom g6-font-' + font;
    if (cls !== st.className) st.className = cls;
  }

  function shortDate() {
    var el = document.getElementById('date');
    if (!el || !on) return;
    var lang = (window.I18N && I18N.lang) ? I18N.lang() : 'en';
    var loc = lang === 'en' ? 'en-US' : lang;
    var s;
    try { s = new Date().toLocaleDateString(loc, { weekday: 'short', month: 'short', day: 'numeric' }); } catch (e) { return; }
    if (s && el.textContent !== s) el.textContent = s;
  }

  function start() {
    applyClass();
    shortDate();
    var st = document.getElementById('stage');
    if (st) new MutationObserver(applyClass).observe(st, { attributes: true, attributeFilter: ['class'] });
    var d = document.getElementById('date');
    if (d) new MutationObserver(shortDate).observe(d, { childList: true, characterData: true, subtree: true });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
  else start();
})();
