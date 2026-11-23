import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/report_status.dart';
import '../../domain/entities/reported_content.dart';
import '../models/content_report_model.dart';

abstract class ModerationRemoteDataSource {
  Future<List<ContentReportModel>> getReports(ReportStatus status);

  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    required String reviewerId,
  });

  Future<void> setContentStatus({
    required ReportedContentKind kind,
    required String contentId,
    required ContentStatus status,
  });
}

class ModerationRemoteDataSourceImpl implements ModerationRemoteDataSource {
  final supabase.SupabaseClient client;

  ModerationRemoteDataSourceImpl({required this.client});

  static const _reportColumns =
      'id, reason_code, details, status, created_at, reviewed_at, '
      'reporter:profiles!content_reports_reporter_id_fkey(display_name), '
      'post:posts!content_reports_post_id_fkey('
      'id, body, status, author_id, '
      'author:profiles!posts_author_id_fkey(display_name)), '
      'comment:comments!content_reports_comment_id_fkey('
      'id, body, status, author_id, '
      'author:profiles!comments_author_id_fkey(display_name))';

  @override
  Future<List<ContentReportModel>> getReports(ReportStatus status) {
    return _guard(() async {
      final rows = await client
          .from('content_reports')
          .select(_reportColumns)
          .eq('status', status.code)
          .order('created_at', ascending: true);

      return rows.map(ContentReportModel.fromJson).toList();
    });
  }

  @override
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    required String reviewerId,
  }) {
    return _guard(() async {
      final updated = await client
          .from('content_reports')
          .update({
            'status': status.code,
            'reviewed_by': reviewerId,
            'reviewed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', reportId)
          .select('id');
      _requireChange(updated);
    });
  }

  @override
  Future<void> setContentStatus({
    required ReportedContentKind kind,
    required String contentId,
    required ContentStatus status,
  }) {
    final table = switch (kind) {
      ReportedContentKind.post => 'posts',
      ReportedContentKind.comment => 'comments',
    };
    return _guard(() async {
      final updated = await client
          .from(table)
          .update({'status': status.code})
          .eq('id', contentId)
          .select('id');
      _requireChange(updated);
    });
  }

  /// La RLS no falla cuando no hay permiso: simplemente no toca ninguna fila.
  void _requireChange(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      throw const ServerException('No se pudo aplicar el cambio.');
    }
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
