import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../models/auth_user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUserModel> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<AuthUserModel> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);

  Future<AuthUserModel?> getCurrentUser();

  Stream<AuthUserModel?> authStateChanges();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final supabase.SupabaseClient client;

  AuthRemoteDataSourceImpl({required this.client});

  supabase.GoTrueClient get _auth => client.auth;

  @override
  Future<AuthUserModel> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _guard(() async {
      // El trigger `handle_new_user` crea el perfil al registrarse y toma el
      // nombre de `display_name` en la metadata. Sin nombre usa uno
      // provisional tomado del correo.
      final name = displayName?.trim();
      final response = name == null || name.isEmpty
          ? await _auth.signUp(email: email.trim(), password: password)
          : await _auth.signUp(
              email: email.trim(),
              password: password,
              data: {'display_name': name},
            );

      final user = response.user;
      if (user == null) {
        throw const AuthException('El registro no devolvió un usuario.');
      }
      return AuthUserModel.fromSupabaseUser(user);
    });
  }

  @override
  Future<AuthUserModel> signIn({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('El inicio de sesión no devolvió un usuario.');
      }
      return AuthUserModel.fromSupabaseUser(user);
    });
  }

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());

  @override
  Future<void> sendPasswordReset(String email) {
    return _guard(() => _auth.resetPasswordForEmail(email.trim()));
  }

  @override
  Future<AuthUserModel?> getCurrentUser() {
    return _guard(() async {
      final user = _auth.currentUser;
      return user == null ? null : AuthUserModel.fromSupabaseUser(user);
    });
  }

  @override
  Stream<AuthUserModel?> authStateChanges() {
    return _auth.onAuthStateChange.map((state) {
      final user = state.session?.user;
      if (user == null) return null;
      try {
        return AuthUserModel.fromSupabaseUser(user);
      } on FormatException {
        // Una sesión sin correo no se puede usar en la app.
        return null;
      }
    });
  }

  /// Traduce los errores de Supabase y de red a las excepciones del proyecto.
  /// El código de Supabase viaja intacto: es el repositorio quien decide qué
  /// mensaje ve la usuaria.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on supabase.AuthRetryableFetchException catch (e) {
      throw NetworkException(e.message);
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message, code: e.code ?? e.statusCode);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on TimeoutException {
      throw const NetworkException('La petición tardó demasiado.');
    } on FormatException catch (e) {
      throw ServerException(e.message);
    }
  }
}
