// Riverpod providers wiring app-wide state (settings, theme, active kernel).
// Uses the Riverpod 3.x Notifier API.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_store.dart';
import '../fs/workspace_controller.dart';
import '../fs/workspace_store.dart';
import '../kernel/kernel_controller.dart';

/// Provided at app start via an override in ProviderScope (see main.dart).
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => throw UnimplementedError('settingsStoreProvider must be overridden'),
);

/// Persisted Auto/Light/Dark choice.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(settingsStoreProvider).themeMode;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsStoreProvider).setThemeMode(mode);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Persisted editor/console font size.
class FontSizeController extends Notifier<double> {
  static const double min = 11;
  static const double max = 22;

  @override
  double build() => ref.read(settingsStoreProvider).fontSize;

  Future<void> set(double size) async {
    final double clamped = size.clamp(min, max);
    state = clamped;
    await ref.read(settingsStoreProvider).setFontSize(clamped);
  }
}

final fontSizeProvider =
    NotifierProvider<FontSizeController, double>(FontSizeController.new);

/// The currently-active kernel language for the session (two separate kernels).
class ActiveKernelController extends Notifier<KernelLanguage> {
  @override
  KernelLanguage build() => ref.read(settingsStoreProvider).defaultKernel;

  void set(KernelLanguage lang) => state = lang;
}

final activeKernelProvider =
    NotifierProvider<ActiveKernelController, KernelLanguage>(
        ActiveKernelController.new);

/// The single bridge to the in-WebView kernels. Lives for the app's lifetime.
final kernelControllerProvider = Provider<KernelController>((ref) {
  final controller = KernelController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// The canonical workspace store (opened at app start; overridden in main).
final workspaceStoreProvider = Provider<WorkspaceStore>(
  (ref) => throw UnimplementedError('workspaceStoreProvider must be overridden'),
);

/// Index of the visible pane in the navigation shell. Lets actions elsewhere
/// (e.g. opening a file) switch panes.
class NavIndexController extends Notifier<int> {
  static const int files = 0;
  static const int editor = 1;
  static const int console = 2;

  @override
  int build() => editor;

  void set(int i) => state = i;
}

final navIndexProvider =
    NotifierProvider<NavIndexController, int>(NavIndexController.new);

/// The workspace-relative path of the file currently open in the editor
/// (null = scratch buffer).
class OpenFileController extends Notifier<String?> {
  @override
  String? build() => null;
  void open(String relPath) => state = relPath;
  void close() => state = null;
}

final openFileProvider =
    NotifierProvider<OpenFileController, String?>(OpenFileController.new);

/// Drives the file browser and kernel<->workspace mirroring.
final workspaceControllerProvider = Provider<WorkspaceController>((ref) {
  final controller = WorkspaceController(
    ref.watch(workspaceStoreProvider),
    ref.watch(kernelControllerProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
