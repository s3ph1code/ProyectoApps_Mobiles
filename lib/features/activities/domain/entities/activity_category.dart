import 'package:equatable/equatable.dart';

/// Categoría de microdescansos: respiración, descanso, movimiento suave…
class ActivityCategory extends Equatable {
  final String id;
  final String name;
  final String slug;

  const ActivityCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  @override
  List<Object?> get props => [id, name, slug];
}
