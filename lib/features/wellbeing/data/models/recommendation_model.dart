import '../../domain/entities/recommendation.dart';

class RecommendationModel extends Recommendation {
  const RecommendationModel({
    required super.id,
    required super.message,
    required super.priority,
    super.activityId,
    super.destinationCode,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      id: json['id'] as String,
      message: json['message'] as String,
      priority: (json['priority'] as num).toInt(),
      activityId: json['activity_id'] as String?,
      destinationCode: json['destination_code'] as String?,
    );
  }
}
