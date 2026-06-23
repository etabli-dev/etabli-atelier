import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'app/app_providers.dart';
import 'data/settings_store.dart';
import 'fs/workspace_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
