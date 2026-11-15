import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_activities.dart';
import '../../domain/usecases/get_activity_categories.dart';
import 'activities_event.dart';
import 'activities_state.dart';

/// Lista de microdescansos con filtro por categoría.
class ActivitiesBloc extends Bloc<ActivitiesEvent, ActivitiesState> {
  final GetActivityCategories getActivityCategories;
  final GetActivities getActivities;

  ActivitiesBloc({
    required this.getActivityCategories,
    required this.getActivities,
  }) : super(const ActivitiesInitial()) {
    on<ActivitiesRequested>(_onRequested);
    on<ActivityCategorySelected>(_onCategorySelected);
  }

  Future<void> _onRequested(
    ActivitiesRequested event,
    Emitter<ActivitiesState> emit,
  ) async {
    if (state is ActivitiesLoading) return;
    emit(const ActivitiesLoading());

    final categoriesResult = await getActivityCategories(const NoParams());
    final categories = categoriesResult.fold((_) => null, (value) => value);
    if (categories == null) {
      emit(
        ActivitiesFailure(
          categoriesResult.fold((failure) => failure.message, (_) => ''),
        ),
      );
      return;
    }

    final activitiesResult = await getActivities(const GetActivitiesParams());

    activitiesResult.fold(
      (failure) => emit(ActivitiesFailure(failure.message)),
      (activities) => emit(
        ActivitiesLoaded(categories: categories, activities: activities),
      ),
    );
  }

  Future<void> _onCategorySelected(
    ActivityCategorySelected event,
    Emitter<ActivitiesState> emit,
  ) async {
    final current = state;
    if (current is! ActivitiesLoaded) return;

    emit(
      current.copyWith(
        selectedCategoryId: event.categoryId,
        clearCategory: event.categoryId == null,
        isLoadingActivities: true,
      ),
    );

    final result = await getActivities(
      GetActivitiesParams(categoryId: event.categoryId),
    );

    result.fold(
      (failure) => emit(ActivitiesFailure(failure.message)),
      (activities) => emit(
        current.copyWith(
          activities: activities,
          selectedCategoryId: event.categoryId,
          clearCategory: event.categoryId == null,
          isLoadingActivities: false,
        ),
      ),
    );
  }
}
