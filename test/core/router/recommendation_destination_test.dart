import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/core/router/recommendation_destination.dart';
import 'package:doulapp/features/wellbeing/domain/entities/recommendation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Recommendation rec({String? activityId, String? destinationCode}) {
    return Recommendation(
      id: 'rec-1',
      message: 'Mensaje',
      priority: 10,
      activityId: activityId,
      destinationCode: destinationCode,
    );
  }

  test('con activity_id abre el detalle de esa actividad', () {
    expect(
      recommendationRoute(rec(activityId: 'act-1')),
      AppRoutes.activityDetailPath('act-1'),
    );
  });

  test('el activity_id manda sobre el destination_code', () {
    // En los datos de demostración las recomendaciones con activity_id
    // también traen destination_code = activities.
    expect(
      recommendationRoute(
        rec(activityId: 'act-1', destinationCode: 'activities'),
      ),
      AppRoutes.activityDetailPath('act-1'),
    );
  });

  test('destination_code = activities abre la lista de microdescansos', () {
    expect(
      recommendationRoute(rec(destinationCode: 'activities')),
      AppRoutes.activities,
    );
  });

  test('destination_code = mood_checkin abre el check-in de ánimo', () {
    expect(
      recommendationRoute(rec(destinationCode: 'mood_checkin')),
      AppRoutes.moodCheckin,
    );
  });

  test('destination_code = community abre la comunidad', () {
    expect(
      recommendationRoute(rec(destinationCode: 'community')),
      AppRoutes.community,
    );
  });

  test('un destino desconocido no lleva a ninguna parte', () {
    expect(recommendationRoute(rec(destinationCode: 'podcasts')), isNull);
  });

  test('sin actividad ni destino no lleva a ninguna parte', () {
    expect(recommendationRoute(rec()), isNull);
  });

  test('una actividad en blanco se ignora', () {
    expect(
      recommendationRoute(rec(activityId: '  ', destinationCode: 'activities')),
      AppRoutes.activities,
    );
  });

  test('la ruta del detalle lleva el id de la actividad', () {
    expect(AppRoutes.activityDetailPath('act-7'), contains('act-7'));
    expect(AppRoutes.activityDetailPath('act-7'), startsWith(AppRoutes.activities));
  });
}
