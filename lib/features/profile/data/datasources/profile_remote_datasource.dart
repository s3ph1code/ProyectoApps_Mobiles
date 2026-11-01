import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> createProfile({
    required String userId,
    required String displayName,
  });

  Future<ProfileModel> getProfile(String userId);

  Future<ProfileModel> updateProfile(ProfileModel profile);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final supabase.SupabaseClient client;

  ProfileRemoteDataSourceImpl({required this.client});

  @override
  Future<ProfileModel> createProfile({
    required String userId,
    required String displayName,
  }) {
    return _guard(() async {
      // El trigger `handle_new_user` inserta la fila al registrarse; aquí se
      // actualiza el nombre elegido en el onboarding respetando la política RLS.
      final json = await client
          .from('profiles')
          .update({'display_name': displayName.trim()})
          .eq('id', userId)
          .select()
          .single();

      return ProfileModel.fromJson(json);
    });
  }

  @override
  Future<ProfileModel> getProfile(String userId) {
    return _guard(() async {
      final json = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return ProfileModel.fromJson(json);
    });
  }

  @override
  Future<ProfileModel> updateProfile(ProfileModel profile) {
    return _guard(() async {
      final json = await client
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id)
          .select()
          .single();

      return ProfileModel.fromJson(json);
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
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
