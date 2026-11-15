import 'package:equatable/equatable.dart';

import 'activity_modality.dart';

/// Un microdescanso publicado: una pausa breve de autocuidado.
class Activity extends Equatable {
  final String id;
  final String categoryId;
  final String title;
  final String description;
  final ActivityModality modality;
  final int durationMinutes;

  const Activity({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.modality,
    required this.durationMinutes,
  });

  @override
  List<Object?> get props => [
    id,
    categoryId,
    title,
    description,
    modality,
    durationMinutes,
  ];
}
