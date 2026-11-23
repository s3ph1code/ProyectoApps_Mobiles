import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../community/presentation/utils/community_format.dart';
import '../../domain/entities/content_report.dart';
import '../../domain/entities/report_status.dart';
import '../../domain/entities/reported_content.dart';
import '../bloc/report_detail_bloc.dart';
import '../bloc/report_detail_event.dart';
import '../bloc/report_detail_state.dart';
import '../widgets/report_widgets.dart';

/// Un reporte con su contenido y las acciones de moderación.
class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reporte')),
      body: SafeArea(
        child: BlocConsumer<ReportDetailBloc, ReportDetailState>(
          listenWhen: (previous, current) =>
              current.notice != null && current.noticeId != previous.noticeId,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.notice!)));
          },
          builder: (context, state) => Column(
            children: [
              if (state.isWorking)
                const LinearProgressIndicator(
                  key: Key('report_working'),
                  color: AppColors.sage,
                ),
              Expanded(child: _Content(state: state)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final ReportDetailState state;

  const _Content({required this.state});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final report = state.report;
    final details = report.details?.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(report.reason.label, style: textTheme.titleLarge),
            ),
            const SizedBox(width: 8),
            ModerationPill(
              key: const Key('report_status_pill'),
              label: report.status.label,
              color: reportStatusColor(report.status),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Reportado ${formatPostDate(report.createdAt).toLowerCase()} por '
          '${authorLabel(report.reporterName)}',
          style: textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Lo que contó quien reportó',
          child: Text(
            details == null || details.isEmpty
                ? 'No dejó más detalles.'
                : details,
            key: const Key('report_details'),
            style: textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),
        _ContentCard(content: report.content),
        const SizedBox(height: 20),
        _StatusActions(report: report, enabled: !state.isWorking),
        const SizedBox(height: 20),
        _ContentActions(content: report.content, enabled: !state.isWorking),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final ReportedContent content;

  const _ContentCard({required this.content});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _Section(
      title: '${content.kind.label} reportada',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  authorLabel(content.authorName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              ModerationPill(
                key: const Key('content_status_pill'),
                label: content.status.label,
                color: contentStatusColor(content.status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            content.body,
            key: const Key('report_content_body'),
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  final ContentReport report;
  final bool enabled;

  const _StatusActions({required this.report, required this.enabled});

  static const _options = [
    (ReportStatus.reviewing, 'Marcar en revisión', Icons.visibility_outlined),
    (ReportStatus.resolved, 'Marcar como resuelto', Icons.check_rounded),
    (ReportStatus.dismissed, 'Descartar reporte', Icons.close_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (status, label, icon) in _options)
          if (status != report.status)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton.icon(
                key: Key('status_${status.code}'),
                onPressed: enabled
                    ? () => context.read<ReportDetailBloc>().add(
                        ReportStatusChanged(status),
                      )
                    : null,
                icon: Icon(icon, size: 20),
                label: Text(label),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.sageDark,
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: AppColors.sageLight),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
      ],
    );
  }
}

class _ContentActions extends StatelessWidget {
  final ReportedContent content;
  final bool enabled;

  const _ContentActions({required this.content, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final noun = content.kind == ReportedContentKind.post
        ? 'la publicación'
        : 'el comentario';

    if (content.status != ContentStatus.published) {
      return Text(
        'Este contenido ya está ${content.status.label.toLowerCase()} y las '
        'demás usuarias no lo ven.',
        key: const Key('content_already_moderated'),
        textAlign: TextAlign.center,
        style: textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const Key('content_hide'),
          onPressed: enabled
              ? () => _confirm(
                  context,
                  action: ModerationAction.hide,
                  title: '¿Ocultar $noun?',
                  message:
                      'Las demás usuarias dejarán de verlo y el reporte '
                      'quedará resuelto.',
                  confirmLabel: 'Ocultar',
                )
              : null,
          icon: const Icon(Icons.visibility_off_outlined, size: 20),
          label: Text('Ocultar $noun'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const Key('content_remove'),
          onPressed: enabled
              ? () => _confirm(
                  context,
                  action: ModerationAction.remove,
                  title: '¿Eliminar $noun?',
                  message:
                      'Se retira de la comunidad y el reporte quedará '
                      'resuelto.',
                  confirmLabel: 'Eliminar',
                )
              : null,
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          label: Text('Eliminar $noun'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: AppColors.error),
            shape: const StadiumBorder(),
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required ModerationAction action,
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final bloc = context.read<ReportDetailBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            key: const Key('confirm_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm_ok'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) bloc.add(ContentModerationRequested(action));
  }
}
