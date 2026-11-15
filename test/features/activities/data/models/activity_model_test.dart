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

    test('lee los pasos y el enlace externo cuando vienen', () {
      final activity = ActivityModel.fromJson({
        ...json(),
        'content_text': 'Inhala contando 4, sostén 7 y suelta en 8.',
        'external_url': 'https://ejemplo.org/guia',
      });

      expect(activity.contentText, 'Inhala contando 4, sostén 7 y suelta en 8.');
      expect(activity.externalUrl, 'https://ejemplo.org/guia');
    });

    test('sin pasos ni enlace quedan en null', () {
      final activity = ActivityModel.fromJson({
        ...json(),
        'content_text': null,
        'external_url': null,
      });

      expect(activity.contentText, isNull);
      expect(activity.externalUrl, isNull);
    });

    test('la lista no trae esas columnas y no falla', () {
      final activity = ActivityModel.fromJson(json());

      expect(activity.contentText, isNull);
      expect(activity.externalUrl, isNull);
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
