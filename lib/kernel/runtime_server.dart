// Copyright 2026 R. Heller
// SPDX-License-Identifier: Apache-2.0

// Serves the bundled runtime assets (WebR, later Pyodide) and the host page
// over http://localhost so the WebView loads them with a proper origin and
// correct MIME types (.mjs => text/javascript, .wasm => application/wasm).
//
// Everything is local — no network is touched. This is what makes the app
// offline from first launch.

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class RuntimeServer {
  RuntimeServer._();
  static final RuntimeServer instance = RuntimeServer._();

  static const int port = 51736;

  final InAppLocalhostServer _server = InAppLocalhostServer(port: port);
  bool _started = false;

  String get hostUrl => 'http://localhost:$port/assets/web/index.html';

  Future<void> start() async {
    if (_started) return;
    await _server.start();
    _started = true;
  }
}
