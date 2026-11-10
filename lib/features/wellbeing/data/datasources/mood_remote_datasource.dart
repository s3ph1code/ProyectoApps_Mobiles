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
}

class MoodRemoteDataSourceImpl implements MoodRemoteDataSource {
  final supabase.SupabaseClient client;

  MoodRemoteDataSourceImpl({required this.client});

  @override
  Future<MoodCheckinModel> insertCheckin({
    required String userId,
    required int moodScore,
    String? note,
  }) async {
    try {
      final json = await client
          .from('mood_checkins')
          .insert({'user_id': userId, 'mood_score': moodScore, 'note': note})
          .select()
          .single();

      return MoodCheckinModel.fromJson(json);
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
