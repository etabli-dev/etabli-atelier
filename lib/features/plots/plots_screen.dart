// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../../data/settings_store.dart';
import '../../kernel/kernel_controller.dart';
import '../../l10n/l10n.dart';
import '../../theme/coder_theme_atelier.dart';

class PlotsScreen extends ConsumerWidget {
  const PlotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final KernelController kernel = ref.watch(kernelControllerProvider);
    final KernelLanguage lang = ref.watch(activeKernelProvider);

    return ListenableBuilder(
      listenable: kernel,
      builder: (context, _) {
        final List<Uint8List> plots = kernel.plotsFor(lang);
        return Column(
          children: [
            _Header(
              language: lang,
              count: plots.length,
              onClear: plots.isEmpty ? null : () => kernel.clearPlots(lang),
            ),
            const Divider(height: 1),
            Expanded(
              child: plots.isEmpty
                  ? _EmptyState(language: lang)
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      reverse: true,
                      itemCount: plots.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, i) =>
                          _PlotCard(bytes: plots[i], index: i + 1),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.language,
    required this.count,
    required this.onClear,
  });

  final KernelLanguage language;
  final int count;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final String src = language == KernelLanguage.r
        ? 'ggplot2 / base R'
        : 'matplotlib';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$src  ·  $count',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.labelMedium,
            ),
          ),
          IconButton(
            tooltip: context.l10n.plotsClear,
            icon: const Icon(Icons.cleaning_services_outlined, size: 18),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

class _PlotCard extends StatelessWidget {
  const _PlotCard({required this.bytes, required this.index});
  final Uint8List bytes;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              context.l10n.plotsItem('$index'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Divider(height: 1),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: AppRadius.mdRadius,
            ),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: InteractiveViewer(
                maxScale: 5,
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.language});
  final KernelLanguage language;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = context.l10n;
    final AtelierColors c = AtelierColors.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    // The code examples are verbatim; only the prose around them is translated.
    final String hint = language == KernelLanguage.r
        ? '${l.plotsHintR}\nplot(mtcars\$wt, mtcars\$mpg)\n\n${l.plotsHintGgplot}'
        : '${l.plotsHintPython}\nimport matplotlib.pyplot as plt\nplt.plot([1, 2, 3]); plt.title("demo")';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_chart_outlined, size: 40, color: c.accent),
            const SizedBox(height: AppSpacing.md),
            Text(l.plotsEmpty, style: t.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(hint, textAlign: TextAlign.center, style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}
