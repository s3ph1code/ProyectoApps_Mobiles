import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../../../profile/domain/entities/app_role.dart';
import '../models/managed_user_model.dart';

abstract class RoleAdminRemoteDataSource {
  Future<List<ManagedUserModel>> getTeam();

  Future<List<ManagedUserModel>> searchUsers(String query);

  Future<void> assignRole({required String userId, required AppRole role});

  Future<void> removeRole({required String userId, required AppRole role});
}

class RoleAdminRemoteDataSourceImpl implements RoleAdminRemoteDataSource {
  final supabase.SupabaseClient client;

  RoleAdminRemoteDataSourceImpl({required this.client});

  static const searchLimit = 20;

  /// Roles que forman «el equipo».
  static const _teamCodes = ['moderator', 'admin'];

  @override
  Future<List<ManagedUserModel>> getTeam() {
    return _guard(() async {
      final rows = await client
          .from('user_roles')
          .select(
            'user_id, roles!inner(code), '
            'profile:profiles!user_roles_user_id_fkey(display_name)',
          )
          .inFilter('roles.code', _teamCodes)
          .order('assigned_at', ascending: true);

      return ManagedUserModel.groupTeamRows(rows);
    });
  }

  @override
  Future<List<ManagedUserModel>> searchUsers(String query) {
    return _guard(() async {
      final rows = await client
          .from('profiles')
          .select('id, display_name, user_roles(roles(code))')
          .ilike('display_name', '%${_escapeLike(query)}%')
          .order('display_name', ascending: true)
          .limit(searchLimit);

      return rows.map(ManagedUserModel.fromProfileJson).toList();
    });
  }

  @override
  Future<void> assignRole({required String userId, required AppRole role}) {
    return _guard(() async {
      final roleId = await _roleId(role);
      // `ignoreDuplicates`: asignar un rol que ya tiene no es un error.
      await client
          .from('user_roles')
          .upsert(
            {'user_id': userId, 'role_id': roleId},
            onConflict: 'user_id,role_id',
            ignoreDuplicates: true,
          );
    });
  }

  @override
  Future<void> removeRole({required String userId, required AppRole role}) {
    return _guard(() async {
      final roleId = await _roleId(role);
      await client
          .from('user_roles')
          .delete()
          .eq('user_id', userId)
          .eq('role_id', roleId);
    });
  }

  Future<int> _roleId(AppRole role) async {
    final row = await client
        .from('roles')
        .select('id')
        .eq('code', role.code)
        .single();
    return row['id'] as int;
  }

  /// `%`, `_` y `\` son comodines de LIKE: se buscan como texto literal.
  String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

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
