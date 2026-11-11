import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/app_role.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> createProfile({
    required String userId,
    required String displayName,
  });

  Future<ProfileModel> getProfile(String userId);

  Future<ProfileModel> updateProfile(ProfileModel profile);

  Future<ProfileModel> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String mimeType,
    String? previousAvatarUrl,
  });

  Future<ProfileModel> removeAvatar({
    required String userId,
    String? previousAvatarUrl,
  });

  Future<List<AppRole>> getRoles(String userId);
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

  static const _avatarBucket = 'avatars';
  static const _avatarExtensions = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };

  @override
  Future<ProfileModel> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String mimeType,
    String? previousAvatarUrl,
  }) {
    return _guard(() async {
      // Nombre único por subida: la URL cambia y nadie ve una foto cacheada.
      final extension = _avatarExtensions[mimeType] ?? 'jpg';
      final path =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';
      final bucket = client.storage.from(_avatarBucket);

      await bucket.uploadBinary(
        path,
        bytes,
        fileOptions: supabase.FileOptions(contentType: mimeType),
      );

      final json = await client
          .from('profiles')
          .update({'avatar_url': bucket.getPublicUrl(path)})
          .eq('id', userId)
          .select()
          .single();

      await _deletePreviousAvatar(userId, previousAvatarUrl);
      return ProfileModel.fromJson(json);
    });
  }

  @override
  Future<ProfileModel> removeAvatar({
    required String userId,
    String? previousAvatarUrl,
  }) {
    return _guard(() async {
      final json = await client
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', userId)
          .select()
          .single();

      await _deletePreviousAvatar(userId, previousAvatarUrl);
      return ProfileModel.fromJson(json);
    });
  }

  /// Borra el archivo anterior. Si falla no importa: la foto nueva ya quedó
  /// guardada y un archivo huérfano no se ve en ninguna pantalla.
  Future<void> _deletePreviousAvatar(String userId, String? url) async {
    if (url == null) return;
    const marker = '/$_avatarBucket/';
    final index = url.indexOf(marker);
    if (index == -1) return;

    final path = Uri.decodeComponent(url.substring(index + marker.length));
    // Nunca se borra nada fuera de la carpeta de la usuaria.
    if (!path.startsWith('$userId/')) return;

    try {
      await client.storage.from(_avatarBucket).remove([path]);
    } catch (_) {}
  }

  @override
  Future<List<AppRole>> getRoles(String userId) {
    return _guard(() async {
      // `roles(code)` trae el código del rol enlazado por user_roles.role_id.
      final rows = await client
          .from('user_roles')
          .select('roles(code)')
          .eq('user_id', userId);

      final roles = <AppRole>[];
      for (final row in rows) {
        final code = (row['roles'] as Map<String, dynamic>?)?['code'];
        final role = code is String ? AppRole.fromCode(code) : null;
        if (role != null) roles.add(role);
      }
      return roles;
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message, code: e.code ?? e.statusCode);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    } on supabase.StorageException catch (e) {
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
