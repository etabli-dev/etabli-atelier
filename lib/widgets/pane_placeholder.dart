// Copyright 2026 Raban Heller
// SPDX-License-Identifier: Apache-2.0

// Consistent "coming in milestone N" placeholder for not-yet-built panes.

import 'package:flutter/material.dart';

import '../theme/coder_theme_atelier.dart';

class PanePlaceholder extends StatelessWidget {
  const PanePlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.accent),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: t.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: t.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
