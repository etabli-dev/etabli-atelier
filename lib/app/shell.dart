// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

// The navigation shell: responsive rail/bottom-bar over the six feature panes,
// with a per-session kernel switcher (R / Python — two separate kernels).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_store.dart';
import '../l10n/l10n.dart';
import '../theme/coder_theme_atelier.dart';
import 'app_providers.dart';
import '../features/files/files_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/console/console_screen.dart';
import '../features/plots/plots_screen.dart';
import '../features/packages/packages_screen.dart';
import '../features/settings/settings_screen.dart';

class _Destination {
  const _Destination(this.label, this.title, this.icon, this.builder);

  /// The short tab label (fits a 375-pt phone in every language).
  final String Function(AppLocalizations) label;

  /// The full pane title, also the tab's tooltip and accessibility label.
  final String Function(AppLocalizations) title;
  final IconData icon;
  final WidgetBuilder builder;
}

final List<_Destination> _destinations = <_Destination>[
  _Destination(
    (l) => l.navFiles,
    (l) => l.navFiles,
    Icons.folder_outlined,
    (_) => const FilesScreen(),
  ),
  _Destination(
    (l) => l.navEditor,
    (l) => l.navEditor,
    Icons.code,
    (_) => const EditorScreen(),
  ),
  _Destination(
    (l) => l.navConsole,
    (l) => l.navConsole,
    Icons.terminal,
    (_) => const ConsoleScreen(),
  ),
  _Destination(
    (l) => l.navPlots,
    (l) => l.navPlots,
    Icons.insert_chart_outlined,
    (_) => const PlotsScreen(),
  ),
  _Destination(
    (l) => l.navPackages,
    (l) => l.navPackages,
    Icons.widgets_outlined,
    (_) => const PackagesScreen(),
  ),
  _Destination(
    (l) => l.navSettings,
    (l) => l.settingsTitle,
    Icons.settings_outlined,
    (_) => const SettingsScreen(),
  ),
];

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool wide = MediaQuery.sizeOf(context).width >= 720;
    final int index = ref.watch(navIndexProvider);
    void select(int i) => ref.read(navIndexProvider.notifier).set(i);
    final _Destination dest = _destinations[index];
    final AppLocalizations l = context.l10n;

    // Inset below the status bar (and notches). The bottom is handled by the
    // navigation bar / its own safe area, so don't pad it here.
    final Widget body = SafeArea(
      bottom: false,
      child: Column(
        children: [
          _TopBar(title: dest.title(l)),
          const Divider(height: 1),
          // Retain editor and console drafts when visiting another pane.
          // In particular, the file browser must not dispose the editor before
          // it can ask how to handle unsaved changes to a different file.
          Expanded(
            child: IndexedStack(
              index: index,
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  ExcludeFocus(
                    excluding: i != index,
                    child: TickerMode(
                      enabled: i == index,
                      child: _destinations[i].builder(context),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      // Keep the workspace under the same keyed ancestry across the responsive
      // breakpoint, so rotating the device does not recreate its editor state.
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Tooltip(
                      message: d.title(l),
                      excludeFromSemantics: true,
                      child: Icon(d.icon),
                    ),
                    label: Semantics(
                      label: d.title(l),
                      excludeSemantics: true,
                      child: Text(d.label(l), maxLines: 1, softWrap: false),
                    ),
                  ),
              ],
            ),
          if (wide) const VerticalDivider(width: 1),
          Expanded(key: const ValueKey('workspace'), child: body),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AtelierColors.of(context).border),
                ),
              ),
              child: NavigationBar(
                selectedIndex: index,
                onDestinationSelected: select,
                destinations: [
                  for (var i = 0; i < _destinations.length; i++)
                    // The short tab label is shown; screen readers get the full pane title.
                    Semantics(
                      label: _destinations[i].title(l),
                      hint: MaterialLocalizations.of(context).tabLabel(
                        tabIndex: i + 1,
                        tabCount: _destinations.length,
                      ),
                      button: true,
                      selected: i == index,
                      onTap: () => select(i),
                      excludeSemantics: true,
                      child: NavigationDestination(
                        icon: Icon(_destinations[i].icon),
                        label: _destinations[i].label(l),
                        tooltip: _destinations[i].title(l),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// App bar showing the pane title and the active-kernel switcher.
class _TopBar extends ConsumerWidget {
  const _TopBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const _KernelSwitcher(),
        ],
      ),
    );
  }
}

class _KernelSwitcher extends ConsumerWidget {
  const _KernelSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final KernelLanguage active = ref.watch(activeKernelProvider);
    final AppLocalizations l = context.l10n;
    return SegmentedButton<KernelLanguage>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          Theme.of(context).textTheme.labelMedium,
        ),
      ),
      segments: [
        ButtonSegment(
          value: KernelLanguage.r,
          label: const Text('R', maxLines: 1, softWrap: false),
          tooltip: l.kernelName('R'),
          icon: const Icon(Icons.circle, size: 10, color: AppColors.rAccent),
        ),
        ButtonSegment(
          value: KernelLanguage.python,
          label: const Text('Python', maxLines: 1, softWrap: false),
          tooltip: l.kernelName('Python'),
          icon: const Icon(Icons.circle, size: 10, color: AppColors.pyAccent),
        ),
      ],
      selected: {active},
      onSelectionChanged: (sel) =>
          ref.read(activeKernelProvider.notifier).set(sel.first),
    );
  }
}
