import 'package:equatable/equatable.dart';

sealed class ActivitiesEvent extends Equatable {
  const ActivitiesEvent();

  @override
  List<Object?> get props => [];
}

/// Carga inicial y reintento: trae las categorías y las actividades.
class ActivitiesRequested extends ActivitiesEvent {
  const ActivitiesRequested();
}

/// Filtra por categoría. `null` es «Todas».
class ActivityCategorySelected extends ActivitiesEvent {
  final String? categoryId;

  const ActivityCategorySelected(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}
