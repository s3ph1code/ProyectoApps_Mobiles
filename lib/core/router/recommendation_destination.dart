import '../../features/wellbeing/domain/entities/recommendation.dart';
import 'app_router.dart';

/// Códigos de `need_recommendations.destination_code` y la ruta que abren.
const _routeByDestinationCode = {
  'activities': AppRoutes.activities,
  'mood_checkin': AppRoutes.moodCheckin,
  'community': AppRoutes.community,
};

/// A dónde lleva una recomendación, o `null` si no lleva a ninguna parte.
///
/// Resolver el destino es trabajo de la capa de navegación, no de la pantalla.
/// Una actividad concreta manda sobre el código de destino: en los datos de
/// demostración las recomendaciones con `activity_id` también traen
/// `destination_code = activities`, y abrir la actividad es más útil que
/// dejar a la usuaria buscándola en la lista.
String? recommendationRoute(Recommendation recommendation) {
  final activityId = recommendation.activityId?.trim();
  if (activityId != null && activityId.isNotEmpty) {
    return AppRoutes.activityDetailPath(activityId);
  }

  return _routeByDestinationCode[recommendation.destinationCode];
}
