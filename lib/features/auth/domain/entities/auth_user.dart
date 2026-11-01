import 'package:equatable/equatable.dart';

/// Usuario autenticado. Vive en `auth.users`, que gestiona Supabase.
/// Los datos del perfil están en [Profile], no aquí.
class AuthUser extends Equatable {
  final String id;
  final String email;

  const AuthUser({required this.id, required this.email});

  @override
  List<Object?> get props => [id, email];
}
