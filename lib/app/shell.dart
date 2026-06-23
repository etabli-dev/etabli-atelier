// Copyright 2026 Raban Heller
// SPDX-License-Identifier: Apache-2.0

// The navigation shell: responsive rail/bottom-bar over the six feature panes,
// with a per-session kernel switcher (R / Python — two separate kernels).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_store.dart';
import '../theme/coder_theme_atelier.dart';
import 'app_providers.dart';
import '../features/files/files_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/console/console_screen.dart';
import '../features/plots/plots_screen.dart';
import '../features/packages/packages_screen.dart';
import '../features/settings/settings_screen.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.builder);
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

final List<_Destination> _destinations = <_Destination>[
  _Destination('Files', Icons.folder_outlined, (_) => const FilesScreen()),
  _Destination('Editor', Icons.code, (_) => const EditorScreen()),
  _Destination('Console', Icons.terminal, (_) => const ConsoleScreen()),
  _Destination('Plots', Icons.insert_chart_outlined, (_) => const PlotsScreen()),
  _Destination('Packages', Icons.widgets_outlined, (_) => const PackagesScreen()),
  _Destination('Settings', Icons.settings_outlined, (_) => const SettingsScreen()),
];

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool wide = MediaQuery.sizeOf(context).width >= 720;
    final int index = ref.watch(navIndexProvider);
    void select(int i) => ref.read(navIndexProvider.notifier).set(i);
    final _Destination dest = _destinations[index];

    // Inset below the status bar (and notches). The bottom is handled by the
    // navigation bar / its own safe area, so don't pad it here.
    final Widget body = SafeArea(
      bottom: false,
      child: Column(
        children: [
          _TopBar(title: dest.label),
          const Divider(height: 1),
          Expanded(child: dest.builder(context)),
        ],
      ),
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: select,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
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
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
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
    return SegmentedButton<KernelLanguage>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          Theme.of(context).textTheme.labelMedium,
        ),
      ),
      segments: const [
        ButtonSegment(
          value: KernelLanguage.r,
          label: Text('R'),
          icon: Icon(Icons.circle, size: 10, color: AppColors.rAccent),
        ),
        ButtonSegment(
          value: KernelLanguage.python,
          label: Text('Python'),
          icon: Icon(Icons.circle, size: 10, color: AppColors.pyAccent),
        ),
      ],
      selected: {active},
      onSelectionChanged: (sel) =>
          ref.read(activeKernelProvider.notifier).set(sel.first),
    );
  }
}
