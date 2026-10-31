import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:etabli_atelier/app/app_providers.dart';
import 'package:etabli_atelier/app/shell.dart';
import 'package:etabli_atelier/data/settings_store.dart';
import 'package:etabli_atelier/features/editor/editor_screen.dart';
import 'package:etabli_atelier/fs/workspace_store.dart';

class _Settings implements SettingsStore {
  @override
  ThemeMode get themeMode => ThemeMode.light;
  @override
  double get fontSize => 14;
  @override
  KernelLanguage get defaultKernel => KernelLanguage.r;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Store extends WorkspaceStore {
  _Store(super.root) : super.at();
  bool failWrites = false;
  @override
  Future<void> writeText(String rel, String text) {
    if (failWrites) throw const FileSystemException('Injected disk failure');
    return super.writeText(rel, text);
  }
}

void main() {
  late Directory directory;
  late _Store store;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('atelier-editor-');
    store = _Store(directory);
    await store.writeText('original.R', 'print(42)');
    await store.writeText('other.py', 'print(2)');
    await store.writeBytes('binary.R', [0xff, 0xfe, 0x80]);
  });
  tearDown(() => directory.delete(recursive: true));

  testWidgets(
    'failed file read and save preserve the buffer and original bytes',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(_Settings()),
          workspaceStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
      container.read(openFileProvider.notifier).open('original.R');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: EditorScreen())),
        ),
      );
      Future<void> settleUntil(bool Function() done) async {
        for (var i = 0; i < 100 && !done(); i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await tester.pump(const Duration(milliseconds: 10));
        }
        expect(done(), isTrue);
        expect(tester.takeException(), isNull);
      }

      CodeController code() =>
          tester.widget<CodeField>(find.byType(CodeField)).controller;
      await settleUntil(
        () =>
            find.byType(CodeField).evaluate().isNotEmpty &&
            code().fullText == 'print(42)',
      );
      code().fullText = 'print(56)';
      container.read(openFileProvider.notifier).open('binary.R');
      await settleUntil(
        () => find.text('Unsaved changes').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Discard'));
      await settleUntil(
        () => find
            .textContaining('Could not open binary.R as text')
            .evaluate()
            .isNotEmpty,
      );
      expect(code().fullText, 'print(56)');
      expect(find.text('original.R'), findsOneWidget);
      await tester.tap(find.byTooltip('Save'));
      await settleUntil(
        () => find.text('Saved original.R').evaluate().isNotEmpty,
      );
      expect(await tester.runAsync(() => store.readBytes('binary.R')), [
        0xff,
        0xfe,
        0x80,
      ]);
      expect(
        await tester.runAsync(() => store.readText('original.R')),
        'print(56)',
      );

      // Finish the prior success snackbar before exercising the failure UI.
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      store.failWrites = true;
      code().fullText = 'unsaved draft';
      await tester.tap(find.byTooltip('Save'));
      await settleUntil(
        () => find
            .textContaining('Could not save original.R')
            .evaluate()
            .isNotEmpty,
      );
      expect(code().fullText, 'unsaved draft');
      expect(
        await tester.runAsync(() => store.readText('original.R')),
        'print(56)',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'file navigation protects unsaved drafts for every dialog outcome',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(_Settings()),
          workspaceStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
      container.read(openFileProvider.notifier).open('original.R');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: EditorScreen())),
        ),
      );
      Future<void> waitFor(bool Function() done) async {
        for (var i = 0; i < 100 && !done(); i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await tester.pump(const Duration(milliseconds: 20));
        }
        expect(done(), isTrue);
        expect(tester.takeException(), isNull);
      }

      CodeController code() =>
          tester.widget<CodeField>(find.byType(CodeField)).controller;
      Future<void> openAndChoose(String? path, String choice) async {
        if (path == null) {
          container.read(openFileProvider.notifier).close();
        } else {
          container.read(openFileProvider.notifier).open(path);
        }
        await waitFor(() => find.text('Unsaved changes').evaluate().isNotEmpty);
        await tester.tap(
          find.widgetWithText(TextButton, choice).evaluate().isNotEmpty
              ? find.widgetWithText(TextButton, choice)
              : find.widgetWithText(FilledButton, choice),
        );
        await waitFor(() => find.text('Unsaved changes').evaluate().isEmpty);
      }

      await waitFor(
        () =>
            find.byType(CodeField).evaluate().isNotEmpty &&
            code().fullText == 'print(42)',
      );
      code().fullText = 'draft to preserve';
      await openAndChoose('other.py', 'Cancel');
      expect(container.read(openFileProvider), 'original.R');
      expect(container.read(activeKernelProvider), KernelLanguage.r);
      expect(code().fullText, 'draft to preserve');
      expect(
        await tester.runAsync(() => store.readText('original.R')),
        'print(42)',
      );

      store.failWrites = true;
      await openAndChoose('other.py', 'Save');
      await waitFor(
        () => find
            .textContaining('Could not save original.R')
            .evaluate()
            .isNotEmpty,
      );
      expect(container.read(openFileProvider), 'original.R');
      expect(container.read(activeKernelProvider), KernelLanguage.r);
      expect(code().fullText, 'draft to preserve');
      expect(
        await tester.runAsync(() => store.readText('original.R')),
        'print(42)',
      );

      store.failWrites = false;
      await openAndChoose('other.py', 'Save');
      await waitFor(() => code().fullText == 'print(2)');
      expect(container.read(openFileProvider), 'other.py');
      expect(container.read(activeKernelProvider), KernelLanguage.python);
      expect(
        await tester.runAsync(() => store.readText('original.R')),
        'draft to preserve',
      );

      code().fullText = 'deliberately discarded';
      await openAndChoose('original.R', 'Discard');
      await waitFor(() => code().fullText == 'draft to preserve');
      expect(container.read(openFileProvider), 'original.R');
      expect(container.read(activeKernelProvider), KernelLanguage.r);
      expect(
        await tester.runAsync(() => store.readText('other.py')),
        'print(2)',
      );
      code().fullText = 'draft before closing';
      await openAndChoose(null, 'Cancel');
      expect(container.read(openFileProvider), 'original.R');
      expect(container.read(activeKernelProvider), KernelLanguage.r);
      expect(code().fullText, 'draft before closing');
      await openAndChoose(null, 'Discard');
      await waitFor(() => code().fullText.isEmpty);
      expect(container.read(openFileProvider), isNull);
      expect(find.text('scratch buffer'), findsOneWidget);
      expect(
        await tester.runAsync(() => store.readText('original.R')),
        'draft to preserve',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'shell pane navigation retains the draft before opening another file',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(_Settings()),
          workspaceStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
      container.read(openFileProvider.notifier).open('original.R');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AppShell()),
        ),
      );
      Future<void> waitFor(bool Function() done) async {
        for (var i = 0; i < 100 && !done(); i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await tester.pump(const Duration(milliseconds: 20));
        }
        expect(done(), isTrue);
        expect(tester.takeException(), isNull);
      }

      CodeController code() =>
          tester.widget<CodeField>(find.byType(CodeField)).controller;
      Future<void> pane(String label) async {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationRail),
            matching: find.text(label),
          ),
        );
        await tester.pump();
      }

      await waitFor(
        () =>
            find.byType(CodeField).evaluate().isNotEmpty &&
            code().fullText == 'print(42)',
      );
      code().fullText = 'retained across panes';
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 800);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byType(NavigationRail), findsNothing);
      expect(code().fullText, 'retained across panes');
      tester.view.physicalSize = const Size(800, 600);
      await tester.pump();
      expect(code().fullText, 'retained across panes');
      await pane('Files');
      await waitFor(() => find.text('other.py').evaluate().isNotEmpty);
      await tester.tap(find.text('other.py'));
      await waitFor(() => find.text('Unsaved changes').evaluate().isNotEmpty);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await waitFor(() => find.text('Unsaved changes').evaluate().isEmpty);
      expect(code().fullText, 'retained across panes');
      expect(container.read(activeKernelProvider), KernelLanguage.r);
      expect(container.read(openFileProvider), 'original.R');
      await pane('Console');
      await pane('Editor');
      expect(code().fullText, 'retained across panes');
      await pane('Files');
      await tester.tap(find.text('other.py'));
      await waitFor(() => find.text('Unsaved changes').evaluate().isNotEmpty);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await waitFor(() => code().fullText == 'print(2)');
      expect(container.read(activeKernelProvider), KernelLanguage.python);
      expect(
        await tester.runAsync(() => store.readText('original.R')),
        'retained across panes',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
