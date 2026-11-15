import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/activities/domain/entities/activity.dart';
import 'package:doulapp/features/activities/domain/entities/activity_modality.dart';
import 'package:doulapp/features/activities/presentation/bloc/activity_detail_bloc.dart';
import 'package:doulapp/features/activities/presentation/bloc/activity_detail_event.dart';
import 'package:doulapp/features/activities/presentation/bloc/activity_detail_state.dart';
import 'package:doulapp/features/activities/presentation/pages/activity_detail_page.dart';
import 'package:doulapp/features/activities/presentation/services/link_opener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockActivityDetailBloc
    extends MockBloc<ActivityDetailEvent, ActivityDetailState>
    implements ActivityDetailBloc {}

/// Doble del abridor de enlaces: anota lo que se le pidió abrir.
class FakeLinkOpener implements LinkOpener {
  final List<String> opened = [];
  bool result = true;

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return result;
  }
}

void main() {
  late MockActivityDetailBloc bloc;
  late FakeLinkOpener linkOpener;

  const withEverything = Activity(
    id: 'act-1',
    categoryId: 'cat-1',
    title: 'Respiración 4-7-8',
    description: 'Una pausa para bajar el ritmo cuando todo se acelera.',
    modality: ActivityModality.practice,
    durationMinutes: 3,
    contentText: 'Inhala contando 4, sostén 7 y suelta en 8. Repite cuatro '
        'veces.',
    externalUrl: 'https://ejemplo.org/guia',
  );
  const bare = Activity(
    id: 'act-2',
    categoryId: 'cat-1',
    title: 'Escáner corporal',
    description: 'Recorrer el cuerpo con atención.',
    modality: ActivityModality.read,
    durationMinutes: 6,
  );

  setUpAll(
    () => registerFallbackValue(const ActivityDetailRequested('act-1')),
  );
  setUp(() {
    bloc = MockActivityDetailBloc();
    linkOpener = FakeLinkOpener();
    when(() => bloc.state).thenReturn(const ActivityDetailInitial());
  });

  void useSmallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget buildPage({String activityId = 'act-1'}) {
    final router = GoRouter(
      initialLocation: AppRoutes.activityDetailPath(activityId),
      routes: [
        GoRoute(
          path: AppRoutes.activities,
          builder: (_, _) =>
              const Scaffold(body: Text('Pantalla Microdescansos')),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => BlocProvider<ActivityDetailBloc>.value(
                value: bloc,
                child: ActivityDetailPage(
                  activityId: state.pathParameters['id']!,
                  linkOpener: linkOpener,
                ),
              ),
            ),
          ],
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('mientras carga muestra el indicador', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(const ActivityDetailLoading());

    await t.pumpWidget(buildPage());

    expect(find.byKey(const Key('activity_detail_loading')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('muestra título, descripción, duración, modalidad y pasos', (
    t,
  ) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(const ActivityDetailLoaded(withEverything));

    await t.pumpWidget(buildPage());

    expect(find.text('Respiración 4-7-8'), findsWidgets);
    expect(
      find.text('Una pausa para bajar el ritmo cuando todo se acelera.'),
      findsOneWidget,
    );
    expect(find.textContaining('3 min'), findsOneWidget);
    expect(find.text('Hacer'), findsOneWidget);
    expect(find.byKey(const Key('activity_detail_steps')), findsOneWidget);
    expect(find.textContaining('Inhala contando 4'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('sin pasos no muestra esa sección', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(const ActivityDetailLoaded(bare));

    await t.pumpWidget(buildPage(activityId: 'act-2'));

    expect(find.byKey(const Key('activity_detail_steps')), findsNothing);
    expect(find.text('Escáner corporal'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('con enlace externo lo muestra y al tocarlo lo abre', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(const ActivityDetailLoaded(withEverything));

    await t.pumpWidget(buildPage());
    await t.ensureVisible(find.byKey(const Key('activity_detail_link')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('activity_detail_link')));
    await t.pumpAndSettle();

    expect(linkOpener.opened, ['https://ejemplo.org/guia']);
  });

  testWidgets('si el enlace no se puede abrir avisa sin romper', (t) async {
    useSmallPhone(t);
    linkOpener.result = false;
    when(() => bloc.state).thenReturn(const ActivityDetailLoaded(withEverything));

    await t.pumpWidget(buildPage());
    await t.ensureVisible(find.byKey(const Key('activity_detail_link')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('activity_detail_link')));
    await t.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('sin enlace externo no muestra el enlace', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(const ActivityDetailLoaded(bare));

    await t.pumpWidget(buildPage(activityId: 'act-2'));

    expect(find.byKey(const Key('activity_detail_link')), findsNothing);
  });

  testWidgets('«Comenzar» está en el tercio inferior de la pantalla', (
    t,
  ) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(const ActivityDetailLoaded(withEverything));

    await t.pumpWidget(buildPage());

    final boton = find.byKey(const Key('activity_detail_start_button'));
    expect(boton, findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);

    // 844 de alto: el tercio inferior empieza en 562,7.
    expect(t.getCenter(boton).dy, greaterThan(844 * 2 / 3));
    expect(t.takeException(), isNull);
  });

  testWidgets('si la actividad no existe avisa y deja volver a la lista', (
    t,
  ) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      const ActivityDetailNotFound('Esa actividad ya no está disponible.'),
    );

    await t.pumpWidget(buildPage(activityId: 'act-9'));

    expect(find.text('Esa actividad ya no está disponible.'), findsOneWidget);
    // No tiene sentido reintentar algo que no existe.
    expect(find.byKey(const Key('activity_detail_retry_button')), findsNothing);

    await t.tap(find.byKey(const Key('activity_detail_back_to_list_button')));
    await t.pumpAndSettle();

    expect(find.text('Pantalla Microdescansos'), findsOneWidget);
  });

  testWidgets('un error deja reintentar con el mismo id', (t) async {
    useSmallPhone(t);
    when(
      () => bloc.state,
    ).thenReturn(const ActivityDetailFailure('No hay conexión.'));

    await t.pumpWidget(buildPage());

    expect(find.text('No hay conexión.'), findsOneWidget);

    await t.tap(find.byKey(const Key('activity_detail_retry_button')));
    await t.pump();

    verify(() => bloc.add(const ActivityDetailRequested('act-1'))).called(1);
  });

  testWidgets('un contenido largo no desborda el teléfono', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      ActivityDetailLoaded(
        Activity(
          id: 'act-3',
          categoryId: 'cat-1',
          title: 'Un título larguísimo que ocupa varias líneas en pantalla '
              'angosta sin romper nada',
          description: 'Descripción larga. ' * 30,
          modality: ActivityModality.listen,
          durationMinutes: 12,
          contentText: 'Paso con mucho texto. ' * 60,
          externalUrl: 'https://ejemplo.org/una/ruta/bastante/larga/tambien',
        ),
      ),
    );

    await t.pumpWidget(buildPage(activityId: 'act-3'));

    expect(t.takeException(), isNull);
  });
}
