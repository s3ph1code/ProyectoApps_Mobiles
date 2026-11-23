import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../models/blocked_user_model.dart';

abstract class BlockRemoteDataSource {
  Future<List<BlockedUserModel>> getBlockedUsers(String userId);

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  });

  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  });
}

class BlockRemoteDataSourceImpl implements BlockRemoteDataSource {
  final supabase.SupabaseClient client;

  BlockRemoteDataSourceImpl({required this.client});

  @override
  Future<List<BlockedUserModel>> getBlockedUsers(String userId) {
    return _guard(() async {
      final rows = await client
          .from('user_blocks')
          .select(
            'blocked_id, created_at, '
            'blocked:profiles!user_blocks_blocked_id_fkey(display_name)',
          )
          .eq('blocker_id', userId)
          .order('created_at', ascending: false);

      return rows.map(BlockedUserModel.fromJson).toList();
    });
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) {
    // `ignoreDuplicates`: bloquear a quien ya está bloqueada no es un error.
    return _guard(
      () => client
          .from('user_blocks')
          .upsert(
            {'blocker_id': blockerId, 'blocked_id': blockedId},
            onConflict: 'blocker_id,blocked_id',
            ignoreDuplicates: true,
          ),
    );
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) {
    return _guard(
      () => client
          .from('user_blocks')
          .delete()
          .eq('blocker_id', blockerId)
          .eq('blocked_id', blockedId),
    );
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
