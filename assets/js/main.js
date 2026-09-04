/* matacic.net — the only bundled script.
   Theme toggle · mobile menu · code-copy buttons · ToC active section · giscus theme sync.
   Everything here is progressive enhancement; the site works without it. */
(function () {
  'use strict';
  var d = document, root = d.documentElement, KEY = 'theme';
  var mq = window.matchMedia ? window.matchMedia('(prefers-color-scheme: dark)') : null;

  function resolved() {
    var t = root.getAttribute('data-theme');
    if (t === 'light' || t === 'dark') return t;
    return mq && mq.matches ? 'dark' : 'light';
  }

  function syncGiscus(theme) {
    var f = d.querySelector('iframe.giscus-frame');
    if (f && f.contentWindow) {
      f.contentWindow.postMessage({ giscus: { setConfig: { theme: theme } } }, 'https://giscus.app');
    }
  }

  /* Theme toggle: flips the resolved theme, persists it, re-labels itself. */
  var toggle = d.querySelector('.theme-toggle');
  function labelToggle() {
    var next = resolved() === 'dark' ? 'light' : 'dark';
    toggle.setAttribute('aria-label', 'Switch to ' + next + ' theme');
    toggle.title = 'Switch to ' + next + ' theme';
  }
  if (toggle) {
    labelToggle();
    toggle.addEventListener('click', function () {
      var next = resolved() === 'dark' ? 'light' : 'dark';
      root.setAttribute('data-theme', next);
      try { localStorage.setItem(KEY, next); } catch (e) { /* storage unavailable */ }
      labelToggle();
      syncGiscus(next);
    });
    if (mq && mq.addEventListener) {
      mq.addEventListener('change', function () {
        if (!root.getAttribute('data-theme')) { labelToggle(); syncGiscus(resolved()); }
      });
    }
  }

  /* Mobile menu */
  var menuBtn = d.querySelector('.nav-toggle');
  if (menuBtn) {
    menuBtn.addEventListener('click', function () {
      var open = menuBtn.getAttribute('aria-expanded') === 'true';
      menuBtn.setAttribute('aria-expanded', open ? 'false' : 'true');
      menuBtn.setAttribute('aria-label', open ? 'Open menu' : 'Close menu');
    });
  }

  /* Code-copy buttons, injected into the header bar of every code block in content. */
  var live = d.getElementById('live-status');
  function announce(msg) {
    if (!live) return;
    live.textContent = '';
    setTimeout(function () { live.textContent = msg; }, 50);
  }
  function copyText(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      return navigator.clipboard.writeText(text).catch(function () { return legacyCopy(text); });
    }
    return legacyCopy(text);
  }
  function legacyCopy(text) {
    return new Promise(function (res, rej) {
      var ta = d.createElement('textarea');
      ta.value = text;
      ta.setAttribute('readonly', '');
      ta.style.position = 'fixed';
      ta.style.opacity = '0';
      d.body.appendChild(ta);
      ta.select();
      var ok = false;
      try { ok = d.execCommand('copy'); } catch (e) { ok = false; }
      d.body.removeChild(ta);
      ok ? res() : rej();
    });
  }
  d.querySelectorAll('.prose figure.code').forEach(function (fig) {
    var pre = fig.querySelector('pre'), head = fig.querySelector('.code-head');
    if (!pre || !head) return;
    var btn = d.createElement('button');
    btn.type = 'button';
    btn.className = 'copy-btn';
    btn.textContent = 'Copy';
    btn.setAttribute('aria-label', 'Copy code to clipboard');
    var timer;
    function flash(label, cls, msg) {
      btn.textContent = label;
      if (cls) btn.classList.add(cls);
      announce(msg);
      clearTimeout(timer);
      timer = setTimeout(function () { btn.textContent = 'Copy'; btn.classList.remove('is-copied'); }, 1500);
    }
    btn.addEventListener('click', function () {
      copyText(pre.innerText.replace(/\n$/, '')).then(
        function () { flash('Copied ✓', 'is-copied', 'Code copied to clipboard'); },
        function () { flash('Failed', null, 'Copy failed'); }
      );
    });
    head.appendChild(btn);
  });

  /* Table of contents: highlight the section currently at the top of the viewport. */
  var rail = d.querySelector('.toc-rail');
  if (rail && 'IntersectionObserver' in window) {
    var links = {}, active = null;
    rail.querySelectorAll('a[href^="#"]').forEach(function (a) {
      links[decodeURIComponent(a.getAttribute('href').slice(1))] = a;
    });
    var heads = Array.prototype.filter.call(
      d.querySelectorAll('.article-body h2[id], .article-body h3[id]'),
      function (h) { return !!links[h.id]; }
    );
    function setActive(id) {
      if (active) active.classList.remove('is-active');
      active = links[id] || null;
      if (active) active.classList.add('is-active');
    }
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) { if (e.isIntersecting) setActive(e.target.id); });
    }, { rootMargin: '0px 0px -70% 0px', threshold: 0 });
    heads.forEach(function (h) { io.observe(h); });
    if (heads.length) setActive(heads[0].id);
  }

  /* giscus: the partial only renders a configured container; the script is added here so
     data-theme matches the resolved site theme on first paint. */
  var c = d.querySelector('.comments[data-giscus-repo]');
  if (c) {
    var s = d.createElement('script');
    s.src = 'https://giscus.app/client.js';
    var attrs = {
      'repo': c.getAttribute('data-giscus-repo'),
      'repo-id': c.getAttribute('data-giscus-repo-id'),
      'category': c.getAttribute('data-giscus-category'),
      'category-id': c.getAttribute('data-giscus-category-id'),
      'mapping': c.getAttribute('data-giscus-mapping') || 'pathname',
      'strict': '0',
      'reactions-enabled': '1',
      'emit-metadata': '0',
      'input-position': 'bottom',
      'theme': resolved(),
      'lang': 'en'
    };
    Object.keys(attrs).forEach(function (k) { s.setAttribute('data-' + k, attrs[k]); });
    s.crossOrigin = 'anonymous';
    s.async = true;
    c.appendChild(s);
  }
})();
