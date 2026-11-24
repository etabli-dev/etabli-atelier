// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get navFiles => 'Dateien';

  @override
  String get navEditor => 'Editor';

  @override
  String get navConsole => 'Konsole';

  @override
  String get navPlots => 'Grafiken';

  @override
  String get navPackages => 'Pakete';

  @override
  String get navSettings => 'Optionen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String kernelName(String kernel) {
    return '$kernel-Kernel';
  }

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonDiscard => 'Verwerfen';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonRun => 'Ausführen';

  @override
  String get filesNameHint => 'Name';

  @override
  String get filesNewFile => 'Neue Datei';

  @override
  String get filesNewFolder => 'Neuer Ordner';

  @override
  String get filesImport => 'Vom Gerät importieren';

  @override
  String get filesRename => 'Umbenennen';

  @override
  String get filesMove => 'Verschieben …';

  @override
  String filesMoveTitle(String name) {
    return '„$name“ verschieben nach …';
  }

  @override
  String get filesWorkspaceRoot => '/ (Arbeitsbereich)';

  @override
  String filesDeleteTitle(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get filesDeleteFolderBody =>
      'Der Ordner und sein gesamter Inhalt werden entfernt.';

  @override
  String get filesDeleteFileBody => 'Diese Datei wird entfernt.';

  @override
  String get filesShare => 'Teilen / Kopie sichern …';

  @override
  String filesActions(String name) {
    return 'Aktionen für $name';
  }

  @override
  String get filesEmpty =>
      'Der Arbeitsbereich ist leer.\nLege eine Datei an oder importiere eine.';

  @override
  String filesPull(String kernel) {
    return 'Aus $kernel holen';
  }

  @override
  String filesPullTooltip(String kernel) {
    return 'Von $kernel geschriebene Dateien in den Arbeitsbereich kopieren';
  }

  @override
  String errorGeneric(String detail) {
    return 'Fehler: $detail';
  }

  @override
  String get errorInvalidPath =>
      'Das ist kein gültiger Pfad im Arbeitsbereich.';

  @override
  String errorInvalidName(String name) {
    return '„$name“ ist kein gültiger Name.';
  }

  @override
  String errorExists(String path) {
    return '„$path“ ist bereits vorhanden.';
  }

  @override
  String get errorMoveIntoItself =>
      'Ein Ordner kann nicht in sich selbst verschoben werden.';

  @override
  String get errorSymlink =>
      'Verknüpfungen im Arbeitsbereich werden nicht unterstützt.';

  @override
  String get editorScratch => 'Entwurf';

  @override
  String get editorThisScratch => 'diesem Entwurf';

  @override
  String get editorNewScratch => 'ein neuer Entwurf';

  @override
  String editorOpenFailed(String path) {
    return '$path konnte nicht als Text geöffnet werden. Der aktuelle Inhalt bleibt erhalten.';
  }

  @override
  String get editorUnsavedTitle => 'Ungespeicherte Änderungen';

  @override
  String editorUnsavedBody(String current, String next) {
    return 'Änderungen an $current speichern, bevor $next geöffnet wird?';
  }

  @override
  String editorSaved(String path) {
    return '$path gespeichert';
  }

  @override
  String editorSaveFailed(String path) {
    return '$path konnte nicht gespeichert werden. Der Inhalt des Editors bleibt erhalten.';
  }

  @override
  String get editorSaveAs => 'Speichern unter';

  @override
  String get editorUntitled => 'unbenannt';

  @override
  String editorKernelStarting(String kernel) {
    return 'Der $kernel-Kernel startet noch …';
  }

  @override
  String get editorSelection => 'Auswahl';

  @override
  String get editorRunSelection => 'Auswahl oder aktuelle Zeile ausführen';

  @override
  String get editorRunFile => 'Datei speichern und ganz ausführen';

  @override
  String editorOutput(String kernel) {
    return 'Ausgabe · $kernel';
  }

  @override
  String get editorClearOutput => 'Ausgabe leeren';

  @override
  String get editorShowOutput => 'Ausgabe einblenden';

  @override
  String get editorHideOutput => 'Ausgabe ausblenden';

  @override
  String get consoleHintR => 'R-Ausdruck eingeben …';

  @override
  String get consoleHintPython => 'Python-Anweisung eingeben …';

  @override
  String get consoleNotReady => 'Kernel nicht bereit';

  @override
  String consoleInputLabel(String kernel) {
    return '$kernel-Eingabe';
  }

  @override
  String get kernelStateIdle => 'inaktiv';

  @override
  String get kernelStateLoading => 'lädt …';

  @override
  String get kernelStateReady => 'bereit';

  @override
  String get kernelStateError => 'Fehler';

  @override
  String get consoleClear => 'Konsole leeren';

  @override
  String get consoleRestartR => 'R-Kernel neu starten (erzwingen)';

  @override
  String get consoleRestartPython =>
      'Neustart erzwingen (lädt den Kernel-Host neu)';

  @override
  String get consoleBooting => 'Kernel startet …';

  @override
  String get kernelStartingR => 'R (WebR) startet …';

  @override
  String get kernelStartingPython => 'Python (Pyodide) startet …';

  @override
  String get kernelReadyR => 'R-Kernel bereit.';

  @override
  String kernelError(String kernel, String detail) {
    return '$kernel-Kernel-Fehler: $detail';
  }

  @override
  String get kernelErrorUnknown => 'unbekannt';

  @override
  String get kernelRestartingR => 'R-Kernel wird neu gestartet …';

  @override
  String get kernelReloadingHost => 'Kernel-Host wird neu geladen …';

  @override
  String kernelPackageLoadWarning(String detail) {
    return 'Warnung beim Laden von Paketen: $detail';
  }

  @override
  String kernelPlotCaptureWarning(String detail) {
    return 'Warnung beim Erfassen der Grafik: $detail';
  }

  @override
  String kernelHostStartFailed(String detail) {
    return 'Die lokale Laufzeitumgebung konnte nicht gestartet werden: $detail';
  }

  @override
  String get plotsClear => 'Grafiken leeren';

  @override
  String plotsItem(String index) {
    return 'Grafik $index';
  }

  @override
  String get plotsEmpty => 'Noch keine Grafiken';

  @override
  String get plotsHintR => 'Führe R-Grafikcode aus, zum Beispiel:';

  @override
  String get plotsHintGgplot =>
      'ggplot2 funktioniert, sobald es unter Pakete installiert ist.';

  @override
  String get plotsHintPython => 'Führe matplotlib-Code aus, zum Beispiel:';

  @override
  String get packagesTitleR => 'R-Pakete';

  @override
  String get packagesTitlePython => 'Python-Pakete';

  @override
  String get packagesSourceR => 'repo.r-wasm.org (WebR-WASM-Binärpakete)';

  @override
  String get packagesSourcePython =>
      'PyPI über micropip (reine Python- und WASM-Wheels)';

  @override
  String packagesSource(String source) {
    return 'Quelle: $source';
  }

  @override
  String get packagesNetwork =>
      'Die Installation braucht eine Netzwerkverbindung. Mitgelieferte Pakete funktionieren bereits offline.';

  @override
  String get packagesHintR => 'z. B. ggplot2, jsonlite';

  @override
  String get packagesHintPython => 'z. B. requests, sympy';

  @override
  String get packagesInstall => 'Installieren';

  @override
  String packagesStartFirst(String kernel) {
    return 'Wechsle zuerst zum $kernel-Kernel und starte ihn (Tab Konsole).';
  }

  @override
  String get packagesNone => 'Noch keine Installationen.';

  @override
  String get packagesInstalling => 'Wird installiert … (braucht Netzwerk)';

  @override
  String get packagesInstalled => 'installiert';

  @override
  String get packagesUnavailableR => 'nicht im WebR-WASM-Repository verfügbar';

  @override
  String get packagesUnavailable => 'nicht verfügbar';

  @override
  String get packagesInstallFailed => 'Installation fehlgeschlagen';

  @override
  String packagesInstallError(String detail) {
    return 'Installationsfehler: $detail';
  }

  @override
  String packagesMicropipUnavailable(String detail) {
    return 'micropip nicht verfügbar: $detail';
  }

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsLanguage => 'App-Sprache';

  @override
  String get settingsMode => 'Modus';

  @override
  String get modeSystem => 'System';

  @override
  String get modeLight => 'Hell';

  @override
  String get modeDark => 'Dunkel';

  @override
  String get languageSystem => 'System';

  @override
  String get settingsAccent => 'Akzentfarbe';

  @override
  String get accentCoderBlue => 'Coder-Blau';

  @override
  String get accentGreen => 'Grün';

  @override
  String get accentYellow => 'Gelb';

  @override
  String get accentOrange => 'Orange';

  @override
  String get accentRed => 'Rot';

  @override
  String get accentPurple => 'Violett';

  @override
  String get accentGraphite => 'Graphit';

  @override
  String get settingsAppearanceNote =>
      'Sprache, Modus und Akzentfarbe gelten sofort. Voreinstellung: Hugo-Coder-Palette.';

  @override
  String get settingsEditor => 'Editor';

  @override
  String get settingsFontSize => 'Schriftgröße';

  @override
  String get settingsKernel => 'Kernel';

  @override
  String get settingsDefaultKernel => 'Standard-Kernel';

  @override
  String get settingsAbout => 'Über';

  @override
  String get settingsAboutBody =>
      'Offline-IDE für R und Python.\nR über WebR · Python über Pyodide.\nBeides auf dem Gerät, kein Netzwerk nötig.';

  @override
  String get settingsLicenses => 'Open-Source-Lizenzen';
}
