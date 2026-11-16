import '../../domain/entities/community_category.dart';

class CommunityCategoryModel extends CommunityCategory {
  const CommunityCategoryModel({
    required super.id,
    required super.name,
    required super.slug,
  });

  factory CommunityCategoryModel.fromJson(Map<String, dynamic> json) {
    return CommunityCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }
}
