import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../community/presentation/utils/community_format.dart';
import '../../domain/entities/content_report.dart';
import '../../domain/entities/report_status.dart';
import '../bloc/moderation_bloc.dart';
import '../bloc/moderation_event.dart';
import '../bloc/moderation_state.dart';
import '../widgets/report_widgets.dart';

/// Perfil → Moderación: los reportes de la comunidad, por estado.
class ModerationPage extends StatelessWidget {
  const ModerationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moderación')),
      body: SafeArea(
        child: BlocBuilder<ModerationBloc, ModerationState>(
          builder: (context, state) {
            final filter = switch (state) {
              ModerationLoading(:final filter) => filter,
              ModerationLoaded(:final filter) => filter,
              ModerationFailure(:final filter) => filter,
              _ => ReportStatus.pending,
            };

            return Column(
              children: [
                if (state is! ModerationForbidden) _FilterBar(selected: filter),
                Expanded(child: _Body(state: state)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final ReportStatus selected;

  const _FilterBar({required this.selected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          for (final status in ReportStatus.values) ...[
            ChoiceChip(
              key: Key('filter_${status.code}'),
              label: Text(status.label),
              selected: status == selected,
              onSelected: (_) => context.read<ModerationBloc>().add(
                ModerationFilterChanged(status),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final ModerationState state;

  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ModerationInitial() || ModerationLoading() => const Center(
        key: Key('moderation_loading'),
        child: CircularProgressIndicator(color: AppColors.sage),
      ),
      ModerationForbidden() => const _Message(
        icon: Icons.lock_outline_rounded,
        title: 'Esta sección es para moderación',
        message: 'Tu cuenta no tiene permiso para revisar reportes.',
      ),
      ModerationFailure(:final message) => _Message(
        icon: Icons.cloud_off_rounded,
        title: 'No pudimos cargar los reportes',
        message: message,
        actionLabel: 'Reintentar',
        onAction: () =>
            context.read<ModerationBloc>().add(const ModerationRefreshed()),
      ),
      ModerationLoaded(:final reports, :final filter) when reports.isEmpty =>
        _Message(
          icon: Icons.check_circle_outline_rounded,
          title: 'No hay reportes ${_plural(filter)}',
          message: 'Cuando haya algo que revisar, aparecerá aquí.',
        ),
      ModerationLoaded(:final reports) => RefreshIndicator(
        onRefresh: () async =>
            context.read<ModerationBloc>().add(const ModerationRefreshed()),
        child: ListView.separated(
          key: const Key('moderation_list'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          itemCount: reports.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _ReportTile(report: reports[index]),
        ),
      ),
    };
  }

  static String _plural(ReportStatus status) => switch (status) {
    ReportStatus.pending => 'pendientes',
    ReportStatus.reviewing => 'en revisión',
    ReportStatus.resolved => 'resueltos',
    ReportStatus.dismissed => 'descartados',
  };
}

class _ReportTile extends StatelessWidget {
  final ContentReport report;

  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final content = report.content;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        key: Key('report_${report.id}'),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () async {
          final bloc = context.read<ModerationBloc>();
          await context.push<void>(AppRoutes.reportDetail, extra: report);
          // Lo que se resolvió allí ya no pertenece a este filtro.
          bloc.add(const ModerationRefreshed());
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.reason.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ModerationPill(
                    label: content.kind.label,
                    color: AppColors.sageDark,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                content.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Autora: ${authorLabel(content.authorName)} · '
                '${formatPostDate(report.createdAt)}',
                style: textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.sage),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('moderation_retry'),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
