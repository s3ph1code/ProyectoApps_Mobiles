import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_category.dart';
import '../bloc/activities_bloc.dart';
import '../bloc/activities_event.dart';
import '../bloc/activities_state.dart';
import '../bloc/saved_activities_bloc.dart';
import '../bloc/saved_activities_event.dart';
import '../bloc/saved_activities_state.dart';
import '../widgets/save_activity_button.dart';

/// «Microdescansos»: las pausas breves de autocuidado publicadas, filtrables
/// por categoría. Solo muestra lo que el BLoC le entrega.
class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  SavedActivitiesBloc? _findSavedBloc(BuildContext context) {
    try {
      return context.read<SavedActivitiesBloc>();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: BlocBuilder<ActivitiesBloc, ActivitiesState>(
        builder: (context, state) => switch (state) {
          ActivitiesInitial() || ActivitiesLoading() => const Center(
            key: Key('activities_loading'),
            child: CircularProgressIndicator(),
          ),
          ActivitiesFailure(:final message) => _ErrorView(message: message),
          ActivitiesLoaded() => _CatalogView(state: state),
        },
      ),
    );

    final savedBloc = _findSavedBloc(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Microdescansos'),
        actions: [
          IconButton(
            key: const Key('activities_saved_button'),
            tooltip: 'Actividades guardadas',
            icon: const Icon(Icons.bookmark_border_rounded),
            onPressed: () => context.push(AppRoutes.savedActivities),
          ),
        ],
      ),
      body: savedBloc != null
          ? BlocListener<SavedActivitiesBloc, SavedActivitiesState>(
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
              child: body,
            )
          : body,
    );
  }
}

class _CatalogView extends StatelessWidget {
  final ActivitiesLoaded state;

  const _CatalogView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategoryFilters(
          categories: state.categories,
          selectedCategoryId: state.selectedCategoryId,
        ),
        if (state.isLoadingActivities)
          const LinearProgressIndicator(minHeight: 2)
        else
          const SizedBox(height: 2),
        Expanded(
          child: state.isEmpty
              ? const _EmptyView()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  itemCount: state.activities.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final activity = state.activities[index];
                    return _ActivityCard(
                      key: Key('activities_item_${activity.id}'),
                      activity: activity,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Chips de categoría con «Todas» al principio. Se desplazan en horizontal
/// para que quepan en un teléfono angosto.
class _CategoryFilters extends StatelessWidget {
  final List<ActivityCategory> categories;
  final String? selectedCategoryId;

  const _CategoryFilters({
    required this.categories,
    required this.selectedCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Row(
        children: [
          _CategoryChip(
            key: const Key('activities_chip_all'),
            label: 'Todas',
            selected: selectedCategoryId == null,
            categoryId: null,
          ),
          for (final category in categories) ...[
            const SizedBox(width: 8),
            _CategoryChip(
              key: Key('activities_chip_${category.id}'),
              label: category.name,
              selected: selectedCategoryId == category.id,
              categoryId: category.id,
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final String? categoryId;

  const _CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        onTap: () => context.read<ActivitiesBloc>().add(
          ActivityCategorySelected(categoryId),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.sage.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(
              color: selected ? AppColors.sage : AppColors.lineSoft,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: selected ? AppColors.sageDark : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;

  const _ActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        // Con push, el detalle se abre encima y la flecha vuelve a la lista
        // manteniendo el filtro elegido.
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
                children: [
                  Expanded(
                    child: Text(activity.title, style: textTheme.titleMedium),
                  ),
                  const SizedBox(width: 4),
                  SaveActivityButton(activity: activity),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.inkMuted,
                  ),
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
                    key: Key('activity_start_${activity.id}'),
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
      key: const Key('activities_empty'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.spa_outlined, size: 44, color: AppColors.sage),
          const SizedBox(height: 18),
          Text(
            'Nada por aquí todavía',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Esta categoría aún no tiene microdescansos. Prueba con otra o '
            'mira todas.',
            key: const Key('activities_empty_message'),
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
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
            key: const Key('activities_error'),
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
            key: const Key('activities_retry_button'),
            onPressed: () =>
                context.read<ActivitiesBloc>().add(const ActivitiesRequested()),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
