import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../models/mood_checkin_model.dart';

abstract class MoodRemoteDataSource {
  Future<MoodCheckinModel> insertCheckin({
    required String userId,
    required int moodScore,
    String? note,
  });

  /// Los check-ins de [userId], del más reciente al más antiguo, como
  /// máximo [limit].
  Future<List<MoodCheckinModel>> fetchCheckins({
    required String userId,
    required int limit,
  });
}

class MoodRemoteDataSourceImpl implements MoodRemoteDataSource {
  final supabase.SupabaseClient client;

  MoodRemoteDataSourceImpl({required this.client});

  @override
  Future<MoodCheckinModel> insertCheckin({
    required String userId,
    required int moodScore,
    String? note,
  }) {
    return _guard(() async {
      final json = await client
          .from('mood_checkins')
          .insert({'user_id': userId, 'mood_score': moodScore, 'note': note})
          .select()
          .single();

      return MoodCheckinModel.fromJson(json);
    });
  }

  @override
  Future<List<MoodCheckinModel>> fetchCheckins({
    required String userId,
    required int limit,
  }) {
    return _guard(() async {
      final rows = await client
          .from('mood_checkins')
          .select()
          .eq('user_id', userId)
          .order('recorded_at', ascending: false)
          .limit(limit);

      return rows.map(MoodCheckinModel.fromJson).toList();
    });
  }

  /// Traduce los errores de Supabase y de red a las excepciones de la app,
  /// que el repositorio convierte en `Failure`.
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
