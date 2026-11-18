import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/features/activities/domain/entities/activity.dart';
import 'package:doulapp/features/activities/domain/entities/activity_category.dart';
import 'package:doulapp/features/activities/domain/entities/activity_modality.dart';
import 'package:doulapp/features/activities/presentation/bloc/activities_bloc.dart';
import 'package:doulapp/features/activities/presentation/bloc/activities_event.dart';
import 'package:doulapp/features/activities/presentation/bloc/activities_state.dart';
import 'package:doulapp/features/activities/presentation/pages/activities_page.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockActivitiesBloc extends MockBloc<ActivitiesEvent, ActivitiesState>
    implements ActivitiesBloc {}

void main() {
  late MockActivitiesBloc bloc;

  const categories = [
    ActivityCategory(id: 'cat-1', name: 'Respiración', slug: 'respiracion'),
    ActivityCategory(id: 'cat-2', name: 'Descanso', slug: 'descanso'),
  ];
  const breathing = Activity(
    id: 'act-1',
    categoryId: 'cat-1',
    title: 'Respiración 4-7-8',
    description: 'Una pausa para bajar el ritmo.',
    modality: ActivityModality.practice,
    durationMinutes: 3,
  );
  const reading = Activity(
    id: 'act-2',
    categoryId: 'cat-2',
    title: 'Escáner corporal',
    description: 'Recorrer el cuerpo con atención.',
    modality: ActivityModality.read,
    durationMinutes: 6,
  );

  setUpAll(() => registerFallbackValue(const ActivitiesRequested()));
  setUp(() {
    bloc = MockActivitiesBloc();
    when(() => bloc.state).thenReturn(const ActivitiesInitial());
  });

  void useSmallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget buildPage() {
    final router = GoRouter(
      initialLocation: AppRoutes.activities,
      routes: [
        GoRoute(
          path: AppRoutes.activities,
          builder: (_, _) => BlocProvider<ActivitiesBloc>.value(
            value: bloc,
            child: const ActivitiesPage(),
          ),
          routes: [
            GoRoute(
              path: 'saved',
              builder: (_, _) => const Scaffold(
                body: Text('Pantalla Actividades Guardadas'),
              ),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) => Scaffold(
                appBar: AppBar(title: const Text('Microdescanso')),
                body: Text(
                  'Pantalla Detalle ${state.pathParameters['id']}',
                ),
              ),
            ),
          ],
        ),
      ],
    );
    // Con el tema real, que es el que define el tamaño mínimo de los botones.
    return MaterialApp.router(theme: AppTheme.light, routerConfig: router);
  }

  testWidgets('mientras carga muestra el indicador', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(const ActivitiesLoading());

    await t.pumpWidget(buildPage());

    expect(find.byKey(const Key('activities_loading')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('muestra «Todas» y un chip por categoría', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      const ActivitiesLoaded(
        categories: categories,
        activities: [breathing, reading],
      ),
    );

    await t.pumpWidget(buildPage());

    expect(find.byKey(const Key('activities_chip_all')), findsOneWidget);
    expect(find.text('Todas'), findsOneWidget);
    expect(find.byKey(const Key('activities_chip_cat-1')), findsOneWidget);
    expect(find.byKey(const Key('activities_chip_cat-2')), findsOneWidget);
    expect(find.text('Respiración'), findsOneWidget);
    expect(find.text('Descanso'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('cada tarjeta muestra título, duración y modalidad', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      const ActivitiesLoaded(
        categories: categories,
        activities: [breathing, reading],
      ),
    );

    await t.pumpWidget(buildPage());

    expect(find.byKey(const Key('activities_item_act-1')), findsOneWidget);
    expect(find.text('Respiración 4-7-8'), findsOneWidget);
    expect(find.textContaining('3 min'), findsOneWidget);
    expect(find.text('Hacer'), findsOneWidget);

    expect(find.text('Escáner corporal'), findsOneWidget);
    expect(find.textContaining('6 min'), findsOneWidget);
    expect(find.text('Leer'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('tocar una categoría la pide al BLoC', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      const ActivitiesLoaded(categories: categories, activities: [breathing]),
    );

    await t.pumpWidget(buildPage());
    // La fila de chips se desplaza; con la fuente de pruebas «Descanso»
    // arranca fuera de la pantalla.
    await t.ensureVisible(find.byKey(const Key('activities_chip_cat-2')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('activities_chip_cat-2')));

    verify(() => bloc.add(const ActivityCategorySelected('cat-2'))).called(1);
  });

  testWidgets('«Todas» quita el filtro', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      const ActivitiesLoaded(
        categories: categories,
        activities: [breathing],
        selectedCategoryId: 'cat-1',
      ),
    );

    await t.pumpWidget(buildPage());
    await t.tap(find.byKey(const Key('activities_chip_all')));

    verify(() => bloc.add(const ActivityCategorySelected(null))).called(1);
  });

  testWidgets('una categoría sin actividades lo dice con claridad', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      const ActivitiesLoaded(
        categories: categories,
        activities: [],
        selectedCategoryId: 'cat-1',
      ),
    );

    await t.pumpWidget(buildPage());

    expect(find.byKey(const Key('activities_empty')), findsOneWidget);
    expect(
      t.widget<Text>(find.byKey(const Key('activities_empty_message'))).data,
      isNotEmpty,
    );
    // Los chips siguen ahí para poder cambiar de categoría.
    expect(find.byKey(const Key('activities_chip_all')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('un error muestra el mensaje y permite reintentar', (t) async {
    useSmallPhone(t);
    when(
      () => bloc.state,
    ).thenReturn(const ActivitiesFailure('No hay conexión.'));

    await t.pumpWidget(buildPage());

    expect(find.text('No hay conexión.'), findsOneWidget);

    await t.tap(find.byKey(const Key('activities_retry_button')));
    await t.pump();

    verify(() => bloc.add(const ActivitiesRequested())).called(1);
  });

  testWidgets('tocar una tarjeta abre el detalle de esa actividad', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      const ActivitiesLoaded(
        categories: categories,
        activities: [breathing, reading],
      ),
    );

    await t.pumpWidget(buildPage());
    await t.tap(find.byKey(const Key('activities_item_act-2')));
    await t.pumpAndSettle();

    expect(find.text('Pantalla Detalle act-2'), findsOneWidget);
  });

  testWidgets('desde el detalle puedo volver a la lista', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      const ActivitiesLoaded(categories: categories, activities: [breathing]),
    );

    await t.pumpWidget(buildPage());
    await t.tap(find.byKey(const Key('activities_item_act-1')));
    await t.pumpAndSettle();
    expect(find.text('Pantalla Detalle act-1'), findsOneWidget);

    await t.pageBack();
    await t.pumpAndSettle();

    expect(find.byKey(const Key('activities_item_act-1')), findsOneWidget);
  });

  testWidgets('títulos largos y muchas categorías no desbordan', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      ActivitiesLoaded(
        categories: List.generate(
          8,
          (i) => ActivityCategory(
            id: 'cat-$i',
            name: 'Categoría larguísima número $i',
            slug: 'cat-$i',
          ),
        ),
        activities: [
          Activity(
            id: 'act-9',
            categoryId: 'cat-1',
            title: 'Un título larguísimo que no debería romper la tarjeta '
                'ni empujar la duración fuera de la pantalla',
            description: 'Descripción igualmente larga para la prueba. ' * 6,
            modality: ActivityModality.listen,
            durationMinutes: 12,
          ),
        ],
      ),
    );

    await t.pumpWidget(buildPage());

    expect(t.takeException(), isNull);
  });

  testWidgets('el botón de guardadas en el AppBar abre las actividades guardadas', (
    t,
  ) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      const ActivitiesLoaded(categories: categories, activities: [breathing]),
    );

    await t.pumpWidget(buildPage());
    await t.tap(find.byKey(const Key('activities_saved_button')));
    await t.pumpAndSettle();

    expect(find.text('Pantalla Actividades Guardadas'), findsOneWidget);
  });
}
