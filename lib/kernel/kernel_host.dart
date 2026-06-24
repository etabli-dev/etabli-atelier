// Copyright 2026 R. Heller
// SPDX-License-Identifier: Apache-2.0

// Hosts the kernel WebView for the whole app lifetime. The WebView is a pure
// compute surface — it is kept effectively invisible (1x1, behind the UI); all
// user-facing output is rendered natively by the Flutter shell from the events
// this view emits. Wrapping the app keeps the kernels alive across navigation.

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_providers.dart';
import 'kernel_controller.dart';
import 'runtime_server.dart';

class KernelHost extends ConsumerStatefulWidget {
  const KernelHost({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<KernelHost> createState() => _KernelHostState();
}

class _KernelHostState extends ConsumerState<KernelHost> {
  bool _serverReady = false;

  static final InAppWebViewSettings _settings = InAppWebViewSettings(
    isInspectable: true,
    javaScriptEnabled: true,
    transparentBackground: true,
    mediaPlaybackRequiresUserGesture: false,
    allowFileAccessFromFileURLs: true,
    allowUniversalAccessFromFileURLs: true,
    // WebR/Pyodide spin up Web Workers; nothing here needs hardware back nav.
    supportZoom: false,
  );

  @override
  void initState() {
    super.initState();
    // Instantiate the workspace controller now so its kernel-ready / run-
    // complete sync callbacks are wired from app start, regardless of which
    // pane the user opens first.
    ref.read(workspaceControllerProvider);
    _startServer();
  }

  Future<void> _startServer() async {
    try {
      await RuntimeServer.instance.start();
    } catch (e, st) {
      debugPrint('localhost server start failed: $e\n$st');
    }
    if (mounted) setState(() => _serverReady = true);
  }

  @override
  Widget build(BuildContext context) {
    final KernelController kernel = ref.read(kernelControllerProvider);

    // Boot the active kernel as soon as it's selected (queued until the host
    // page is ready). Rebuilds when the switcher changes the active language.
    final active = ref.watch(activeKernelProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) kernel.ensureStarted(active);
    });

    return Stack(
      children: [
        widget.child,
        // Invisible compute surface. Kept laid out (not Offstage) so the
        // platform view and its workers stay active.
        Positioned(
          left: 0,
          bottom: 0,
          width: 1,
          height: 1,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0,
              child: _serverReady
                  ? InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri(RuntimeServer.instance.hostUrl),
                      ),
                      initialSettings: _settings,
                      onWebViewCreated: (controller) {
                        kernel.attachWebView(controller);
                        controller.addJavaScriptHandler(
                          handlerName: 'onKernelEvent',
                          callback: (args) {
                            kernel.handleEvent(
                                args.isNotEmpty ? args.first : null);
                          },
                        );
                      },
                      // Do NOT trigger kernel startup from onLoadStop: that
                      // fires after the document is parsed but BEFORE the ES
                      // module's static imports (webr.mjs, pyodide.mjs)
                      // resolve, so window.EtabliKernel would still be
                      // undefined. The module emits a `host: loaded` status
                      // when it's truly ready; KernelController triggers
                      // kernel boot then.
                      onConsoleMessage: (controller, msg) {
                        if (msg.messageLevel == ConsoleMessageLevel.ERROR) {
                          kernel.handleEvent({
                            'type': 'status',
                            'payload': {
                              'kernel': 'host',
                              'state': 'error',
                              'message': msg.message,
                            },
                          });
                        }
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
