import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../../data/settings_store.dart';
import '../../kernel/kernel_controller.dart';
import '../../theme/theme.dart';

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

    return ListenableBuilder(
      listenable: kernel,
      builder: (context, _) {
        final bool ready = kernel.stateFor(lang) == KernelState.ready;
        final bool busy = kernel.installing;
        final List<PackageResult> log = kernel.packageLogFor(lang);
        final String source = lang == KernelLanguage.r
            ? 'repo.r-wasm.org (WebR WASM binaries)'
            : 'PyPI via micropip (pure-Python & WASM wheels)';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang == KernelLanguage.r ? 'R packages' : 'Python packages',
                    style: t.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Source: $source', style: t.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.wifi, size: 13, color: AppColors.warning),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Installing requires a network connection. '
                          'Bundled packages already work offline.',
                          style: t.bodySmall,
                        ),
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
                                ? 'e.g. ggplot2, jsonlite'
                                : 'e.g. requests, sympy',
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.download, size: 18),
                        label: const Text('Install'),
                      ),
                    ],
                  ),
                  if (!ready)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        'Switch to and start the ${lang == KernelLanguage.r ? 'R' : 'Python'} kernel first (Console tab).',
                        style: t.bodySmall?.copyWith(color: AppColors.warning),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: log.isEmpty
                  ? Center(
                      child: Text('No installations yet.',
                          style: t.bodySmall),
                    )
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
    final bool pending = result.message.startsWith('Installing');
    final (IconData icon, Color color) = pending
        ? (Icons.hourglass_empty, AppColors.warning)
        : result.ok
            ? (Icons.check_circle_outline, AppColors.accent)
            : (Icons.error_outline, AppColors.danger);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 4),
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
                Text(result.message,
                    style: t.bodySmall?.copyWith(
                        color: result.ok || pending ? null : AppColors.danger)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
