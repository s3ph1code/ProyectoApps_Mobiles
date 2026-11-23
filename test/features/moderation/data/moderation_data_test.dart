import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/exceptions.dart' as app;
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/moderation/data/datasources/moderation_remote_datasource.dart';
import 'package:doulapp/features/moderation/data/models/content_report_model.dart';
import 'package:doulapp/features/moderation/data/repositories/moderation_repository_impl.dart';
import 'package:doulapp/features/moderation/domain/entities/report_reason.dart';
import 'package:doulapp/features/moderation/domain/entities/report_status.dart';
import 'package:doulapp/features/moderation/domain/entities/reported_content.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../fixtures.dart';

class MockDataSource extends Mock implements ModerationRemoteDataSource {}

void main() {
  setUpAll(() => registerFallbackValue(ReportStatus.pending));

  group('ContentReportModel', () {
    test('lee un reporte de publicación con reportadora y autora', () {
      final model = ContentReportModel.fromJson(postReportRow);

      expect(model.props, postReport.props);
      expect(model.reason, ReportReason.harassment);
      expect(model.content.kind, ReportedContentKind.post);
    });

    test('lee un reporte de comentario con perfiles privados', () {
      final model = ContentReportModel.fromJson(commentReportRow);

      expect(model.content.kind, ReportedContentKind.comment);
      expect(model.reporterName, isNull);
      expect(model.content.authorName, isNull);
      expect(model.details, isNull);
    });

    test('un motivo desconocido se muestra como «otro»', () {
      final model = ContentReportModel.fromJson({
        ...postReportRow,
        'reason_code': 'algo-nuevo',
      });
      expect(model.reason, ReportReason.other);
    });

    test('un reporte sin contenido es un error de formato', () {
      expect(
        () => ContentReportModel.fromJson({...postReportRow, 'post': null}),
        throwsFormatException,
      );
    });
  });

  group('ModerationRemoteDataSourceImpl', () {
    late http.Request? lastRequest;
    late ModerationRemoteDataSourceImpl dataSource;

    void useResponse(Object body, {int status = 200}) {
      final client = supabase.SupabaseClient(
        'http://localhost:54321',
        'public-key',
        httpClient: MockClient((request) async {
          lastRequest = request;
          return http.Response(
            jsonEncode(body),
            status,
            request: request,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      dataSource = ModerationRemoteDataSourceImpl(client: client);
    }

    setUp(() => lastRequest = null);

    test(
      'getReports filtra por estado, del más antiguo al más nuevo',
      () async {
        useResponse([postReportRow, commentReportRow]);

        final reports = await dataSource.getReports(ReportStatus.pending);

        expect(lastRequest!.method, 'GET');
        expect(lastRequest!.url.path, '/rest/v1/content_reports');
        expect(lastRequest!.url.queryParameters['status'], 'eq.pending');
        expect(
          lastRequest!.url.queryParameters['order'],
          startsWith('created_at.asc'),
        );
        expect(reports.map((r) => r.id), ['rep-1', 'rep-2']);
      },
    );

    test('updateReportStatus guarda estado, revisora y fecha', () async {
      useResponse([
        {'id': 'rep-1'},
      ]);

      await dataSource.updateReportStatus(
        reportId: 'rep-1',
        status: ReportStatus.reviewing,
        reviewerId: 'mod',
      );

      expect(lastRequest!.method, 'PATCH');
      expect(lastRequest!.url.queryParameters['id'], 'eq.rep-1');
      final body = jsonDecode(lastRequest!.body) as Map<String, dynamic>;
      expect(body['status'], 'reviewing');
      expect(body['reviewed_by'], 'mod');
      expect(DateTime.tryParse(body['reviewed_at'] as String), isNotNull);
    });

    test('setContentStatus cambia la tabla según el tipo', () async {
      useResponse([
        {'id': 'post-1'},
      ]);
      await dataSource.setContentStatus(
        kind: ReportedContentKind.post,
        contentId: 'post-1',
        status: ContentStatus.hidden,
      );
      expect(lastRequest!.url.path, '/rest/v1/posts');
      expect(jsonDecode(lastRequest!.body), {'status': 'hidden'});

      useResponse([
        {'id': 'c-1'},
      ]);
      await dataSource.setContentStatus(
        kind: ReportedContentKind.comment,
        contentId: 'c-1',
        status: ContentStatus.removed,
      );
      expect(lastRequest!.url.path, '/rest/v1/comments');
      expect(jsonDecode(lastRequest!.body), {'status': 'removed'});
    });

    test('si la política no deja tocar ninguna fila, falla', () async {
      useResponse([]);

      expect(
        () => dataSource.setContentStatus(
          kind: ReportedContentKind.post,
          contentId: 'post-1',
          status: ContentStatus.hidden,
        ),
        throwsA(isA<app.ServerException>()),
      );
    });

    test('un error de la base se vuelve ServerException', () async {
      useResponse({'code': '42501', 'message': 'denied'}, status: 403);

      expect(
        () => dataSource.getReports(ReportStatus.pending),
        throwsA(isA<app.ServerException>()),
      );
    });
  });

  group('ModerationRepositoryImpl', () {
    late MockDataSource dataSource;
    late ModerationRepositoryImpl repository;

    setUp(() {
      dataSource = MockDataSource();
      repository = ModerationRepositoryImpl(remoteDataSource: dataSource);
    });

    test('getReports devuelve la lista', () async {
      when(
        () => dataSource.getReports(ReportStatus.pending),
      ).thenAnswer((_) async => [postReportModel]);

      final result = await repository.getReports(ReportStatus.pending);

      expect(result.getOrElse(() => []).single.props, postReport.props);
    });

    test('updateReportStatus y setContentStatus devuelven unit', () async {
      when(
        () => dataSource.updateReportStatus(
          reportId: 'r',
          status: ReportStatus.resolved,
          reviewerId: 'm',
        ),
      ).thenAnswer((_) async {});
      when(
        () => dataSource.setContentStatus(
          kind: ReportedContentKind.post,
          contentId: 'p',
          status: ContentStatus.hidden,
        ),
      ).thenAnswer((_) async {});

      expect(
        await repository.updateReportStatus(
          reportId: 'r',
          status: ReportStatus.resolved,
          reviewerId: 'm',
        ),
        const Right<Failure, Unit>(unit),
      );
      expect(
        await repository.setContentStatus(
          kind: ReportedContentKind.post,
          contentId: 'p',
          status: ContentStatus.hidden,
        ),
        const Right<Failure, Unit>(unit),
      );
    });

    group('mapea las excepciones a fallos', () {
      Future<Either<Failure, List<dynamic>>> failingWith(Object error) {
        when(() => dataSource.getReports(any())).thenThrow(error);
        return repository.getReports(ReportStatus.pending);
      }

      test('red', () async {
        expect(
          await failingWith(const app.NetworkException('x')),
          const Left<Failure, dynamic>(NetworkFailure()),
        );
      });
      test('servidor', () async {
        expect(
          await failingWith(const app.ServerException('x')),
          const Left<Failure, dynamic>(ServerFailure()),
        );
      });
      test('sesión', () async {
        expect(
          await failingWith(const app.UnauthenticatedException()),
          const Left<Failure, dynamic>(UnauthenticatedFailure()),
        );
      });
      test('inesperado', () async {
        expect(
          await failingWith(StateError('x')),
          const Left<Failure, dynamic>(UnexpectedFailure()),
        );
      });
    });
  });
}
