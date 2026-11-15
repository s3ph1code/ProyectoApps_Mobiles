import 'package:doulapp/features/activities/data/models/activity_category_model.dart';
import 'package:doulapp/features/activities/data/models/activity_model.dart';
import 'package:doulapp/features/activities/domain/entities/activity_modality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityCategoryModel', () {
    test('lee id, nombre y slug', () {
      final category = ActivityCategoryModel.fromJson(const {
        'id': 'cat-1',
        'name': 'Respiración',
        'slug': 'respiracion',
        'is_active': true,
      });

      expect(category.id, 'cat-1');
      expect(category.name, 'Respiración');
      expect(category.slug, 'respiracion');
    });
  });

  group('ActivityModel', () {
    Map<String, dynamic> json({String modality = 'do'}) => {
      'id': 'act-1',
      'category_id': 'cat-1',
      'title': 'Respiración 4-7-8',
      'description': 'Una pausa para bajar el ritmo.',
      'modality': modality,
      'duration_minutes': 3,
    };

    test('lee los campos que la lista necesita', () {
      final activity = ActivityModel.fromJson(json());

      expect(activity.id, 'act-1');
      expect(activity.categoryId, 'cat-1');
      expect(activity.title, 'Respiración 4-7-8');
      expect(activity.description, 'Una pausa para bajar el ritmo.');
      expect(activity.durationMinutes, 3);
      expect(activity.modality, ActivityModality.practice);
    });

    test('traduce cada modalidad de la base', () {
      expect(
        ActivityModel.fromJson(json(modality: 'read')).modality,
        ActivityModality.read,
      );
      expect(
        ActivityModel.fromJson(json(modality: 'listen')).modality,
        ActivityModality.listen,
      );
      expect(
        ActivityModel.fromJson(json(modality: 'watch')).modality,
        ActivityModality.watch,
      );
    });
  });
}
