import 'package:equatable/equatable.dart';

/// Tema de la comunidad: lactancia, emociones, primeras semanas…
class CommunityCategory extends Equatable {
  final String id;
  final String name;
  final String slug;

  const CommunityCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  @override
  List<Object?> get props => [id, name, slug];
}
