import '../../domain/entities/activity_category.dart';

class ActivityCategoryModel extends ActivityCategory {
  const ActivityCategoryModel({
    required super.id,
    required super.name,
    required super.slug,
  });

  factory ActivityCategoryModel.fromJson(Map<String, dynamic> json) {
    return ActivityCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }
}
