import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({required super.id, required super.email});

  /// Supabase declara `email` como opcional porque una cuenta puede crearse
  /// solo con teléfono. Doulapp registra siempre con correo, así que una
  /// cuenta sin él es un dato que no sabemos interpretar.
  factory AuthUserModel.fromSupabaseUser(User user) {
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const FormatException('El usuario autenticado no tiene correo.');
    }
    return AuthUserModel(id: user.id, email: email);
  }

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
        id: json['id'] as String,
        email: json['email'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'email': email};
}
