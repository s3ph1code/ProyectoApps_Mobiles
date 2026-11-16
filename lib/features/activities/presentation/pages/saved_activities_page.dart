import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../domain/entities/activity.dart';
import '../bloc/saved_activities_bloc.dart';
import '../bloc/saved_activities_event.dart';
import '../bloc/saved_activities_state.dart';
import '../widgets/save_activity_button.dart';

/// Consulta de actividades guardadas por la usuaria autenticada.
class SavedActivitiesPage extends StatelessWidget {
  const SavedActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actividades guardadas')),
      body: SafeArea(
        child: BlocConsumer<SavedActivitiesBloc, SavedActivitiesState>(
          listenWhen: (previous, current) =>
              current is SavedActivitiesLoaded && current.noticeMessage != null,
          listener: (context, state) {
            if (state is SavedActivitiesLoaded && state.noticeMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.noticeMessage!),
                  duration: const Duration(seconds: 3),
                ),
              );
              context
                  .read<SavedActivitiesBloc>()
                  .add(const SavedActivitiesNoticeDismissed());
            }
          },
          builder: (context, state) => switch (state) {
            SavedActivitiesInitial() || SavedActivitiesLoading() => const Center(
              key: Key('saved_activities_loading'),
              child: CircularProgressIndicator(),
            ),
            SavedActivitiesFailure(:final message) => _ErrorView(
              message: message,
            ),
            SavedActivitiesLoaded(:final activities) => activities.isEmpty
                ? const _EmptyView()
                : _SavedActivitiesList(activities: activities),
          },
        ),
      ),
    );
  }
}

class _SavedActivitiesList extends StatelessWidget {
  final List<Activity> activities;

  const _SavedActivitiesList({required this.activities});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const Key('saved_activities_list'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: activities.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _SavedActivityCard(
          key: Key('saved_activity_item_${activity.id}'),
          activity: activity,
        );
      },
    );
  }
}

class _SavedActivityCard extends StatelessWidget {
  final Activity activity;

  const _SavedActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: () => context.push(AppRoutes.activityDetailPath(activity.id)),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      activity.title,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SaveActivityButton(activity: activity),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                activity.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
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
                  ),
                  TextButton.icon(
                    key: Key('saved_activity_start_${activity.id}'),
                    onPressed: () => context.push(
                      AppRoutes.activitySessionPath(activity.id),
                      extra: activity,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Comenzar'),
                  ),
                ],
              ),
            ],
          ),
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      key: const Key('saved_activities_empty'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.bookmark_border_rounded,
            size: 48,
            color: AppColors.sage,
          ),
          const SizedBox(height: 18),
          Text(
            'Aún no tienes actividades guardadas',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Guarda las pausas que más te gusten para encontrarlas fácilmente '
            'después cuando necesites un respiro.',
            key: const Key('saved_activities_empty_message'),
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton(
              key: const Key('saved_activities_explore_button'),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.activities);
                }
              },
              child: const Text('Explorar microdescansos'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

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
            key: const Key('saved_activities_error'),
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
            key: const Key('saved_activities_retry_button'),
            onPressed: () => context
                .read<SavedActivitiesBloc>()
                .add(const SavedActivitiesRequested()),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
