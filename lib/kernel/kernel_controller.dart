// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

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

/// App-authored console messages; the UI localizes them when it shows them, so they follow the app
/// language at once.
enum KernelNotice {
  startingR,
  startingPython,
  readyR,
  kernelError,
  restartingR,
  reloadingHost,
  packageLoadWarning,
  plotCaptureWarning,
  hostStartFailed,
}

class ConsoleLine {
  const ConsoleLine(this.text, this.stream, {this.notice});

  /// The kernel's own text, or the detail of a [notice] (an upstream error message, may be empty).
  final String text;
  final ConsoleStream stream;
  final KernelNotice? notice;
}

/// The outcome of a package installation step; the UI localizes it.
enum PackageOutcome {
  pending,
  installed,
  unavailableR,
  unavailable,
  failed,
  kernelNotReady,
  installFailed,
  installError,
  micropipUnavailable,
}

class PackageResult {
  const PackageResult(this.name, this.outcome, [this.detail = '']);
  final String name;
  final PackageOutcome outcome;

  /// The upstream message (micropip or JavaScript error), if any; not translated.
  final String detail;

  bool get pending => outcome == PackageOutcome.pending;
  bool get ok => pending || outcome == PackageOutcome.installed;
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

  // Prefixes of the host page's own warnings (assets/web/kernel_host.js).
  static const String _packageLoadWarning = 'Package load warning: ';
  static const String _plotCaptureWarning = 'Plot capture warning: ';

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
      "void (window.EtabliKernel && window.EtabliKernel.start('${_id(lang)}'));",
    );
  }

  // --- Incoming events from the WebView -----------------------------------
  void handleEvent(Object? raw) {
    final Map<String, dynamic> msg = _asMap(raw);
    final String type = msg['type'] as String? ?? '';
    final Map<String, dynamic> payload = _asMap(msg['payload']);
    final KernelLanguage? lang = _langOf(payload['kernel'] as String?);

    switch (type) {
      case 'stdout':
        if (lang != null) {
          _add(lang, payload['text'] as String? ?? '', ConsoleStream.stdout);
        }
      case 'stderr':
        if (lang != null) {
          final String text = payload['text'] as String? ?? '';
          // The host page prefixes its own warnings; keep only the upstream detail.
          if (text.startsWith(_packageLoadWarning)) {
            _add(
              lang,
              text.substring(_packageLoadWarning.length),
              ConsoleStream.stderr,
              notice: KernelNotice.packageLoadWarning,
            );
          } else if (text.startsWith(_plotCaptureWarning)) {
            _add(
              lang,
              text.substring(_plotCaptureWarning.length),
              ConsoleStream.stderr,
              notice: KernelNotice.plotCaptureWarning,
            );
          } else {
            _add(lang, text, ConsoleStream.stderr);
          }
        }
      case 'stdin':
        if (lang != null) {
          _add(lang, payload['text'] as String? ?? '', ConsoleStream.input);
        }
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
        if (payload['code'] == 'serverStartFailed') {
          // Without the local server neither kernel can boot: say so instead of "booting" forever.
          for (final KernelLanguage l in KernelLanguage.values) {
            _state[l] = KernelState.error;
            _add(
              l,
              lastError ?? '',
              ConsoleStream.system,
              notice: KernelNotice.hostStartFailed,
            );
          }
        }
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
        _add(
          lang,
          '',
          ConsoleStream.system,
          notice: lang == KernelLanguage.r
              ? KernelNotice.startingR
              : KernelNotice.startingPython,
        );
      case 'ready':
        _state[lang] = KernelState.ready;
        if (lang == KernelLanguage.r) {
          _add(lang, '', ConsoleStream.system, notice: KernelNotice.readyR);
        }
        onKernelReady?.call(lang);
      case 'error':
        _state[lang] = KernelState.error;
        lastError = payload['message'] as String?;
        _add(
          lang,
          lastError ?? '',
          ConsoleStream.system,
          notice: KernelNotice.kernelError,
        );
    }
    notifyListeners();
  }

  // --- Commands to the kernels --------------------------------------------
  Future<void> run(KernelLanguage lang, String code) async {
    if (_state[lang] != KernelState.ready) return;
    _running.add(lang);
    await _eval(
      "void window.EtabliKernel.stdin('${_id(lang)}', ${jsonEncode(code)});",
    );
  }

  // --- Shared-FS sync -----------------------------------------------------
  /// Push the workspace [files] (each {path, b64}) into the kernel's
  /// /workspace, replacing what was there.
  Future<void> pushFiles(
    KernelLanguage lang,
    List<Map<String, String>> files,
  ) async {
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
        .map((m) => {'path': m['path'].toString(), 'b64': m['b64'].toString()})
        .toList();
  }

  Future<void> restart(KernelLanguage lang) async {
    if (lang == KernelLanguage.r) {
      _state[lang] = KernelState.loading;
      _add(lang, '', ConsoleStream.system, notice: KernelNotice.restartingR);
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
    _add(
      KernelLanguage.python,
      '',
      ConsoleStream.system,
      notice: KernelNotice.reloadingHost,
    );
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
      _pkgLog[lang]!.add(
        const PackageResult('—', PackageOutcome.kernelNotReady),
      );
      notifyListeners();
      return;
    }
    _installing = true;
    final PackageResult pending = PackageResult(
      names.join(', '),
      PackageOutcome.pending,
    );
    _pkgLog[lang]!.add(pending);
    notifyListeners();

    final String fn = lang == KernelLanguage.r ? 'installR' : 'installPython';
    try {
      final CallAsyncJavaScriptResult? res = await web.callAsyncJavaScript(
        functionBody: 'return await window.EtabliPkg.$fn(names);',
        arguments: {'names': names},
      );
      final Object? value = res?.value;
      if (value is Map) {
        final Object? error = value['error'];
        if (error != null) _pkgLog[lang]!.add(_hostError(error.toString()));
        final Object? results = value['results'];
        if (results is List) {
          for (final Map r in results.whereType<Map>()) {
            final bool ok = r['ok'] == true;
            final String message = r['message']?.toString() ?? '';
            _pkgLog[lang]!.add(
              PackageResult(
                r['name'].toString(),
                ok
                    ? PackageOutcome.installed
                    : lang == KernelLanguage.r
                    ? PackageOutcome.unavailableR
                    : message.isEmpty
                    ? PackageOutcome.unavailable
                    : PackageOutcome.failed,
                ok || lang == KernelLanguage.r ? '' : message,
              ),
            );
          }
        }
      } else {
        _pkgLog[lang]!.add(
          const PackageResult('—', PackageOutcome.installFailed),
        );
      }
    } catch (e) {
      _pkgLog[lang]!.add(
        PackageResult('—', PackageOutcome.installError, e.toString()),
      );
    } finally {
      // The results replace the "installing" entry, which would otherwise keep its hourglass.
      _pkgLog[lang]!.remove(pending);
      _installing = false;
      notifyListeners();
    }
  }

  /// A top-level error of the host page's installer (assets/web/kernel_host.js).
  static PackageResult _hostError(String error) {
    const String micropip = 'micropip unavailable: ';
    if (error.startsWith(micropip)) {
      return PackageResult(
        '—',
        PackageOutcome.micropipUnavailable,
        error.substring(micropip.length),
      );
    }
    if (error.endsWith('kernel not ready')) {
      return const PackageResult('—', PackageOutcome.kernelNotReady);
    }
    return PackageResult('—', PackageOutcome.installError, error);
  }

  // --- internals ----------------------------------------------------------
  Future<void> _eval(String source) async {
    await _web?.evaluateJavascript(source: source);
  }

  void _add(
    KernelLanguage lang,
    String text,
    ConsoleStream stream, {
    KernelNotice? notice,
  }) {
    _lines[lang]!.add(ConsoleLine(text, stream, notice: notice));
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
