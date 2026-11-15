import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../models/activity_category_model.dart';
import '../models/activity_model.dart';
import '../models/activity_session_model.dart';

abstract class ActivitiesRemoteDataSource {
  Future<List<ActivityCategoryModel>> fetchCategories();

  Future<List<ActivityModel>> fetchActivities({String? categoryId});

  Future<ActivitySessionModel> insertSession({
    required String userId,
    required String activityId,
  });

  Future<ActivitySessionModel> updateSessionStatus({
    required String sessionId,
    required String status,
    required int elapsedSeconds,
    DateTime? completedAt,
  });
}

class ActivitiesRemoteDataSourceImpl implements ActivitiesRemoteDataSource {
  final supabase.SupabaseClient client;

  ActivitiesRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ActivityCategoryModel>> fetchCategories() {
    return _guard(() async {
      final rows = await client
          .from('activity_categories')
          .select()
          .eq('is_active', true)
          .order('name', ascending: true);

      return rows.map(ActivityCategoryModel.fromJson).toList();
    });
  }

  /// Filtra `is_published` de forma explícita y no solo por RLS: moderadoras y
  /// administradoras sí pueden ver borradores, y en esta lista no deben salir.
  @override
  Future<List<ActivityModel>> fetchActivities({String? categoryId}) {
    return _guard(() async {
      var query = client.from('activities').select().eq('is_published', true);

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      final rows = await query.order('title', ascending: true);

      return rows.map(ActivityModel.fromJson).toList();
    });
  }

  @override
  Future<ActivitySessionModel> insertSession({
    required String userId,
    required String activityId,
  }) {
    return _guard(() async {
      final json = await client
          .from('activity_sessions')
          .insert({
            'user_id': userId,
            'activity_id': activityId,
            'status': 'in_progress',
          })
          .select()
          .single();

      return ActivitySessionModel.fromJson(json);
    });
  }

  @override
  Future<ActivitySessionModel> updateSessionStatus({
    required String sessionId,
    required String status,
    required int elapsedSeconds,
    DateTime? completedAt,
  }) {
    return _guard(() async {
      final data = <String, dynamic>{
        'status': status,
        'elapsed_seconds': elapsedSeconds,
      };
      if (completedAt != null) {
        data['completed_at'] = completedAt.toIso8601String();
      }

      final json = await client
          .from('activity_sessions')
          .update(data)
          .eq('id', sessionId)
          .select()
          .single();

      return ActivitySessionModel.fromJson(json);
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
