import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/features/wellbeing/domain/entities/mood_checkin.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/mood_history_bloc.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/mood_history_event.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/mood_history_state.dart';
import 'package:doulapp/features/wellbeing/presentation/pages/mood_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMoodHistoryBloc extends MockBloc<MoodHistoryEvent, MoodHistoryState>
    implements MoodHistoryBloc {}

void main() {
  late MockMoodHistoryBloc bloc;

  // Fechas locales: así la etiqueta no depende de la zona horaria de quien
  // corre las pruebas.
  final history = [
    MoodCheckin(
      id: 'c-2',
      moodScore: 2,
      note: 'Noche larga',
      recordedAt: DateTime(2026, 11, 12, 8, 5),
    ),
    MoodCheckin(
      id: 'c-1',
      moodScore: 4,
      recordedAt: DateTime(2026, 11, 10, 14, 30),
    ),
  ];

  setUpAll(() => registerFallbackValue(const MoodHistoryRequested()));
  setUp(() {
    bloc = MockMoodHistoryBloc();
    when(() => bloc.state).thenReturn(const MoodHistoryInitial());
  });

  void useSmallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget buildPage() => MaterialApp(
    home: BlocProvider<MoodHistoryBloc>.value(
      value: bloc,
      child: const MoodHistoryPage(),
    ),
  );

  testWidgets('mientras carga muestra el indicador', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(const MoodHistoryLoading());

    await t.pumpWidget(buildPage());

    expect(find.byKey(const Key('mood_history_loading')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('muestra cada registro con su fecha, ánimo y nota', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(MoodHistoryLoaded(history));

    await t.pumpWidget(buildPage());

    expect(find.byKey(const Key('mood_history_item_c-2')), findsOneWidget);
    expect(find.byKey(const Key('mood_history_item_c-1')), findsOneWidget);

    expect(find.text('Mal'), findsOneWidget);
    expect(find.text('Bien'), findsOneWidget);
    expect(find.text('Noche larga'), findsOneWidget);
    expect(find.textContaining('12 nov 2026'), findsOneWidget);
    expect(find.textContaining('10 nov 2026'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('conserva el orden recibido: lo más reciente primero', (
    t,
  ) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(MoodHistoryLoaded(history));

    await t.pumpWidget(buildPage());

    final reciente = t.getTopLeft(find.byKey(const Key('mood_history_item_c-2')));
    final antiguo = t.getTopLeft(find.byKey(const Key('mood_history_item_c-1')));
    expect(reciente.dy, lessThan(antiguo.dy));
  });

  testWidgets('sin registros invita al primero, sin culpa', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(const MoodHistoryLoaded([]));

    await t.pumpWidget(buildPage());

    expect(find.byKey(const Key('mood_history_empty')), findsOneWidget);
    final texto = t
        .widget<Text>(find.byKey(const Key('mood_history_empty_message')))
        .data!;
    expect(texto, isNotEmpty);
    for (final culpa in ['deberías', 'olvidaste', 'fallaste', 'debes']) {
      expect(texto.toLowerCase(), isNot(contains(culpa)), reason: culpa);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('un error muestra el mensaje y permite reintentar', (t) async {
    useSmallPhone(t);
    when(
      () => bloc.state,
    ).thenReturn(const MoodHistoryFailure('No hay conexión.'));

    await t.pumpWidget(buildPage());

    expect(find.text('No hay conexión.'), findsOneWidget);

    await t.tap(find.byKey(const Key('mood_history_retry_button')));
    await t.pump();

    verify(() => bloc.add(const MoodHistoryRequested())).called(1);
  });

  testWidgets('una nota larga no desborda el teléfono', (t) async {
    useSmallPhone(t);
    when(() => bloc.state).thenReturn(
      MoodHistoryLoaded([
        MoodCheckin(
          id: 'c-3',
          moodScore: 3,
          note: 'Hoy ' * 120,
          recordedAt: DateTime(2026, 11, 13, 21, 0),
        ),
      ]),
    );

    await t.pumpWidget(buildPage());

    expect(t.takeException(), isNull);
  });

  group('etiqueta de fecha', () {
    test('usa el mes abreviado y la hora de 12 horas', () {
      expect(
        moodCheckinDateLabel(DateTime(2026, 11, 12, 8, 5)),
        '12 nov 2026, 8:05 a. m.',
      );
    });

    test('el mediodía y la medianoche se leen como 12', () {
      expect(
        moodCheckinDateLabel(DateTime(2026, 1, 1, 12, 0)),
        '1 ene 2026, 12:00 p. m.',
      );
      expect(
        moodCheckinDateLabel(DateTime(2026, 1, 1, 0, 30)),
        '1 ene 2026, 12:30 a. m.',
      );
    });
  });
}
