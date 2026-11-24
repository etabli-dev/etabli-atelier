// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

import '../l10n/app_localizations.dart';
import 'workspace_store.dart';

/// A localized message for a failed workspace operation; other errors keep their own text.
String describeWorkspaceError(Object error, AppLocalizations l) {
  final (WorkspaceErrorKind? kind, String value) = switch (error) {
    WorkspaceArgumentError e => (e.kind, '${e.invalidValue}'),
    WorkspaceFileError e => (e.kind, e.path ?? ''),
    _ => (null, ''),
  };
  return switch (kind) {
    WorkspaceErrorKind.invalidPath => l.errorInvalidPath,
    WorkspaceErrorKind.invalidName => l.errorInvalidName(value),
    WorkspaceErrorKind.moveIntoItself => l.errorMoveIntoItself,
    WorkspaceErrorKind.exists => l.errorExists(value),
    WorkspaceErrorKind.symlink => l.errorSymlink,
    null => l.errorGeneric('$error'),
  };
}
