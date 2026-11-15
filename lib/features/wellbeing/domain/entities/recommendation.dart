import 'package:equatable/equatable.dart';

/// Sugerencia para una necesidad. La lógica vive como datos en
/// `need_recommendations`, no como código.
///
/// [activityId] apunta a un microdescanso concreto y [destinationCode] a una
/// sección de la app; pueden venir los dos, uno o ninguno. [priority] es menor
/// cuando la sugerencia es más relevante.
class Recommendation extends Equatable {
  final String id;
  final String message;
  final int priority;
  final String? activityId;
  final String? destinationCode;

  const Recommendation({
    required this.id,
    required this.message,
    required this.priority,
    this.activityId,
    this.destinationCode,
  });

  @override
  List<Object?> get props => [
    id,
    message,
    priority,
    activityId,
    destinationCode,
  ];
}
