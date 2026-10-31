// Copyright 2026 R. Heller
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'app/app_providers.dart';
import 'data/settings_store.dart';
import 'fs/workspace_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'WebR 0.6.0 (binary: GPL-3.0)',
    ], await rootBundle.loadString('assets/licenses/webr-LICENSE.md'));
    yield LicenseEntryWithLineBreaks([
      'Pyodide 0.27.7',
    ], await rootBundle.loadString('assets/licenses/pyodide-LICENSE.txt'));
  });
  await Hive.initFlutter();
  final SettingsStore settings = await SettingsStore.open();
  final WorkspaceStore workspace = await WorkspaceStore.open();

  runApp(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(settings),
        workspaceStoreProvider.overrideWithValue(workspace),
      ],
      child: const EtabliAtelierApp(),
    ),
  );
}
