// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navFiles => 'Files';

  @override
  String get navEditor => 'Editor';

  @override
  String get navConsole => 'Console';

  @override
  String get navPlots => 'Plots';

  @override
  String get navPackages => 'Packages';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String kernelName(String kernel) {
    return '$kernel kernel';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDiscard => 'Discard';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonRun => 'Run';

  @override
  String get filesNameHint => 'name';

  @override
  String get filesNewFile => 'New file';

  @override
  String get filesNewFolder => 'New folder';

  @override
  String get filesImport => 'Import from device';

  @override
  String get filesRename => 'Rename';

  @override
  String get filesMove => 'Move…';

  @override
  String filesMoveTitle(String name) {
    return 'Move “$name” to…';
  }

  @override
  String get filesWorkspaceRoot => '/ (workspace root)';

  @override
  String filesDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get filesDeleteFolderBody =>
      'The folder and all its contents will be removed.';

  @override
  String get filesDeleteFileBody => 'This file will be removed.';

  @override
  String get filesShare => 'Share / save a copy…';

  @override
  String filesActions(String name) {
    return 'Actions for $name';
  }

  @override
  String get filesEmpty => 'Workspace is empty.\nCreate or import a file.';

  @override
  String filesPull(String kernel) {
    return 'Pull from $kernel';
  }

  @override
  String filesPullTooltip(String kernel) {
    return 'Copy the files $kernel wrote into the workspace';
  }

  @override
  String errorGeneric(String detail) {
    return 'Error: $detail';
  }

  @override
  String get errorInvalidPath => 'That is not a valid workspace path.';

  @override
  String errorInvalidName(String name) {
    return '“$name” is not a valid name.';
  }

  @override
  String errorExists(String path) {
    return '“$path” already exists.';
  }

  @override
  String get errorMoveIntoItself => 'A folder cannot be moved into itself.';

  @override
  String get errorSymlink => 'Links inside the workspace are not supported.';

  @override
  String get editorScratch => 'scratch buffer';

  @override
  String get editorThisScratch => 'this scratch buffer';

  @override
  String get editorNewScratch => 'a new scratch buffer';

  @override
  String editorOpenFailed(String path) {
    return 'Could not open $path as text. The current buffer is retained.';
  }

  @override
  String get editorUnsavedTitle => 'Unsaved changes';

  @override
  String editorUnsavedBody(String current, String next) {
    return 'Save changes to $current before opening $next?';
  }

  @override
  String editorSaved(String path) {
    return 'Saved $path';
  }

  @override
  String editorSaveFailed(String path) {
    return 'Could not save $path. The editor buffer is retained.';
  }

  @override
  String get editorSaveAs => 'Save as';

  @override
  String get editorUntitled => 'untitled';

  @override
  String editorKernelStarting(String kernel) {
    return '$kernel kernel is still starting…';
  }

  @override
  String get editorSelection => 'Selection';

  @override
  String get editorRunSelection => 'Run the selection or the current line';

  @override
  String get editorRunFile => 'Save and run the whole file';

  @override
  String editorOutput(String kernel) {
    return 'Output · $kernel';
  }

  @override
  String get editorClearOutput => 'Clear output';

  @override
  String get editorShowOutput => 'Show output';

  @override
  String get editorHideOutput => 'Hide output';

  @override
  String get consoleHintR => 'Enter R expression…';

  @override
  String get consoleHintPython => 'Enter Python statement…';

  @override
  String get consoleNotReady => 'Kernel not ready';

  @override
  String consoleInputLabel(String kernel) {
    return '$kernel input';
  }

  @override
  String get kernelStateIdle => 'idle';

  @override
  String get kernelStateLoading => 'loading…';

  @override
  String get kernelStateReady => 'ready';

  @override
  String get kernelStateError => 'error';

  @override
  String get consoleClear => 'Clear console';

  @override
  String get consoleRestartR => 'Force-restart R kernel';

  @override
  String get consoleRestartPython => 'Force-restart (reloads kernel host)';

  @override
  String get consoleBooting => 'Booting kernel…';

  @override
  String get kernelStartingR => 'Starting R (WebR)…';

  @override
  String get kernelStartingPython => 'Starting Python (Pyodide)…';

  @override
  String get kernelReadyR => 'R kernel ready.';

  @override
  String kernelError(String kernel, String detail) {
    return '$kernel kernel error: $detail';
  }

  @override
  String get kernelErrorUnknown => 'unknown';

  @override
  String get kernelRestartingR => 'Restarting R kernel…';

  @override
  String get kernelReloadingHost => 'Reloading kernel host…';

  @override
  String kernelPackageLoadWarning(String detail) {
    return 'Package load warning: $detail';
  }

  @override
  String kernelPlotCaptureWarning(String detail) {
    return 'Plot capture warning: $detail';
  }

  @override
  String kernelHostStartFailed(String detail) {
    return 'Could not start the local runtime: $detail';
  }

  @override
  String get plotsClear => 'Clear plots';

  @override
  String plotsItem(String index) {
    return 'Plot $index';
  }

  @override
  String get plotsEmpty => 'No plots yet';

  @override
  String get plotsHintR => 'Run R plotting code, for example:';

  @override
  String get plotsHintGgplot => 'ggplot2 works once installed under Packages.';

  @override
  String get plotsHintPython => 'Run matplotlib code, for example:';

  @override
  String get packagesTitleR => 'R packages';

  @override
  String get packagesTitlePython => 'Python packages';

  @override
  String get packagesSourceR => 'repo.r-wasm.org (WebR WASM binaries)';

  @override
  String get packagesSourcePython =>
      'PyPI via micropip (pure-Python & WASM wheels)';

  @override
  String packagesSource(String source) {
    return 'Source: $source';
  }

  @override
  String get packagesNetwork =>
      'Installing requires a network connection. Bundled packages already work offline.';

  @override
  String get packagesHintR => 'e.g. ggplot2, jsonlite';

  @override
  String get packagesHintPython => 'e.g. requests, sympy';

  @override
  String get packagesInstall => 'Install';

  @override
  String packagesStartFirst(String kernel) {
    return 'Switch to and start the $kernel kernel first (Console tab).';
  }

  @override
  String get packagesNone => 'No installations yet.';

  @override
  String get packagesInstalling => 'Installing… (requires network)';

  @override
  String get packagesInstalled => 'installed';

  @override
  String get packagesUnavailableR =>
      'not available in the WebR WASM repository';

  @override
  String get packagesUnavailable => 'not available';

  @override
  String get packagesInstallFailed => 'Install failed';

  @override
  String packagesInstallError(String detail) {
    return 'Install error: $detail';
  }

  @override
  String packagesMicropipUnavailable(String detail) {
    return 'micropip unavailable: $detail';
  }

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLanguage => 'App language';

  @override
  String get settingsMode => 'Mode';

  @override
  String get modeSystem => 'System';

  @override
  String get modeLight => 'Light';

  @override
  String get modeDark => 'Dark';

  @override
  String get languageSystem => 'System';

  @override
  String get settingsAccent => 'Accent colour';

  @override
  String get accentCoderBlue => 'Coder blue';

  @override
  String get accentGreen => 'Green';

  @override
  String get accentYellow => 'Yellow';

  @override
  String get accentOrange => 'Orange';

  @override
  String get accentRed => 'Red';

  @override
  String get accentPurple => 'Purple';

  @override
  String get accentGraphite => 'Graphite';

  @override
  String get settingsAppearanceNote =>
      'Language, mode and accent colour apply at once. Default: Hugo Coder palette.';

  @override
  String get settingsEditor => 'Editor';

  @override
  String get settingsFontSize => 'Font size';

  @override
  String get settingsKernel => 'Kernel';

  @override
  String get settingsDefaultKernel => 'Default kernel';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutBody =>
      'Offline polyglot mobile IDE.\nR via WebR · Python via Pyodide.\nBoth on-device, no network required.';

  @override
  String get settingsLicenses => 'Open-source licenses';
}
