// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../../data/settings_store.dart';
import '../../kernel/kernel_controller.dart';
import '../../kernel/kernel_messages.dart';
import '../../l10n/l10n.dart';
import '../../theme/coder_theme_atelier.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  List<String> _parse(String raw) => raw
      .split(RegExp(r'[\s,]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _install(KernelLanguage lang) async {
    final List<String> names = _parse(_input.text);
    if (names.isEmpty) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    await ref.read(kernelControllerProvider).installPackages(lang, names);
  }

  @override
  Widget build(BuildContext context) {
    final KernelController kernel = ref.watch(kernelControllerProvider);
    final KernelLanguage lang = ref.watch(activeKernelProvider);
    final TextTheme t = Theme.of(context).textTheme;
    final AtelierColors c = AtelierColors.of(context);
    final AppLocalizations l = context.l10n;

    return ListenableBuilder(
      listenable: kernel,
      builder: (context, _) {
        final bool ready = kernel.stateFor(lang) == KernelState.ready;
        final bool busy = kernel.installing;
        final List<PackageResult> log = kernel.packageLogFor(lang);
        final String source = lang == KernelLanguage.r
            ? l.packagesSourceR
            : l.packagesSourcePython;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang == KernelLanguage.r
                        ? l.packagesTitleR
                        : l.packagesTitlePython,
                    style: t.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l.packagesSource(source), style: t.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.wifi, size: 13, color: c.warning),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(l.packagesNetwork, style: t.bodySmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          enabled: ready && !busy,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _install(lang),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: lang == KernelLanguage.r
                                ? l.packagesHintR
                                : l.packagesHintPython,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton.icon(
                        onPressed: ready && !busy ? () => _install(lang) : null,
                        icon: busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download, size: 18),
                        label: Text(
                          l.packagesInstall,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                  if (!ready)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        l.packagesStartFirst(kernelLabel(lang)),
                        style: t.bodySmall?.copyWith(color: c.warning),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: log.isEmpty
                  ? Center(child: Text(l.packagesNone, style: t.bodySmall))
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      itemCount: log.length,
                      itemBuilder: (context, i) =>
                          _LogTile(result: log[log.length - 1 - i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.result});
  final PackageResult result;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final AtelierColors c = AtelierColors.of(context);
    final bool pending = result.pending;
    final (IconData icon, Color color) = pending
        ? (Icons.hourglass_empty, c.warning)
        : result.ok
        ? (Icons.check_circle_outline, c.success)
        : (Icons.error_outline, c.danger);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.name, style: t.labelMedium),
                Text(
                  result.display(context.l10n),
                  style: t.bodySmall?.copyWith(
                    color: result.ok ? null : c.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
