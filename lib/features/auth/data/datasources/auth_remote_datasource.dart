import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../models/auth_user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUserModel> signUp({
    required String email,
    required String password,
  });

  Future<AuthUserModel> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<AuthUserModel?> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final supabase.SupabaseClient client;

  AuthRemoteDataSourceImpl({required this.client});

  supabase.GoTrueClient get _auth => client.auth;

  @override
  Future<AuthUserModel> signUp({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      // El trigger `handle_new_user` crea el perfil con un nombre provisional
      // tomado del correo. El onboarding lo reemplaza más adelante.
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
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
  Future<AuthUserModel?> getCurrentUser() {
    return _guard(() async {
      final user = _auth.currentUser;
      return user == null ? null : AuthUserModel.fromSupabaseUser(user);
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
