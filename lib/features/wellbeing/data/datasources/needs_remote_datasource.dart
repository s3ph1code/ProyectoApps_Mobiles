import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../models/need_option_model.dart';
import '../models/recommendation_model.dart';

abstract class NeedsRemoteDataSource {
  Future<List<NeedOptionModel>> fetchNeedOptions();

  Future<List<RecommendationModel>> fetchRecommendations({
    required List<String> optionIds,
  });

  /// Crea la sesión, le cuelga las opciones elegidas y devuelve su id.
  Future<String> insertNeedSession({
    required String userId,
    required List<String> optionIds,
  });
}

class NeedsRemoteDataSourceImpl implements NeedsRemoteDataSource {
  final supabase.SupabaseClient client;

  NeedsRemoteDataSourceImpl({required this.client});

  @override
  Future<List<NeedOptionModel>> fetchNeedOptions() {
    return _guard(() async {
      final rows = await client
          .from('need_options')
          .select()
          .eq('is_active', true)
          .order('label', ascending: true);

      return rows.map(NeedOptionModel.fromJson).toList();
    });
  }

  @override
  Future<List<RecommendationModel>> fetchRecommendations({
    required List<String> optionIds,
  }) {
    return _guard(() async {
      final rows = await client
          .from('need_recommendations')
          .select()
          .inFilter('need_option_id', optionIds)
          .order('priority', ascending: true);

      return rows.map(RecommendationModel.fromJson).toList();
    });
  }

  @override
  Future<String> insertNeedSession({
    required String userId,
    required List<String> optionIds,
  }) {
    return _guard(() async {
      final session = await client
          .from('need_sessions')
          .insert({'user_id': userId})
          .select()
          .single();

      final sessionId = session['id'] as String;

      await client.from('need_session_options').insert([
        for (final optionId in optionIds)
          {'need_session_id': sessionId, 'need_option_id': optionId},
      ]);

      return sessionId;
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message, code: e.code ?? e.statusCode);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado.');
    } on FormatException catch (e) {
      throw ServerException(e.message);
    }
  }
}
