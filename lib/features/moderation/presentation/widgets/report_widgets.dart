import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/report_status.dart';
import '../../domain/entities/reported_content.dart';

/// Etiqueta pequeña con fondo suave.
class ModerationPill extends StatelessWidget {
  final String label;
  final Color color;

  const ModerationPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Color reportStatusColor(ReportStatus status) => switch (status) {
  ReportStatus.pending => AppColors.warning,
  ReportStatus.reviewing => AppColors.sageMid,
  ReportStatus.resolved => AppColors.sageDark,
  ReportStatus.dismissed => AppColors.inkSoft,
};

Color contentStatusColor(ContentStatus status) => switch (status) {
  ContentStatus.published => AppColors.sageMid,
  ContentStatus.hidden => AppColors.warning,
  ContentStatus.removed => AppColors.error,
};
