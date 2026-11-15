import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/coming_soon.dart';
import '../bloc/activity_detail_bloc.dart';
import '../bloc/activity_detail_event.dart';
import '../bloc/activity_detail_state.dart';
import '../services/link_opener.dart';

/// Detalle de un microdescanso: qué es, cuánto dura, cómo se hace y, si lo
/// tiene, un enlace para ampliar. [activityId] viene de la ruta y sirve para
/// reintentar.
class ActivityDetailPage extends StatelessWidget {
  final String activityId;
  final LinkOpener linkOpener;

  const ActivityDetailPage({
    super.key,
    required this.activityId,
    required this.linkOpener,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Microdescanso')),
      body: SafeArea(
        child: BlocBuilder<ActivityDetailBloc, ActivityDetailState>(
          builder: (context, state) => switch (state) {
            ActivityDetailInitial() || ActivityDetailLoading() => const Center(
              key: Key('activity_detail_loading'),
              child: CircularProgressIndicator(),
            ),
            ActivityDetailNotFound(:final message) => _NotFoundView(
              message: message,
            ),
            ActivityDetailFailure(:final message) => _ErrorView(
              message: message,
              activityId: activityId,
            ),
            ActivityDetailLoaded() => _DetailView(
              state: state,
              linkOpener: linkOpener,
            ),
          },
        ),
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  final ActivityDetailLoaded state;
  final LinkOpener linkOpener;

  const _DetailView({required this.state, required this.linkOpener});

  Future<void> _openLink(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await linkOpener.open(state.activity.externalUrl!);
    if (opened) return;

    messenger.showSnackBar(
      const SnackBar(
        content: Text('No pudimos abrir el enlace. Inténtalo más tarde.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activity = state.activity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            children: [
              Text(activity.title, style: textTheme.headlineSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Tag(
                    icon: Icons.schedule_rounded,
                    label: '${activity.durationMinutes} min',
                  ),
                  _Tag(label: activity.modality.label),
                ],
              ),
              const SizedBox(height: 18),
              Text(activity.description, style: textTheme.bodyLarge),
              if (state.hasSteps) ...[
                const SizedBox(height: 24),
                Text('Cómo hacerlo', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  key: const Key('activity_detail_steps'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.lineSoft),
                  ),
                  child: Text(
                    activity.contentText!,
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
              if (state.hasExternalLink) ...[
                const SizedBox(height: 20),
                _ExternalLink(
                  key: const Key('activity_detail_link'),
                  url: activity.externalUrl!,
                  onTap: () => _openLink(context),
                ),
              ],
            ],
          ),
        ),
        // El botón vive fuera del scroll para quedar siempre en el tercio
        // inferior, al alcance del pulgar.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: ElevatedButton(
            key: const Key('activity_detail_start_button'),
            onPressed: () => context.push(
              AppRoutes.activitySessionPath(activity.id),
              extra: activity,
            ),
            child: const Text('Comenzar'),
          ),
        ),
      ],
    );
  }
}

class _ExternalLink extends StatelessWidget {
  final String url;
  final VoidCallback onTap;

  const _ExternalLink({super.key, required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.beige,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.open_in_new_rounded,
              size: 20,
              color: AppColors.sageDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ver más sobre esto', style: textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData? icon;
  final String label;

  const _Tag({this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.sageDark),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(color: AppColors.sageDark),
          ),
        ],
      ),
    );
  }
}

/// La actividad no existe o dejó de estar publicada: reintentar no ayuda, se
/// vuelve a la lista.
class _NotFoundView extends StatelessWidget {
  final String message;

  const _NotFoundView({required this.message});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 44,
            color: AppColors.inkMuted,
          ),
          const SizedBox(height: 18),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('activity_detail_back_to_list_button'),
            onPressed: () => context.go(AppRoutes.activities),
            child: const Text('Volver a la lista'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final String activityId;

  const _ErrorView({required this.message, required this.activityId});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.error),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('activity_detail_retry_button'),
            onPressed: () => context.read<ActivityDetailBloc>().add(
              ActivityDetailRequested(activityId),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
