// Copyright 2026 Raban Heller
// SPDX-License-Identifier: Apache-2.0

// Bridges the in-WebView kernels (R via WebR, Python via Pyodide) to the
// Flutter shell. The WebView calls back through the `onKernelEvent` JS handler
// into [handleEvent]; the shell drives the kernels by evaluating
// `window.EtabliKernel.*`. ChangeNotifier so console UIs rebuild on new output.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../data/settings_store.dart';

enum KernelState { idle, loading, ready, error }

enum ConsoleStream { stdout, stderr, input, prompt, system }

class ConsoleLine {
  const ConsoleLine(this.text, this.stream);
  final String text;
  final ConsoleStream stream;
}

class PackageResult {
  const PackageResult(this.name, this.ok, this.message);
  final String name;
  final bool ok;
  final String message;
}

class KernelController extends ChangeNotifier {
  InAppWebViewController? _web;
  bool _hostReady = false;

  // Languages the shell has asked to start; replayed once the host is ready
  // and after a reload.
  final Set<KernelLanguage> _wanted = <KernelLanguage>{};

  final Map<KernelLanguage, List<ConsoleLine>> _lines = {
    KernelLanguage.r: <ConsoleLine>[],
    KernelLanguage.python: <ConsoleLine>[],
  };
  final Map<KernelLanguage, KernelState> _state = {
    KernelLanguage.r: KernelState.idle,
    KernelLanguage.python: KernelState.idle,
  };
  final Map<KernelLanguage, List<Uint8List>> _plots = {
    KernelLanguage.r: <Uint8List>[],
    KernelLanguage.python: <Uint8List>[],
  };
  final Map<KernelLanguage, List<PackageResult>> _pkgLog = {
    KernelLanguage.r: <PackageResult>[],
    KernelLanguage.python: <PackageResult>[],
  };
  bool _installing = false;
  bool get installing => _installing;

  String? lastError;

  /// Fired when a kernel reaches the ready state (good time to push the
  /// workspace into it).
  void Function(KernelLanguage lang)? onKernelReady;

  /// Fired when a kernel finishes executing a submission (good time to pull
  /// kernel-written files back to the workspace).
  void Function(KernelLanguage lang)? onRunComplete;

  // Tracks whether a submission is in flight, so R's prompt-on-startup isn't
  // mistaken for a run completing.
  final Set<KernelLanguage> _running = <KernelLanguage>{};

  List<ConsoleLine> linesFor(KernelLanguage lang) =>
      List.unmodifiable(_lines[lang]!);
  KernelState stateFor(KernelLanguage lang) => _state[lang]!;
  List<Uint8List> plotsFor(KernelLanguage lang) =>
      List.unmodifiable(_plots[lang]!);

  void clearPlots(KernelLanguage lang) {
    _plots[lang]!.clear();
    notifyListeners();
  }

  List<PackageResult> packageLogFor(KernelLanguage lang) =>
      List.unmodifiable(_pkgLog[lang]!);

  static String _id(KernelLanguage lang) =>
      lang == KernelLanguage.r ? 'r' : 'python';

  // --- WebView wiring -----------------------------------------------------
  void attachWebView(InAppWebViewController controller) {
    _web = controller;
  }

  /// Called when the host page finishes (re)loading. Boots any kernels the
  /// shell has requested.
  Future<void> onHostLoaded() async {
    _hostReady = true;
    for (final KernelLanguage lang in _wanted) {
      await _start(lang);
    }
  }

  /// Idempotently ensure [lang]'s kernel is booting/booted. Safe to call before
  /// the host is ready — the request is queued.
  Future<void> ensureStarted(KernelLanguage lang) async {
    final bool firstRequest = _wanted.add(lang);
    if (_hostReady && firstRequest) await _start(lang);
  }

  Future<void> _start(KernelLanguage lang) async {
    // `start()` returns a Promise; ignoring its value via `void` keeps the
    // JS bridge from trying to serialize an unsupported result type.
    await _eval(
        "void (window.EtabliKernel && window.EtabliKernel.start('${_id(lang)}'));");
  }

  // --- Incoming events from the WebView -----------------------------------
  void handleEvent(Object? raw) {
    final Map<String, dynamic> msg = _asMap(raw);
    final String type = msg['type'] as String? ?? '';
    final Map<String, dynamic> payload = _asMap(msg['payload']);
    final KernelLanguage? lang = _langOf(payload['kernel'] as String?);

    switch (type) {
      case 'stdout':
        if (lang != null) _add(lang, payload['text'] as String? ?? '', ConsoleStream.stdout);
      case 'stderr':
        if (lang != null) _add(lang, payload['text'] as String? ?? '', ConsoleStream.stderr);
      case 'stdin':
        if (lang != null) _add(lang, payload['text'] as String? ?? '', ConsoleStream.input);
      case 'prompt':
        // For R, a prompt after a submission means that submission finished.
        if (lang == KernelLanguage.r && _running.remove(KernelLanguage.r)) {
          onRunComplete?.call(KernelLanguage.r);
        }
      case 'runComplete':
        if (lang != null) {
          _running.remove(lang);
          onRunComplete?.call(lang);
        }
      case 'plot':
        if (lang != null) _addPlot(lang, payload['png'] as String? ?? '');
      case 'status':
        _handleStatus(payload, lang);
    }
  }

  void _handleStatus(Map<String, dynamic> payload, KernelLanguage? lang) {
    final String kernel = payload['kernel'] as String? ?? '';
    final String state = payload['state'] as String? ?? '';

    if (kernel == 'host') {
      if (state == 'error') {
        lastError = payload['message'] as String?;
      } else if (state == 'loaded') {
        // The JS module's static imports finished. Now (and only now) is
        // window.EtabliKernel actually defined, so it's safe to start kernels.
        // onHostLoaded() replays anything the shell queued before the host
        // page reached this state.
        onHostLoaded();
      }
      return;
    }
    if (lang == null) return;

    switch (state) {
      case 'loading':
        _state[lang] = KernelState.loading;
        _add(lang, lang == KernelLanguage.r ? 'Starting R (WebR)…' : 'Starting Python (Pyodide)…',
            ConsoleStream.system);
      case 'ready':
        _state[lang] = KernelState.ready;
        if (lang == KernelLanguage.r) {
          _add(lang, 'R kernel ready.', ConsoleStream.system);
        }
        onKernelReady?.call(lang);
      case 'error':
        _state[lang] = KernelState.error;
        lastError = payload['message'] as String?;
        _add(lang, '${lang == KernelLanguage.r ? 'R' : 'Python'} kernel error: '
            '${lastError ?? 'unknown'}', ConsoleStream.system);
    }
    notifyListeners();
  }

  // --- Commands to the kernels --------------------------------------------
  Future<void> run(KernelLanguage lang, String code) async {
    if (_state[lang] != KernelState.ready) return;
    _running.add(lang);
    await _eval(
        "void window.EtabliKernel.stdin('${_id(lang)}', ${jsonEncode(code)});");
  }

  // --- Shared-FS sync -----------------------------------------------------
  /// Push the workspace [files] (each {path, b64}) into the kernel's
  /// /workspace, replacing what was there.
  Future<void> pushFiles(
      KernelLanguage lang, List<Map<String, String>> files) async {
    final InAppWebViewController? web = _web;
    if (web == null || _state[lang] != KernelState.ready) return;
    await web.callAsyncJavaScript(
      functionBody: 'return await window.EtabliFS.push(lang, files);',
      arguments: {'lang': _id(lang), 'files': files},
    );
  }

  /// Snapshot the kernel's /workspace. Returns a list of {path, b64}.
  Future<List<Map<String, String>>> snapshotFiles(KernelLanguage lang) async {
    final InAppWebViewController? web = _web;
    if (web == null || _state[lang] != KernelState.ready) return const [];
    final CallAsyncJavaScriptResult? res = await web.callAsyncJavaScript(
      functionBody: 'return await window.EtabliFS.snapshot(lang);',
      arguments: {'lang': _id(lang)},
    );
    final Object? value = res?.value;
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((m) => {
              'path': m['path'].toString(),
              'b64': m['b64'].toString(),
            })
        .toList();
  }

  Future<void> restart(KernelLanguage lang) async {
    if (lang == KernelLanguage.r) {
      _state[lang] = KernelState.loading;
      _add(lang, 'Restarting R kernel…', ConsoleStream.system);
      notifyListeners();
      await _eval("void window.EtabliKernel.restart('r');");
    } else {
      // Pyodide runs on the WebView's main thread; a runaway loop blocks JS, so
      // the only reliable kill is a native reload of the whole host page. This
      // also restarts R.
      await _reloadHost();
    }
  }

  Future<void> _reloadHost() async {
    _hostReady = false;
    for (final KernelLanguage l in _state.keys) {
      _state[l] = KernelState.loading;
    }
    _add(KernelLanguage.python, 'Reloading kernel host…', ConsoleStream.system);
    notifyListeners();
    await _web?.reload();
  }

  void clear(KernelLanguage lang) {
    _lines[lang]!.clear();
    notifyListeners();
  }

  /// Install packages (ONLINE) for [lang]; results appended to the package log.
  Future<void> installPackages(KernelLanguage lang, List<String> names) async {
    final InAppWebViewController? web = _web;
    if (web == null || names.isEmpty) return;
    if (_state[lang] != KernelState.ready) {
      _pkgLog[lang]!.add(const PackageResult('—', false, 'Kernel not ready'));
      notifyListeners();
      return;
    }
    _installing = true;
    _pkgLog[lang]!.add(PackageResult(
        names.join(', '), true, 'Installing… (requires network)'));
    notifyListeners();

    final String fn =
        lang == KernelLanguage.r ? 'installR' : 'installPython';
    try {
      final CallAsyncJavaScriptResult? res = await web.callAsyncJavaScript(
        functionBody: 'return await window.EtabliPkg.$fn(names);',
        arguments: {'names': names},
      );
      final Object? value = res?.value;
      if (value is Map) {
        if (value['error'] != null) {
          _pkgLog[lang]!
              .add(PackageResult('—', false, value['error'].toString()));
        }
        final Object? results = value['results'];
        if (results is List) {
          for (final Map r in results.whereType<Map>()) {
            _pkgLog[lang]!.add(PackageResult(
              r['name'].toString(),
              r['ok'] == true,
              r['message']?.toString() ??
                  (r['ok'] == true ? 'installed' : 'not available'),
            ));
          }
        }
      } else {
        _pkgLog[lang]!.add(const PackageResult('—', false, 'Install failed'));
      }
    } catch (e) {
      _pkgLog[lang]!.add(PackageResult('—', false, 'Install error: $e'));
    } finally {
      _installing = false;
      notifyListeners();
    }
  }

  // --- internals ----------------------------------------------------------
  Future<void> _eval(String source) async {
    await _web?.evaluateJavascript(source: source);
  }

  void _add(KernelLanguage lang, String text, ConsoleStream stream) {
    _lines[lang]!.add(ConsoleLine(text, stream));
    notifyListeners();
  }

  void _addPlot(KernelLanguage lang, String dataUrl) {
    final int comma = dataUrl.indexOf(',');
    if (comma < 0) return;
    try {
      _plots[lang]!.add(base64Decode(dataUrl.substring(comma + 1)));
      notifyListeners();
    } catch (_) {}
  }

  static KernelLanguage? _langOf(String? id) => switch (id) {
        'r' => KernelLanguage.r,
        'python' => KernelLanguage.python,
        _ => null,
      };

  static Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (_) {}
    }
    return <String, dynamic>{};
  }
}
