import '../../domain/entities/blocked_user.dart';

class BlockedUserModel extends BlockedUser {
  const BlockedUserModel({
    required super.userId,
    super.displayName,
    required super.blockedAt,
  });

  /// Fila de `user_blocks` con el perfil de la bloqueada embebido como
  /// `blocked`. Si su perfil es privado, `blocked` llega nulo.
  factory BlockedUserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['blocked'] as Map<String, dynamic>?;
    return BlockedUserModel(
      userId: json['blocked_id'] as String,
      displayName: profile?['display_name'] as String?,
      blockedAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
