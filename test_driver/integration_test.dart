// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

// Host side of integration_test/tour_test.dart: writes the screenshots to build/tour/.

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot:
      (String name, List<int> bytes, [Map<String, Object?>? args]) async {
        final File file = File('build/tour/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
        return true;
      },
);
