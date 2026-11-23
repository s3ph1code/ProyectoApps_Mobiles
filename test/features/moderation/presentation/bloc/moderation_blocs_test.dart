import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/moderation/domain/entities/report_status.dart';
import 'package:doulapp/features/moderation/domain/entities/reported_content.dart';
import 'package:doulapp/features/moderation/domain/usecases/get_reports.dart';
import 'package:doulapp/features/moderation/domain/usecases/moderate_content.dart';
import 'package:doulapp/features/moderation/domain/usecases/update_report_status.dart';
import 'package:doulapp/features/moderation/presentation/bloc/moderation_bloc.dart';
import 'package:doulapp/features/moderation/presentation/bloc/moderation_event.dart';
import 'package:doulapp/features/moderation/presentation/bloc/moderation_state.dart';
import 'package:doulapp/features/moderation/presentation/bloc/report_detail_bloc.dart';
import 'package:doulapp/features/moderation/presentation/bloc/report_detail_event.dart';
import 'package:doulapp/features/moderation/presentation/bloc/report_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures.dart';

class MockGetReports extends Mock implements GetReports {}

class MockUpdateReportStatus extends Mock implements UpdateReportStatus {}

class MockModerateContent extends Mock implements ModerateContent {}

void main() {
  setUpAll(() {
    registerFallbackValue(const GetReportsParams());
    registerFallbackValue(
      const UpdateReportStatusParams(
        reportId: 'x',
        status: ReportStatus.resolved,
      ),
    );
    registerFallbackValue(
      const ModerateContentParams(
        reportId: 'x',
        kind: ReportedContentKind.post,
        contentId: 'y',
        action: ModerationAction.hide,
      ),
    );
  });

  group('ModerationBloc', () {
    late MockGetReports getReports;

    setUp(() => getReports = MockGetReports());

    blocTest<ModerationBloc, ModerationState>(
      'abre con los reportes pendientes',
      build: () {
        when(
          () => getReports(const GetReportsParams()),
        ).thenAnswer((_) async => Right([postReport, commentReport]));
        return ModerationBloc(getReports: getReports);
      },
      act: (bloc) => bloc.add(const ModerationStarted()),
      expect: () => [
        const ModerationLoading(ReportStatus.pending),
        ModerationLoaded(
          filter: ReportStatus.pending,
          reports: [postReport, commentReport],
        ),
      ],
    );

    blocTest<ModerationBloc, ModerationState>(
      'cambiar el filtro pide ese estado',
      build: () {
        when(
          () =>
              getReports(const GetReportsParams(status: ReportStatus.resolved)),
        ).thenAnswer((_) async => const Right([]));
        return ModerationBloc(getReports: getReports);
      },
      act: (bloc) =>
          bloc.add(const ModerationFilterChanged(ReportStatus.resolved)),
      expect: () => [
        const ModerationLoading(ReportStatus.resolved),
        const ModerationLoaded(filter: ReportStatus.resolved, reports: []),
      ],
    );

    blocTest<ModerationBloc, ModerationState>(
      'refrescar conserva el filtro elegido',
      build: () {
        when(() => getReports(any())).thenAnswer((_) async => const Right([]));
        return ModerationBloc(getReports: getReports);
      },
      act: (bloc) async {
        bloc.add(const ModerationFilterChanged(ReportStatus.reviewing));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ModerationRefreshed());
      },
      verify: (_) {
        verify(
          () => getReports(
            const GetReportsParams(status: ReportStatus.reviewing),
          ),
        ).called(2);
      },
    );

    blocTest<ModerationBloc, ModerationState>(
      'sin rol de moderación queda como prohibido',
      build: () {
        when(
          () => getReports(any()),
        ).thenAnswer((_) async => const Left(ForbiddenFailure()));
        return ModerationBloc(getReports: getReports);
      },
      act: (bloc) => bloc.add(const ModerationStarted()),
      expect: () => [
        const ModerationLoading(ReportStatus.pending),
        const ModerationForbidden(),
      ],
    );

    blocTest<ModerationBloc, ModerationState>(
      'un error de red se explica',
      build: () {
        when(
          () => getReports(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return ModerationBloc(getReports: getReports);
      },
      act: (bloc) => bloc.add(const ModerationStarted()),
      expect: () => [
        const ModerationLoading(ReportStatus.pending),
        ModerationFailure(
          filter: ReportStatus.pending,
          message: const NetworkFailure().message,
        ),
      ],
    );
  });

  group('ReportDetailBloc', () {
    late MockUpdateReportStatus updateStatus;
    late MockModerateContent moderate;

    setUp(() {
      updateStatus = MockUpdateReportStatus();
      moderate = MockModerateContent();
    });

    ReportDetailBloc build() => ReportDetailBloc(
      report: postReport,
      updateReportStatus: updateStatus,
      moderateContent: moderate,
    );

    blocTest<ReportDetailBloc, ReportDetailState>(
      'cambia el estado del reporte y lo avisa',
      build: () {
        when(
          () => updateStatus(any()),
        ).thenAnswer((_) async => const Right(unit));
        return build();
      },
      act: (bloc) =>
          bloc.add(const ReportStatusChanged(ReportStatus.reviewing)),
      verify: (bloc) {
        expect(bloc.state.report.status, ReportStatus.reviewing);
        expect(bloc.state.report.reviewedAt, isNotNull);
        expect(bloc.state.notice, contains('en revisión'));
        expect(bloc.state.noticeIsError, isFalse);
        expect(bloc.state.isWorking, isFalse);
      },
    );

    blocTest<ReportDetailBloc, ReportDetailState>(
      'si falla, el reporte no cambia y se explica',
      build: () {
        when(
          () => updateStatus(any()),
        ).thenAnswer((_) async => const Left(ServerFailure()));
        return build();
      },
      act: (bloc) =>
          bloc.add(const ReportStatusChanged(ReportStatus.dismissed)),
      verify: (bloc) {
        expect(bloc.state.report.status, ReportStatus.pending);
        expect(bloc.state.noticeIsError, isTrue);
        expect(bloc.state.notice, const ServerFailure().message);
      },
    );

    blocTest<ReportDetailBloc, ReportDetailState>(
      'elegir el estado que ya tiene no hace nada',
      build: build,
      act: (bloc) => bloc.add(const ReportStatusChanged(ReportStatus.pending)),
      expect: () => const <ReportDetailState>[],
      verify: (_) => verifyZeroInteractions(updateStatus),
    );

    blocTest<ReportDetailBloc, ReportDetailState>(
      'ocultar deja el contenido oculto y el reporte resuelto',
      build: () {
        when(() => moderate(any())).thenAnswer((_) async => const Right(unit));
        return build();
      },
      act: (bloc) =>
          bloc.add(const ContentModerationRequested(ModerationAction.hide)),
      verify: (bloc) {
        expect(bloc.state.report.status, ReportStatus.resolved);
        expect(bloc.state.report.content.status, ContentStatus.hidden);
        expect(bloc.state.notice, 'Publicación oculta. Reporte resuelto.');
      },
    );

    blocTest<ReportDetailBloc, ReportDetailState>(
      'eliminar deja el contenido eliminado',
      build: () {
        when(() => moderate(any())).thenAnswer((_) async => const Right(unit));
        return build();
      },
      act: (bloc) =>
          bloc.add(const ContentModerationRequested(ModerationAction.remove)),
      verify: (bloc) {
        expect(bloc.state.report.content.status, ContentStatus.removed);
        expect(bloc.state.notice, 'Publicación eliminada. Reporte resuelto.');
      },
    );

    blocTest<ReportDetailBloc, ReportDetailState>(
      'si moderar falla, nada cambia',
      build: () {
        when(
          () => moderate(any()),
        ).thenAnswer((_) async => const Left(ForbiddenFailure()));
        return build();
      },
      act: (bloc) =>
          bloc.add(const ContentModerationRequested(ModerationAction.hide)),
      verify: (bloc) {
        expect(bloc.state.report.content.status, ContentStatus.published);
        expect(bloc.state.report.status, ReportStatus.pending);
        expect(bloc.state.noticeIsError, isTrue);
      },
    );
  });
}
