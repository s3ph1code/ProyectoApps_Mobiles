import 'package:equatable/equatable.dart';

import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_category.dart';

sealed class ActivitiesState extends Equatable {
  const ActivitiesState();

  @override
  List<Object?> get props => [];
}

class ActivitiesInitial extends ActivitiesState {
  const ActivitiesInitial();
}

class ActivitiesLoading extends ActivitiesState {
  const ActivitiesLoading();
}

/// Catálogo cargado. [selectedCategoryId] en `null` es «Todas», y
/// [isLoadingActivities] marca el cambio de filtro, para no esconder los
/// chips mientras llega la nueva lista.
class ActivitiesLoaded extends ActivitiesState {
  final List<ActivityCategory> categories;
  final List<Activity> activities;
  final String? selectedCategoryId;
  final bool isLoadingActivities;

  const ActivitiesLoaded({
    required this.categories,
    required this.activities,
    this.selectedCategoryId,
    this.isLoadingActivities = false,
  });

  bool get isEmpty => activities.isEmpty;

  ActivitiesLoaded copyWith({
    List<Activity>? activities,
    String? selectedCategoryId,
    bool? isLoadingActivities,
    bool clearCategory = false,
  }) {
    return ActivitiesLoaded(
      categories: categories,
      activities: activities ?? this.activities,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      isLoadingActivities: isLoadingActivities ?? this.isLoadingActivities,
    );
  }

  @override
  List<Object?> get props => [
    categories,
    activities,
    selectedCategoryId,
    isLoadingActivities,
  ];
}

class ActivitiesFailure extends ActivitiesState {
  final String message;

  const ActivitiesFailure(this.message);

  @override
  List<Object?> get props => [message];
}
