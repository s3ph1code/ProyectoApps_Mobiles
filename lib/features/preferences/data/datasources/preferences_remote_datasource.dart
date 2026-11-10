import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../models/user_preferences_model.dart';

abstract class PreferencesRemoteDataSource {
  Future<UserPreferencesModel> getPreferences(String userId);

  Future<UserPreferencesModel> updatePreferences(
    String userId,
    UserPreferencesModel preferences,
  );
}

class PreferencesRemoteDataSourceImpl implements PreferencesRemoteDataSource {
  final supabase.SupabaseClient client;

  PreferencesRemoteDataSourceImpl({required this.client});

  @override
  Future<UserPreferencesModel> getPreferences(String userId) {
    return _guard(() async {
      final json = await client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .single();

      return UserPreferencesModel.fromJson(json);
    });
  }

  @override
  Future<UserPreferencesModel> updatePreferences(
    String userId,
    UserPreferencesModel preferences,
  ) {
    return _guard(() async {
      final json = await client
          .from('user_preferences')
          .update(preferences.toJson())
          .eq('user_id', userId)
          .select()
          .single();

      return UserPreferencesModel.fromJson(json);
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
