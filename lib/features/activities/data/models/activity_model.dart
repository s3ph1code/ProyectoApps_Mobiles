import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_modality.dart';

class ActivityModel extends Activity {
  const ActivityModel({
    required super.id,
    required super.categoryId,
    required super.title,
    required super.description,
    required super.modality,
    required super.durationMinutes,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      modality: ActivityModality.fromCode(json['modality'] as String),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
    );
  }
}
