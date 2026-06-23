// Établi Atelier — kernel host bootstrap (runs INSIDE the WebView).
//
// Owns the on-device language kernels and bridges their I/O to the Flutter
// shell. Two SEPARATE kernels — no interop. A session is bound to one language.
//
//  • R      — WebR over its PostMessage channel (no SharedArrayBuffer in a
//             system WebView). No mid-execution interrupt; the shell offers a
//             force-restart (worker terminate) instead.
//  • Python — Pyodide on the WebView main thread. Also non-interruptible; a
//             runaway loop blocks this thread, so its force-restart is a native
//             WebView reload driven from Flutter.

import { Console, ChannelType } from '/assets/runtimes/webr/webr.mjs';
import { loadPyodide } from '/assets/runtimes/pyodide/pyodide.mjs';

const WEBR_BASE = '/assets/runtimes/webr/';
const PYODIDE_BASE = '/assets/runtimes/pyodide/';

// --- Flutter bridge -------------------------------------------------------
const pending = [];

function rawEmit(msg) {
  window.flutter_inappwebview.callHandler('onKernelEvent', msg);
}

function emit(type, payload) {
  const msg = { type, payload };
  if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
    rawEmit(msg);
  } else {
    pending.push(msg);
  }
}

window.addEventListener('flutterInAppWebViewPlatformReady', () => {
  while (pending.length) rawEmit(pending.shift());
});

window.addEventListener('error', (e) =>
  emit('status', { kernel: 'host', state: 'error', message: String(e.message || e) }));
window.addEventListener('unhandledrejection', (e) =>
  emit('status', { kernel: 'host', state: 'error', message: String((e.reason && e.reason.message) || e.reason) }));

// --- Plot capture ---------------------------------------------------------
// R draws into the #plot canvas via WebR's canvas device; matplotlib is
// captured by savefig. Both are emitted to Flutter as PNG data URLs.
const plotCanvas = document.getElementById('plot');
const plotCtx = plotCanvas.getContext('2d');
let rPlotDirty = false;

function flushRPlot() {
  if (!rPlotDirty) return;
  rPlotDirty = false;
  emit('plot', { kernel: 'r', png: plotCanvas.toDataURL('image/png') });
}

// --- WebR (R) kernel ------------------------------------------------------
let rConsole = null;
let rReady = false;

async function startR() {
  if (rConsole) return;
  emit('status', { kernel: 'r', state: 'loading' });
  try {
    rConsole = new Console(
      {
        stdout: (line) => emit('stdout', { kernel: 'r', text: line }),
        stderr: (line) => emit('stderr', { kernel: 'r', text: line }),
        prompt: (p) => {
          // Returning to a prompt means a submission finished — emit any plot.
          flushRPlot();
          emit('prompt', { kernel: 'r', text: p });
        },
        canvasImage: (image) => {
          plotCtx.drawImage(image, 0, 0);
          rPlotDirty = true;
        },
        canvasNewPage: () => {
          // A new page begins: emit the previous plot, then clear.
          flushRPlot();
          plotCtx.clearRect(0, 0, plotCanvas.width, plotCanvas.height);
        },
      },
      { baseUrl: WEBR_BASE, channelType: ChannelType.PostMessage },
    );
    rConsole.run();
    await rConsole.webR.init();
    rReady = true;
    emit('status', { kernel: 'r', state: 'ready' });
  } catch (e) {
    emit('status', { kernel: 'r', state: 'error', message: String((e && e.message) || e) });
  }
}

async function restartR() {
  try {
    if (rConsole) await rConsole.webR.close();
  } catch (_) {}
  rConsole = null;
  rReady = false;
  return startR();
}

// --- Pyodide (Python) kernel ---------------------------------------------
let pyodide = null;
let pyReady = false;
let pyStarting = false;

async function startPython() {
  if (pyodide || pyStarting) return;
  pyStarting = true;
  emit('status', { kernel: 'python', state: 'loading' });
  try {
    pyodide = await loadPyodide({ indexURL: PYODIDE_BASE });
    pyodide.setStdout({ batched: (s) => emit('stdout', { kernel: 'python', text: s }) });
    pyodide.setStderr({ batched: (s) => emit('stderr', { kernel: 'python', text: s }) });
    // Headless matplotlib so savefig works without a display; we capture
    // figures after each run rather than relying on plt.show().
    pyodide.runPython("import os; os.environ['MPLBACKEND'] = 'AGG'");
    pyReady = true;
    emit('status', { kernel: 'python', state: 'ready' });
    const v = pyodide.runPython('import sys; sys.version.split()[0]');
    emit('stdout', { kernel: 'python', text: 'Python ' + v + ' (Pyodide) ready.' });
  } catch (e) {
    emit('status', { kernel: 'python', state: 'error', message: String((e && e.message) || e) });
  } finally {
    pyStarting = false;
  }
}

async function runPython(code) {
  if (!pyodide) return;
  emit('stdin', { kernel: 'python', text: code });
  try {
    // Auto-load any bundled package referenced by the code's imports.
    await pyodide.loadPackagesFromImports(code);
  } catch (e) {
    emit('stderr', {
      kernel: 'python',
      text: 'Package load warning: ' + String((e && e.message) || e),
    });
  }
  try {
    const result = await pyodide.runPythonAsync(code);
    if (result !== undefined && result !== null) {
      let text;
      if (typeof result === 'object' && typeof result.toString === 'function') {
        text = result.toString();
        if (typeof result.destroy === 'function') result.destroy();
      } else {
        text = String(result);
      }
      if (text.length) emit('stdout', { kernel: 'python', text });
    }
  } catch (e) {
    emit('stderr', { kernel: 'python', text: String((e && e.message) || e) });
  } finally {
    capturePyPlots();
    emit('runComplete', { kernel: 'python' });
  }
}

// Emit any matplotlib figures created by the last run as PNGs. Only touches
// matplotlib if the user has already imported pyplot (no forced load).
function capturePyPlots() {
  if (!pyodide) return;
  let proxy;
  try {
    proxy = pyodide.runPython(`
import sys, io, base64
_figs = []
if 'matplotlib.pyplot' in sys.modules:
    _plt = sys.modules['matplotlib.pyplot']
    for _n in _plt.get_fignums():
        _buf = io.BytesIO()
        _plt.figure(_n).savefig(_buf, format='png', bbox_inches='tight')
        _figs.append(base64.b64encode(_buf.getvalue()).decode('ascii'))
    _plt.close('all')
_figs
`);
    const arr = proxy && proxy.toJs ? proxy.toJs() : proxy;
    if (proxy && proxy.destroy) proxy.destroy();
    if (arr) {
      for (const b64 of arr) {
        emit('plot', { kernel: 'python', png: 'data:image/png;base64,' + b64 });
      }
    }
  } catch (e) {
    emit('stderr', { kernel: 'python', text: 'Plot capture warning: ' + String((e && e.message) || e) });
  }
}

// --- Shared virtual filesystem bridge -------------------------------------
// Both kernels have SEPARATE Emscripten filesystems. The Flutter workspace is
// canonical; before a run it is pushed into the active kernel's /workspace, and
// after a run the kernel's /workspace is snapshotted back. That round-trip is
// what lets a file written in R be read in Python.

const WS = '/workspace';

function u8ToB64(u8) {
  let s = '';
  const chunk = 0x8000;
  for (let i = 0; i < u8.length; i += chunk) {
    s += String.fromCharCode.apply(null, u8.subarray(i, i + chunk));
  }
  return btoa(s);
}
function b64ToU8(b64) {
  const s = atob(b64);
  const u = new Uint8Array(s.length);
  for (let i = 0; i < s.length; i++) u[i] = s.charCodeAt(i);
  return u;
}
function dirOf(path) {
  const i = path.lastIndexOf('/');
  return i <= 0 ? '/' : path.slice(0, i);
}

// ---- WebR FS helpers (async; FS lives in the worker) ----
// WebR's FS.lookupPath returns an Emscripten FSNode whose folder-ness is
// readable as a flag on some versions and a getter on others; on the WebR
// release we bundle, neither `isFolder` nor `isDirectory` is reliably exposed.
// Use the POSIX file-mode bits instead (S_IFMT mask, S_IFDIR value) — that
// surface IS stable on Emscripten and what FS.isDir uses internally.
const S_IFMT = 0o170000;
const S_IFDIR = 0o040000;
function isDirMode(mode) {
  return typeof mode === 'number' && (mode & S_IFMT) === S_IFDIR;
}
async function rIsDir(path) {
  try {
    const st = await rConsole.webR.FS.stat(path);
    return isDirMode(st && st.mode);
  } catch (_) { return false; }
}
async function rReaddir(path) {
  // Prefer FS.readdir if exposed; otherwise fall back to the node's contents.
  try {
    const r = await rConsole.webR.FS.readdir(path);
    if (Array.isArray(r)) {
      return r.filter((n) => n !== '.' && n !== '..');
    }
  } catch (_) {}
  try {
    const node = (await rConsole.webR.FS.lookupPath(path)).node;
    return Object.keys(node.contents || {});
  } catch (_) { return []; }
}
async function rMkdirp(dir) {
  const parts = dir.split('/').filter(Boolean);
  let cur = '';
  for (const part of parts) {
    cur += '/' + part;
    try { await rConsole.webR.FS.mkdir(cur); } catch (_) {}
  }
}
async function rRemoveChildren(path) {
  if (!(await rIsDir(path))) return;
  for (const name of await rReaddir(path)) {
    const child = path + '/' + name;
    if (await rIsDir(child)) {
      await rRemoveChildren(child);
      try { await rConsole.webR.FS.rmdir(child); } catch (_) {}
    } else {
      try { await rConsole.webR.FS.unlink(child); } catch (_) {}
    }
  }
}
async function rSnapshot(path, out) {
  if (await rIsDir(path)) {
    for (const name of await rReaddir(path)) {
      await rSnapshot(path + '/' + name, out);
    }
  } else {
    try {
      const bytes = await rConsole.webR.FS.readFile(path);
      out.push({ path: path.slice(WS.length + 1), b64: u8ToB64(bytes) });
    } catch (_) {}
  }
}

// ---- Pyodide FS helpers (sync; main thread) ----
function pyMkdirp(dir) { pyodide.FS.mkdirTree(dir); }
function pyRemoveChildren(path) {
  let st;
  try { st = pyodide.FS.lstat(path); } catch (_) { return; }
  if (!pyodide.FS.isDir(st.mode)) return;
  for (const name of pyodide.FS.readdir(path)) {
    if (name === '.' || name === '..') continue;
    const child = path + '/' + name;
    const cst = pyodide.FS.lstat(child);
    if (pyodide.FS.isDir(cst.mode)) {
      pyRemoveChildren(child);
      try { pyodide.FS.rmdir(child); } catch (_) {}
    } else {
      try { pyodide.FS.unlink(child); } catch (_) {}
    }
  }
}
function pySnapshot(path, out) {
  let st;
  try { st = pyodide.FS.lstat(path); } catch (_) { return; }
  if (pyodide.FS.isDir(st.mode)) {
    for (const name of pyodide.FS.readdir(path)) {
      if (name === '.' || name === '..') continue;
      pySnapshot(path + '/' + name, out);
    }
  } else {
    const bytes = pyodide.FS.readFile(path);
    out.push({ path: path.slice(WS.length + 1), b64: u8ToB64(bytes) });
  }
}

window.EtabliFS = {
  // Replace the kernel's /workspace with the given files, then chdir into it.
  // Returns `null` so the InAppWebView async-JS bridge always has a
  // JSON-serializable result. (Returning {ok: true, count: N} sometimes trips
  // a "JavaScript execution returned a result of an unsupported type" error
  // on iOS for large or mixed payloads.)
  async push(lang, files) {
    if (lang === 'r' && rConsole) {
      try { await rConsole.webR.FS.mkdir(WS); } catch (_) {}
      await rRemoveChildren(WS);
      for (const f of files) {
        const full = WS + '/' + f.path;
        await rMkdirp(dirOf(full));
        await rConsole.webR.FS.writeFile(full, b64ToU8(f.b64));
      }
      try { await rConsole.webR.evalRVoid("setwd('" + WS + "')"); } catch (_) {}
    } else if (lang === 'python' && pyodide) {
      pyMkdirp(WS);
      pyRemoveChildren(WS);
      for (const f of files) {
        const full = WS + '/' + f.path;
        pyMkdirp(dirOf(full));
        pyodide.FS.writeFile(full, b64ToU8(f.b64));
      }
      try { pyodide.runPython("import os; os.chdir('" + WS + "')"); } catch (_) {}
    }
    return null;
  },

  // Snapshot every file under the kernel's /workspace.
  async snapshot(lang) {
    const out = [];
    if (lang === 'r' && rConsole) await rSnapshot(WS, out);
    else if (lang === 'python' && pyodide) pySnapshot(WS, out);
    return out;
  },
};

// --- Package installation (ONLINE) ----------------------------------------
// The only feature that needs the network: R from repo.r-wasm.org, Python via
// micropip from PyPI. Each requested package is reported installed/failed so
// the shell can warn clearly on misses or unmet WASM dependencies.

window.EtabliPkg = {
  async installR(names) {
    if (!rConsole) return { ok: false, error: 'R kernel not ready', results: [] };
    try {
      await rConsole.webR.installPackages(names);
    } catch (e) {
      // Network/repo-level failure — fall through and report per-package below.
    }
    const results = [];
    for (const name of names) {
      let ok = false;
      try {
        ok = await rConsole.webR.evalRBoolean(
          JSON.stringify(name) + ' %in% rownames(installed.packages())');
      } catch (_) {
        ok = false;
      }
      results.push({
        name,
        ok,
        message: ok ? 'installed' : 'not available in the WebR WASM repository',
      });
    }
    return { ok: true, results };
  },

  async installPython(names) {
    if (!pyodide) return { ok: false, error: 'Python kernel not ready', results: [] };
    try {
      await pyodide.loadPackage('micropip');
    } catch (e) {
      return { ok: false, error: 'micropip unavailable: ' + String((e && e.message) || e), results: [] };
    }
    const micropip = pyodide.pyimport('micropip');
    const results = [];
    for (const name of names) {
      try {
        await micropip.install(name);
        results.push({ name, ok: true, message: 'installed' });
      } catch (e) {
        results.push({
          name,
          ok: false,
          message: String((e && e.message) || e),
        });
      }
    }
    if (micropip.destroy) micropip.destroy();
    return { ok: true, results };
  },
};

// --- Public API exposed to the Flutter shell ------------------------------
window.EtabliKernel = {
  start(lang) {
    if (lang === 'r') return startR();
    if (lang === 'python') return startPython();
  },
  stdin(lang, code) {
    if (lang === 'r' && rConsole) {
      emit('stdin', { kernel: 'r', text: code });
      rConsole.stdin(code);
    } else if (lang === 'python') {
      return runPython(code);
    }
  },
  restart(lang) {
    // Python restart is handled by a native WebView reload from Flutter.
    if (lang === 'r') return restartR();
  },
  isReady(lang) {
    if (lang === 'r') return rReady;
    if (lang === 'python') return pyReady;
    return false;
  },
};

emit('status', { kernel: 'host', state: 'loaded' });
