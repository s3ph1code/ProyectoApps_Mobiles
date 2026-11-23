import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/core/theme/app_theme.dart';
import 'package:doulapp/features/moderation/domain/entities/content_report.dart';
import 'package:doulapp/features/moderation/domain/entities/report_status.dart';
import 'package:doulapp/features/moderation/domain/entities/reported_content.dart';
import 'package:doulapp/features/moderation/domain/usecases/get_reports.dart';
import 'package:doulapp/features/moderation/domain/usecases/moderate_content.dart';
import 'package:doulapp/features/moderation/domain/usecases/update_report_status.dart';
import 'package:doulapp/features/moderation/presentation/bloc/moderation_bloc.dart';
import 'package:doulapp/features/moderation/presentation/bloc/moderation_event.dart';
import 'package:doulapp/features/moderation/presentation/bloc/moderation_state.dart';
import 'package:doulapp/features/moderation/presentation/bloc/report_detail_bloc.dart';
import 'package:doulapp/features/moderation/presentation/pages/moderation_page.dart';
import 'package:doulapp/features/moderation/presentation/pages/report_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures.dart';

class MockModerationBloc extends MockBloc<ModerationEvent, ModerationState>
    implements ModerationBloc {}

class MockUpdateReportStatus extends Mock implements UpdateReportStatus {}

class MockModerateContent extends Mock implements ModerateContent {}

class MockGetReports extends Mock implements GetReports {}

void main() {
  setUpAll(() {
    registerFallbackValue(const ModerationStarted());
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

  void phone(WidgetTester t) {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  group('ModerationPage', () {
    late MockModerationBloc bloc;

    setUp(() => bloc = MockModerationBloc());

    Future<void> show(WidgetTester t, ModerationState state) async {
      phone(t);
      when(() => bloc.state).thenReturn(state);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => BlocProvider<ModerationBloc>.value(
              value: bloc,
              child: const ModerationPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.reportDetail,
            builder: (_, state) => Scaffold(
              body: Text('detalle ${(state.extra! as ContentReport).id}'),
            ),
          ),
        ],
      );
      await t.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await t.pump();
    }

    testWidgets('lista los reportes con motivo, extracto y autora', (t) async {
      await show(
        t,
        ModerationLoaded(
          filter: ReportStatus.pending,
          reports: [postReport, commentReport],
        ),
      );

      expect(find.text('Acoso'), findsOneWidget);
      expect(find.text('Spam'), findsOneWidget);
      expect(find.text('Texto de la publicación reportada'), findsOneWidget);
      expect(find.textContaining('Autora: Ana'), findsOneWidget);
      expect(find.textContaining('Autora: Una mamá'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('los chips de filtro piden otro estado', (t) async {
      await show(
        t,
        const ModerationLoaded(filter: ReportStatus.pending, reports: []),
      );

      await t.ensureVisible(find.byKey(const Key('filter_resolved')));
      await t.tap(find.byKey(const Key('filter_resolved')));

      verify(
        () => bloc.add(const ModerationFilterChanged(ReportStatus.resolved)),
      ).called(1);
    });

    testWidgets('sin reportes dice que no hay pendientes', (t) async {
      await show(
        t,
        const ModerationLoaded(filter: ReportStatus.pending, reports: []),
      );
      expect(find.text('No hay reportes pendientes'), findsOneWidget);
    });

    testWidgets('muestra la carga', (t) async {
      await show(t, const ModerationLoading(ReportStatus.pending));
      expect(find.byKey(const Key('moderation_loading')), findsOneWidget);
    });

    testWidgets('si falla permite reintentar', (t) async {
      await show(
        t,
        const ModerationFailure(
          filter: ReportStatus.pending,
          message: 'No hay conexión.',
        ),
      );

      expect(find.text('No hay conexión.'), findsOneWidget);
      await t.tap(find.byKey(const Key('moderation_retry')));
      verify(() => bloc.add(const ModerationRefreshed())).called(1);
    });

    testWidgets('sin permiso explica y no ofrece filtros', (t) async {
      await show(t, const ModerationForbidden());

      expect(find.text('Esta sección es para moderación'), findsOneWidget);
      expect(find.byKey(const Key('filter_pending')), findsNothing);
    });

    testWidgets('abrir un reporte va al detalle y al volver refresca', (
      t,
    ) async {
      await show(
        t,
        ModerationLoaded(filter: ReportStatus.pending, reports: [postReport]),
      );

      await t.tap(find.byKey(const Key('report_rep-1')));
      await t.pumpAndSettle();
      expect(find.text('detalle rep-1'), findsOneWidget);

      t.element(find.text('detalle rep-1')).pop();
      await t.pumpAndSettle();

      verify(() => bloc.add(const ModerationRefreshed())).called(1);
    });
  });

  group('ReportDetailPage', () {
    late MockUpdateReportStatus updateStatus;
    late MockModerateContent moderate;
    late ReportDetailBloc bloc;

    setUp(() {
      updateStatus = MockUpdateReportStatus();
      moderate = MockModerateContent();
      when(
        () => updateStatus(any()),
      ).thenAnswer((_) async => const Right(unit));
      when(() => moderate(any())).thenAnswer((_) async => const Right(unit));
    });

    tearDown(() => bloc.close());

    Future<void> show(WidgetTester t, {ContentReport? report}) async {
      phone(t);
      bloc = ReportDetailBloc(
        report: report ?? postReport,
        updateReportStatus: updateStatus,
        moderateContent: moderate,
      );
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider.value(
            value: bloc,
            child: const ReportDetailPage(),
          ),
        ),
      );
      await t.pump();
    }

    testWidgets('muestra motivo, detalles, contenido y autora', (t) async {
      await show(t);

      expect(find.text('Acoso'), findsOneWidget);
      expect(find.text('Insulta a otra usuaria'), findsOneWidget);
      expect(find.text('Texto de la publicación reportada'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.textContaining('Lucía'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('sin detalles ni nombres lo dice con amabilidad', (t) async {
      await show(t, report: commentReport);

      expect(find.text('No dejó más detalles.'), findsOneWidget);
      expect(find.textContaining('Una mamá de la comunidad'), findsWidgets);
    });

    testWidgets('«En revisión» actualiza la etiqueta y esconde ese botón', (
      t,
    ) async {
      await show(t);

      await t.tap(find.byKey(const Key('status_reviewing')));
      await t.pumpAndSettle();

      expect(find.text('En revisión'), findsOneWidget);
      expect(find.byKey(const Key('status_reviewing')), findsNothing);
      expect(find.textContaining('en revisión'), findsOneWidget);
    });

    testWidgets('ocultar pide confirmación y luego actúa', (t) async {
      await show(t);

      await t.ensureVisible(find.byKey(const Key('content_hide')));
      await t.tap(find.byKey(const Key('content_hide')));
      await t.pumpAndSettle();
      expect(find.text('¿Ocultar la publicación?'), findsOneWidget);

      await t.tap(find.byKey(const Key('confirm_ok')));
      await t.pumpAndSettle();

      verify(() => moderate(any())).called(1);
      expect(find.text('Resuelto'), findsOneWidget);
      expect(
        find.byKey(const Key('content_already_moderated')),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    });

    testWidgets('cancelar la confirmación no cambia nada', (t) async {
      await show(t);

      await t.ensureVisible(find.byKey(const Key('content_remove')));
      await t.tap(find.byKey(const Key('content_remove')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('confirm_cancel')));
      await t.pumpAndSettle();

      verifyNever(() => moderate(any()));
      expect(find.text('Pendiente'), findsOneWidget);
    });

    testWidgets('si falla el cambio avisa y el estado no cambia', (t) async {
      when(
        () => updateStatus(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      await show(t);

      await t.tap(find.byKey(const Key('status_dismissed')));
      await t.pumpAndSettle();

      expect(find.text(const NetworkFailure().message), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
    });

    testWidgets('el contenido ya oculto no ofrece ocultar otra vez', (t) async {
      await show(
        t,
        report: postReport.copyWith(
          content: postReport.content.copyWith(status: ContentStatus.hidden),
        ),
      );

      expect(find.byKey(const Key('content_hide')), findsNothing);
      expect(
        find.byKey(const Key('content_already_moderated')),
        findsOneWidget,
      );
    });
  });
}
