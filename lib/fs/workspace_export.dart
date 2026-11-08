// Copyright 2026 R. Heller
// SPDX-License-Identifier: Apache-2.0
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'workspace_store.dart';

class WorkspaceExport {
  const WorkspaceExport(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

/// Copies the canonical bytes without renaming, moving or modifying the source.
Future<WorkspaceExport> prepareWorkspaceExport(
  WorkspaceStore store,
  String path,
) async => WorkspaceExport(p.posix.basename(path), await store.readBytes(path));
