// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

// Localized text of the kernel controller's console notices and package outcomes.

import '../data/settings_store.dart';
import '../l10n/app_localizations.dart';
import 'kernel_controller.dart';

String kernelLabel(KernelLanguage lang) =>
    lang == KernelLanguage.r ? 'R' : 'Python';

extension ConsoleLineText on ConsoleLine {
  /// The line as shown: the kernel's own text, or a localized notice with its upstream detail.
  String display(AppLocalizations l, KernelLanguage lang) {
    final String detail = text;
    return switch (notice) {
      null => text,
      KernelNotice.startingR => l.kernelStartingR,
      KernelNotice.startingPython => l.kernelStartingPython,
      KernelNotice.readyR => l.kernelReadyR,
      KernelNotice.kernelError => l.kernelError(
        kernelLabel(lang),
        detail.isEmpty ? l.kernelErrorUnknown : detail,
      ),
      KernelNotice.restartingR => l.kernelRestartingR,
      KernelNotice.reloadingHost => l.kernelReloadingHost,
      KernelNotice.packageLoadWarning => l.kernelPackageLoadWarning(detail),
      KernelNotice.plotCaptureWarning => l.kernelPlotCaptureWarning(detail),
      KernelNotice.hostStartFailed => l.kernelHostStartFailed(
        detail.isEmpty ? l.kernelErrorUnknown : detail,
      ),
    };
  }
}

extension PackageResultText on PackageResult {
  String display(AppLocalizations l) => switch (outcome) {
    PackageOutcome.pending => l.packagesInstalling,
    PackageOutcome.installed => l.packagesInstalled,
    PackageOutcome.unavailableR => l.packagesUnavailableR,
    PackageOutcome.unavailable => l.packagesUnavailable,
    PackageOutcome.failed => l.packagesInstallError(detail),
    PackageOutcome.kernelNotReady => l.consoleNotReady,
    PackageOutcome.installFailed => l.packagesInstallFailed,
    PackageOutcome.installError => l.packagesInstallError(detail),
    PackageOutcome.micropipUnavailable => l.packagesMicropipUnavailable(detail),
  };
}
