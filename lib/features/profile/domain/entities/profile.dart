import 'package:equatable/equatable.dart';

import 'account_status.dart';

/// Perfil del usuario, 1:1 con el usuario autenticado: comparte su `id`.
class Profile extends Equatable {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final AccountStatus accountStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    required this.accountStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    displayName,
    avatarUrl,
    bio,
    accountStatus,
    createdAt,
    updatedAt,
  ];
}
