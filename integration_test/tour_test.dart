// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

// Screenshot tour on a simulator or device: every pane, menu and dialog in English and German, plus dark mode
// with the yellow accent, and the R and Python kernels on the real WebView. Run it with
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/tour_test.dart -d <device>
//
// The screenshots land in build/tour/ (git-ignored). Kernel steps wait for the runtimes and report what they
// saw ("TOUR:" lines) instead of failing the tour.

import 'package:etabli_atelier/app/app_providers.dart';
import 'package:etabli_atelier/app/shell.dart';
import 'package:etabli_atelier/data/settings_store.dart';
import 'package:etabli_atelier/features/console/console_screen.dart';
import 'package:etabli_atelier/features/editor/editor_screen.dart';
import 'package:etabli_atelier/features/settings/settings_screen.dart';
import 'package:etabli_atelier/kernel/kernel_controller.dart';
import 'package:etabli_atelier/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour', (tester) async {
    await app.main();

    Future<void> settle([int ms = 700]) async {
      for (var t = 0; t < ms; t += 50) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<bool> waitFor(bool Function() done, {int seconds = 30}) async {
      for (var t = 0; t < seconds * 4; t++) {
        if (done()) return true;
        await tester.pump(const Duration(milliseconds: 250));
      }
      return done();
    }

    await waitFor(() => find.byType(AppShell).evaluate().isNotEmpty);
    await settle(1500);
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(AppShell)),
    );
    final KernelController kernel = container.read(kernelControllerProvider);
    final String device =
        tester.view.physicalSize.width / tester.view.devicePixelRatio >= 600
        ? 'ipad'
        : 'phone';
    var lang = 'en';
    var n = 0;

    Future<void> shot(String name) async {
      await settle();
      n++;
      final String id = '$device-$lang-${n.toString().padLeft(2, '0')}-$name';
      await binding.takeScreenshot(id);
      debugPrint('TOUR: screenshot $id');
    }

    Future<void> tap(Finder f) async {
      await tester.tap(f.hitTestable().first);
      await settle();
    }

    Future<void> pane(IconData icon) => tap(find.byIcon(icon));

    Future<void> dismiss() async {
      await tester.tapAt(const Offset(8, 200));
      await settle();
    }

    Finder inPane(Type pane, Type widget) =>
        find.descendant(of: find.byType(pane), matching: find.byType(widget));

    Future<void> runInConsole(String code) async {
      await pane(Icons.terminal);
      await tester.enterText(inPane(ConsoleScreen, TextField).first, code);
      await tap(inPane(ConsoleScreen, FilledButton));
    }

    bool consoleHas(KernelLanguage l, String text) => kernel
        .linesFor(l)
        .any((x) => x.stream == ConsoleStream.stdout && x.text.trim() == text);

    Future<void> selectKernel(String label) => tap(
      find.descendant(
        of: find.byType(SegmentedButton<KernelLanguage>).first,
        matching: find.text(label),
      ),
    );

    Future<void> openFile(String name) async {
      await pane(Icons.folder_outlined);
      await tap(find.text(name));
    }

    Future<void> setLanguage(String option) async {
      await pane(Icons.settings_outlined);
      await tester.drag(find.byType(SettingsScreen), const Offset(0, 1500));
      await settle();
      await tap(find.byKey(const ValueKey('settings.appearance.language')));
      await tap(find.text(option));
    }

    Future<void> setAccent(String name) async {
      await pane(Icons.settings_outlined);
      await tap(find.byKey(ValueKey('settings.appearance.accent.$name')));
    }

    Future<void> setMode(int index) async {
      await pane(Icons.settings_outlined);
      await tap(
        find
            .descendant(
              of: find.byKey(const ValueKey('settings.appearance.mode')),
              matching: find.byType(Text),
            )
            .at(index),
      );
    }

    // --- English, with the kernels --------------------------------------------------------------
    await setLanguage('English');
    await setMode(1);
    await setAccent('coderBlue');

    final bool rReady = await waitFor(
      () => kernel.stateFor(KernelLanguage.r) == KernelState.ready,
      seconds: 150,
    );
    debugPrint('TOUR: R kernel ready: $rReady');
    if (rReady) {
      await runInConsole('6*7');
      final bool ok = await waitFor(
        () => consoleHas(KernelLanguage.r, '[1] 42'),
        seconds: 30,
      );
      debugPrint('TOUR: R 6*7 printed [1] 42: $ok');
      await shot('console-r');
      await openFile('sample.R');
      await tap(inPane(EditorScreen, FilledButton));
      final bool plotted = await waitFor(
        () => kernel.plotsFor(KernelLanguage.r).isNotEmpty,
        seconds: 60,
      );
      debugPrint('TOUR: R sample plot captured: $plotted');
      await shot('editor-r-run');
      await pane(Icons.insert_chart_outlined);
      await shot('plots-r');
    }

    await selectKernel('Python');
    final bool pyReady = await waitFor(
      () => kernel.stateFor(KernelLanguage.python) == KernelState.ready,
      seconds: 240,
    );
    debugPrint('TOUR: Python kernel ready: $pyReady');
    if (pyReady) {
      await runInConsole('print(6*7)');
      final bool ok = await waitFor(
        () => consoleHas(KernelLanguage.python, '42'),
        seconds: 30,
      );
      debugPrint('TOUR: Python print(6*7) printed 42: $ok');
      await runInConsole(
        'import pandas as pd; print(pd.Series([1, 2, 3]).sum())',
      );
      final bool pandas = await waitFor(
        () => consoleHas(KernelLanguage.python, '6'),
        seconds: 90,
      );
      debugPrint('TOUR: Python pandas sum printed 6: $pandas');
      await shot('console-python');
    }
    await selectKernel('R');

    Future<void> screens() async {
      await pane(Icons.folder_outlined);
      await shot('files');
      await tap(find.byIcon(Icons.more_vert).at(1));
      await shot('files-menu');
      await dismiss();
      await tap(find.byIcon(Icons.note_add_outlined));
      await shot('dialog-new-file');
      await dismiss();
      await tap(find.byIcon(Icons.more_vert).at(1));
      await tap(find.byType(PopupMenuItem<String>).at(2));
      await shot('dialog-move');
      await dismiss();
      await tap(find.byIcon(Icons.more_vert).at(2));
      await tap(find.byType(PopupMenuItem<String>).at(3));
      await shot('dialog-delete');
      await dismiss();

      await openFile('sample.R');
      await shot('editor');
      final Finder code = find.descendant(
        of: find.byType(CodeField),
        matching: find.byType(EditableText),
      );
      await tester.enterText(code.first, 'x <- 1\n');
      await settle();
      await openFile('sample.py');
      await shot('dialog-unsaved');
      await tap(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextButton),
            )
            .at(1),
      );
      await selectKernel('R');
      await openFile('sample.R');

      await pane(Icons.terminal);
      await shot('console');
      await pane(Icons.insert_chart_outlined);
      await shot('plots');
      await pane(Icons.widgets_outlined);
      await shot('packages');
      await selectKernel('Python');
      await shot('packages-python');
      await selectKernel('R');
      await pane(Icons.settings_outlined);
      await tester.drag(find.byType(SettingsScreen), const Offset(0, 1500));
      await shot('settings');
      await tester.drag(find.byType(SettingsScreen), const Offset(0, -1500));
      await shot('settings-bottom');
      await tap(find.byType(TextButton).last);
      await shot('licenses');
      await tester.pageBack();
      await settle();
      await tester.drag(find.byType(SettingsScreen), const Offset(0, 1500));
      await settle();
      await tap(find.byKey(const ValueKey('settings.appearance.language')));
      await shot('language-menu');
      await dismiss();
    }

    await screens();

    // Dark mode with the yellow accent: selection tints must stay neutral.
    await setMode(2);
    await setAccent('yellow');
    await pane(Icons.settings_outlined);
    await shot('dark-yellow-settings');
    await pane(Icons.folder_outlined);
    await shot('dark-yellow-files');
    await pane(Icons.terminal);
    await shot('dark-yellow-console');
    await setAccent('orange');
    await setMode(1);
    await pane(Icons.widgets_outlined);
    await shot('light-orange-packages');
    await setAccent('coderBlue');

    // --- German ---------------------------------------------------------------------------------
    await setLanguage('Deutsch');
    lang = 'de';
    n = 0;
    await screens();
    await setAccent('purple');
    await setMode(2);
    await pane(Icons.code);
    await shot('dark-purple-editor');
    await setMode(0);
    await setAccent('coderBlue');
    expect(container.read(settingsStoreProvider).language.name, 'de');
  });
}
