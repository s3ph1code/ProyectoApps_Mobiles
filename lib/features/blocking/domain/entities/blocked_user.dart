import 'package:equatable/equatable.dart';

/// Una usuaria a la que bloqueé.
class BlockedUser extends Equatable {
  final String userId;

  /// `null` cuando su perfil es privado o ya no existe.
  final String? displayName;
  final DateTime blockedAt;

  const BlockedUser({
    required this.userId,
    this.displayName,
    required this.blockedAt,
  });

  @override
  List<Object?> get props => [userId, displayName, blockedAt];
}
