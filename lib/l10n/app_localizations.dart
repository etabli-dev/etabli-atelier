import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @navFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get navFiles;

  /// No description provided for @navEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get navEditor;

  /// No description provided for @navConsole.
  ///
  /// In en, this message translates to:
  /// **'Console'**
  String get navConsole;

  /// No description provided for @navPlots.
  ///
  /// In en, this message translates to:
  /// **'Plots'**
  String get navPlots;

  /// No description provided for @navPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get navPackages;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @kernelName.
  ///
  /// In en, this message translates to:
  /// **'{kernel} kernel'**
  String kernelName(String kernel);

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get commonDiscard;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get commonRun;

  /// No description provided for @filesNameHint.
  ///
  /// In en, this message translates to:
  /// **'name'**
  String get filesNameHint;

  /// No description provided for @filesNewFile.
  ///
  /// In en, this message translates to:
  /// **'New file'**
  String get filesNewFile;

  /// No description provided for @filesNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get filesNewFolder;

  /// No description provided for @filesImport.
  ///
  /// In en, this message translates to:
  /// **'Import from device'**
  String get filesImport;

  /// No description provided for @filesRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get filesRename;

  /// No description provided for @filesMove.
  ///
  /// In en, this message translates to:
  /// **'Move…'**
  String get filesMove;

  /// No description provided for @filesMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move “{name}” to…'**
  String filesMoveTitle(String name);

  /// No description provided for @filesWorkspaceRoot.
  ///
  /// In en, this message translates to:
  /// **'/ (workspace root)'**
  String get filesWorkspaceRoot;

  /// No description provided for @filesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String filesDeleteTitle(String name);

  /// No description provided for @filesDeleteFolderBody.
  ///
  /// In en, this message translates to:
  /// **'The folder and all its contents will be removed.'**
  String get filesDeleteFolderBody;

  /// No description provided for @filesDeleteFileBody.
  ///
  /// In en, this message translates to:
  /// **'This file will be removed.'**
  String get filesDeleteFileBody;

  /// No description provided for @filesShare.
  ///
  /// In en, this message translates to:
  /// **'Share / save a copy…'**
  String get filesShare;

  /// No description provided for @filesActions.
  ///
  /// In en, this message translates to:
  /// **'Actions for {name}'**
  String filesActions(String name);

  /// No description provided for @filesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Workspace is empty.\nCreate or import a file.'**
  String get filesEmpty;

  /// No description provided for @filesPull.
  ///
  /// In en, this message translates to:
  /// **'Pull from {kernel}'**
  String filesPull(String kernel);

  /// No description provided for @filesPullTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy the files {kernel} wrote into the workspace'**
  String filesPullTooltip(String kernel);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {detail}'**
  String errorGeneric(String detail);

  /// No description provided for @errorInvalidPath.
  ///
  /// In en, this message translates to:
  /// **'That is not a valid workspace path.'**
  String get errorInvalidPath;

  /// No description provided for @errorInvalidName.
  ///
  /// In en, this message translates to:
  /// **'“{name}” is not a valid name.'**
  String errorInvalidName(String name);

  /// No description provided for @errorExists.
  ///
  /// In en, this message translates to:
  /// **'“{path}” already exists.'**
  String errorExists(String path);

  /// No description provided for @errorMoveIntoItself.
  ///
  /// In en, this message translates to:
  /// **'A folder cannot be moved into itself.'**
  String get errorMoveIntoItself;

  /// No description provided for @errorSymlink.
  ///
  /// In en, this message translates to:
  /// **'Links inside the workspace are not supported.'**
  String get errorSymlink;

  /// No description provided for @editorScratch.
  ///
  /// In en, this message translates to:
  /// **'scratch buffer'**
  String get editorScratch;

  /// No description provided for @editorThisScratch.
  ///
  /// In en, this message translates to:
  /// **'this scratch buffer'**
  String get editorThisScratch;

  /// No description provided for @editorNewScratch.
  ///
  /// In en, this message translates to:
  /// **'a new scratch buffer'**
  String get editorNewScratch;

  /// No description provided for @editorOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open {path} as text. The current buffer is retained.'**
  String editorOpenFailed(String path);

  /// No description provided for @editorUnsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get editorUnsavedTitle;

  /// No description provided for @editorUnsavedBody.
  ///
  /// In en, this message translates to:
  /// **'Save changes to {current} before opening {next}?'**
  String editorUnsavedBody(String current, String next);

  /// No description provided for @editorSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {path}'**
  String editorSaved(String path);

  /// No description provided for @editorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save {path}. The editor buffer is retained.'**
  String editorSaveFailed(String path);

  /// No description provided for @editorSaveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get editorSaveAs;

  /// No description provided for @editorUntitled.
  ///
  /// In en, this message translates to:
  /// **'untitled'**
  String get editorUntitled;

  /// No description provided for @editorKernelStarting.
  ///
  /// In en, this message translates to:
  /// **'{kernel} kernel is still starting…'**
  String editorKernelStarting(String kernel);

  /// No description provided for @editorSelection.
  ///
  /// In en, this message translates to:
  /// **'Selection'**
  String get editorSelection;

  /// No description provided for @editorRunSelection.
  ///
  /// In en, this message translates to:
  /// **'Run the selection or the current line'**
  String get editorRunSelection;

  /// No description provided for @editorRunFile.
  ///
  /// In en, this message translates to:
  /// **'Save and run the whole file'**
  String get editorRunFile;

  /// No description provided for @editorOutput.
  ///
  /// In en, this message translates to:
  /// **'Output · {kernel}'**
  String editorOutput(String kernel);

  /// No description provided for @editorClearOutput.
  ///
  /// In en, this message translates to:
  /// **'Clear output'**
  String get editorClearOutput;

  /// No description provided for @editorShowOutput.
  ///
  /// In en, this message translates to:
  /// **'Show output'**
  String get editorShowOutput;

  /// No description provided for @editorHideOutput.
  ///
  /// In en, this message translates to:
  /// **'Hide output'**
  String get editorHideOutput;

  /// No description provided for @consoleHintR.
  ///
  /// In en, this message translates to:
  /// **'Enter R expression…'**
  String get consoleHintR;

  /// No description provided for @consoleHintPython.
  ///
  /// In en, this message translates to:
  /// **'Enter Python statement…'**
  String get consoleHintPython;

  /// No description provided for @consoleNotReady.
  ///
  /// In en, this message translates to:
  /// **'Kernel not ready'**
  String get consoleNotReady;

  /// No description provided for @consoleInputLabel.
  ///
  /// In en, this message translates to:
  /// **'{kernel} input'**
  String consoleInputLabel(String kernel);

  /// No description provided for @kernelStateIdle.
  ///
  /// In en, this message translates to:
  /// **'idle'**
  String get kernelStateIdle;

  /// No description provided for @kernelStateLoading.
  ///
  /// In en, this message translates to:
  /// **'loading…'**
  String get kernelStateLoading;

  /// No description provided for @kernelStateReady.
  ///
  /// In en, this message translates to:
  /// **'ready'**
  String get kernelStateReady;

  /// No description provided for @kernelStateError.
  ///
  /// In en, this message translates to:
  /// **'error'**
  String get kernelStateError;

  /// No description provided for @consoleClear.
  ///
  /// In en, this message translates to:
  /// **'Clear console'**
  String get consoleClear;

  /// No description provided for @consoleRestartR.
  ///
  /// In en, this message translates to:
  /// **'Force-restart R kernel'**
  String get consoleRestartR;

  /// No description provided for @consoleRestartPython.
  ///
  /// In en, this message translates to:
  /// **'Force-restart (reloads kernel host)'**
  String get consoleRestartPython;

  /// No description provided for @consoleBooting.
  ///
  /// In en, this message translates to:
  /// **'Booting kernel…'**
  String get consoleBooting;

  /// No description provided for @kernelStartingR.
  ///
  /// In en, this message translates to:
  /// **'Starting R (WebR)…'**
  String get kernelStartingR;

  /// No description provided for @kernelStartingPython.
  ///
  /// In en, this message translates to:
  /// **'Starting Python (Pyodide)…'**
  String get kernelStartingPython;

  /// No description provided for @kernelReadyR.
  ///
  /// In en, this message translates to:
  /// **'R kernel ready.'**
  String get kernelReadyR;

  /// No description provided for @kernelError.
  ///
  /// In en, this message translates to:
  /// **'{kernel} kernel error: {detail}'**
  String kernelError(String kernel, String detail);

  /// No description provided for @kernelErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get kernelErrorUnknown;

  /// No description provided for @kernelRestartingR.
  ///
  /// In en, this message translates to:
  /// **'Restarting R kernel…'**
  String get kernelRestartingR;

  /// No description provided for @kernelReloadingHost.
  ///
  /// In en, this message translates to:
  /// **'Reloading kernel host…'**
  String get kernelReloadingHost;

  /// No description provided for @kernelPackageLoadWarning.
  ///
  /// In en, this message translates to:
  /// **'Package load warning: {detail}'**
  String kernelPackageLoadWarning(String detail);

  /// No description provided for @kernelPlotCaptureWarning.
  ///
  /// In en, this message translates to:
  /// **'Plot capture warning: {detail}'**
  String kernelPlotCaptureWarning(String detail);

  /// No description provided for @kernelHostStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the local runtime: {detail}'**
  String kernelHostStartFailed(String detail);

  /// No description provided for @plotsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear plots'**
  String get plotsClear;

  /// No description provided for @plotsItem.
  ///
  /// In en, this message translates to:
  /// **'Plot {index}'**
  String plotsItem(String index);

  /// No description provided for @plotsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plots yet'**
  String get plotsEmpty;

  /// No description provided for @plotsHintR.
  ///
  /// In en, this message translates to:
  /// **'Run R plotting code, for example:'**
  String get plotsHintR;

  /// No description provided for @plotsHintGgplot.
  ///
  /// In en, this message translates to:
  /// **'ggplot2 works once installed under Packages.'**
  String get plotsHintGgplot;

  /// No description provided for @plotsHintPython.
  ///
  /// In en, this message translates to:
  /// **'Run matplotlib code, for example:'**
  String get plotsHintPython;

  /// No description provided for @packagesTitleR.
  ///
  /// In en, this message translates to:
  /// **'R packages'**
  String get packagesTitleR;

  /// No description provided for @packagesTitlePython.
  ///
  /// In en, this message translates to:
  /// **'Python packages'**
  String get packagesTitlePython;

  /// No description provided for @packagesSourceR.
  ///
  /// In en, this message translates to:
  /// **'repo.r-wasm.org (WebR WASM binaries)'**
  String get packagesSourceR;

  /// No description provided for @packagesSourcePython.
  ///
  /// In en, this message translates to:
  /// **'PyPI via micropip (pure-Python & WASM wheels)'**
  String get packagesSourcePython;

  /// No description provided for @packagesSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String packagesSource(String source);

  /// No description provided for @packagesNetwork.
  ///
  /// In en, this message translates to:
  /// **'Installing requires a network connection. Bundled packages already work offline.'**
  String get packagesNetwork;

  /// No description provided for @packagesHintR.
  ///
  /// In en, this message translates to:
  /// **'e.g. ggplot2, jsonlite'**
  String get packagesHintR;

  /// No description provided for @packagesHintPython.
  ///
  /// In en, this message translates to:
  /// **'e.g. requests, sympy'**
  String get packagesHintPython;

  /// No description provided for @packagesInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get packagesInstall;

  /// No description provided for @packagesStartFirst.
  ///
  /// In en, this message translates to:
  /// **'Switch to and start the {kernel} kernel first (Console tab).'**
  String packagesStartFirst(String kernel);

  /// No description provided for @packagesNone.
  ///
  /// In en, this message translates to:
  /// **'No installations yet.'**
  String get packagesNone;

  /// No description provided for @packagesInstalling.
  ///
  /// In en, this message translates to:
  /// **'Installing… (requires network)'**
  String get packagesInstalling;

  /// No description provided for @packagesInstalled.
  ///
  /// In en, this message translates to:
  /// **'installed'**
  String get packagesInstalled;

  /// No description provided for @packagesUnavailableR.
  ///
  /// In en, this message translates to:
  /// **'not available in the WebR WASM repository'**
  String get packagesUnavailableR;

  /// No description provided for @packagesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'not available'**
  String get packagesUnavailable;

  /// No description provided for @packagesInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Install failed'**
  String get packagesInstallFailed;

  /// No description provided for @packagesInstallError.
  ///
  /// In en, this message translates to:
  /// **'Install error: {detail}'**
  String packagesInstallError(String detail);

  /// No description provided for @packagesMicropipUnavailable.
  ///
  /// In en, this message translates to:
  /// **'micropip unavailable: {detail}'**
  String packagesMicropipUnavailable(String detail);

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsLanguage;

  /// No description provided for @settingsMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get settingsMode;

  /// No description provided for @modeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get modeSystem;

  /// No description provided for @modeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get modeLight;

  /// No description provided for @modeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get modeDark;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @settingsAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent colour'**
  String get settingsAccent;

  /// No description provided for @accentCoderBlue.
  ///
  /// In en, this message translates to:
  /// **'Coder blue'**
  String get accentCoderBlue;

  /// No description provided for @accentGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get accentGreen;

  /// No description provided for @accentYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get accentYellow;

  /// No description provided for @accentOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get accentOrange;

  /// No description provided for @accentRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get accentRed;

  /// No description provided for @accentPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get accentPurple;

  /// No description provided for @accentGraphite.
  ///
  /// In en, this message translates to:
  /// **'Graphite'**
  String get accentGraphite;

  /// No description provided for @settingsAppearanceNote.
  ///
  /// In en, this message translates to:
  /// **'Language, mode and accent colour apply at once. Default: Hugo Coder palette.'**
  String get settingsAppearanceNote;

  /// No description provided for @settingsEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get settingsEditor;

  /// No description provided for @settingsFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get settingsFontSize;

  /// No description provided for @settingsKernel.
  ///
  /// In en, this message translates to:
  /// **'Kernel'**
  String get settingsKernel;

  /// No description provided for @settingsDefaultKernel.
  ///
  /// In en, this message translates to:
  /// **'Default kernel'**
  String get settingsDefaultKernel;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutBody.
  ///
  /// In en, this message translates to:
  /// **'Offline polyglot mobile IDE.\nR via WebR · Python via Pyodide.\nBoth on-device, no network required.'**
  String get settingsAboutBody;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get settingsLicenses;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
