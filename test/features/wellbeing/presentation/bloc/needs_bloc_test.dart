import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/usecases/get_current_user.dart';
import 'package:doulapp/features/wellbeing/domain/entities/need_option.dart';
import 'package:doulapp/features/wellbeing/domain/entities/recommendation.dart';
import 'package:doulapp/features/wellbeing/domain/usecases/get_need_options.dart';
import 'package:doulapp/features/wellbeing/domain/usecases/get_recommendations.dart';
import 'package:doulapp/features/wellbeing/domain/usecases/save_need_session.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/needs_bloc.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/needs_event.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/needs_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockGetNeedOptions extends Mock implements GetNeedOptions {}

class MockGetRecommendations extends Mock implements GetRecommendations {}

class MockSaveNeedSession extends Mock implements SaveNeedSession {}

void main() {
  late MockGetCurrentUser getCurrentUser;
  late MockGetNeedOptions getNeedOptions;
  late MockGetRecommendations getRecommendations;
  late MockSaveNeedSession saveNeedSession;

  const user = AuthUser(id: 'uuid-1', email: 'ana@icesi.edu.co');
  const options = [
    NeedOption(id: 'opt-1', code: 'cansancio', label: 'Estoy muy cansada'),
    NeedOption(id: 'opt-2', code: 'ansiedad', label: 'Me siento ansiosa'),
  ];
  const recommendations = [
    Recommendation(
      id: 'rec-1',
      message: 'Una pausa corta puede ayudarte.',
      priority: 10,
      activityId: 'act-1',
      destinationCode: 'activities',
    ),
  ];

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetRecommendationsParams(optionIds: []));
    registerFallbackValue(
      const SaveNeedSessionParams(userId: '', optionIds: []),
    );
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    getNeedOptions = MockGetNeedOptions();
    getRecommendations = MockGetRecommendations();
    saveNeedSession = MockSaveNeedSession();

    when(
      () => getCurrentUser(any()),
    ).thenAnswer((_) async => const Right(user));
    when(
      () => getNeedOptions(any()),
    ).thenAnswer((_) async => const Right(options));
    when(
      () => saveNeedSession(any()),
    ).thenAnswer((_) async => const Right('sess-1'));
    when(
      () => getRecommendations(any()),
    ).thenAnswer((_) async => const Right(recommendations));
  });

  NeedsBloc build() => NeedsBloc(
    getCurrentUser: getCurrentUser,
    getNeedOptions: getNeedOptions,
    getRecommendations: getRecommendations,
    saveNeedSession: saveNeedSession,
  );

  /// Deja el BLoC con las opciones cargadas y [ids] seleccionados.
  Future<void> selectOptions(NeedsBloc bloc, List<String> ids) async {
    bloc.add(const NeedOptionsRequested());
    await Future<void>.delayed(Duration.zero);
    for (final id in ids) {
      bloc.add(NeedOptionToggled(id));
      await Future<void>.delayed(Duration.zero);
    }
  }

  blocTest<NeedsBloc, NeedsState>(
    'al abrir carga las opciones activas, sin nada seleccionado',
    build: build,
    act: (b) => b.add(const NeedOptionsRequested()),
    expect: () => [
      const NeedsLoadingOptions(),
      const NeedsOptionsReady(options: options, selectedIds: {}),
    ],
  );

  blocTest<NeedsBloc, NeedsState>(
    'sin nada seleccionado no se puede continuar',
    build: build,
    act: (b) => b.add(const NeedOptionsRequested()),
    verify: (bloc) {
      final state = bloc.state as NeedsOptionsReady;
      expect(state.canContinue, isFalse);
    },
  );

  blocTest<NeedsBloc, NeedsState>(
    'se pueden elegir varias opciones y quitarlas',
    build: build,
    act: (b) async {
      await selectOptions(b, ['opt-1', 'opt-2']);
      b.add(const NeedOptionToggled('opt-1'));
    },
    expect: () => [
      const NeedsLoadingOptions(),
      const NeedsOptionsReady(options: options, selectedIds: {}),
      const NeedsOptionsReady(options: options, selectedIds: {'opt-1'}),
      const NeedsOptionsReady(
        options: options,
        selectedIds: {'opt-1', 'opt-2'},
      ),
      const NeedsOptionsReady(options: options, selectedIds: {'opt-2'}),
    ],
  );

  blocTest<NeedsBloc, NeedsState>(
    'continuar guarda la consulta y trae las recomendaciones',
    build: build,
    act: (b) async {
      await selectOptions(b, ['opt-1']);
      b.add(const NeedsSubmitted());
    },
    skip: 3,
    expect: () => [
      const NeedsOptionsReady(
        options: options,
        selectedIds: {'opt-1'},
        isSubmitting: true,
      ),
      const NeedsRecommendationsReady(recommendations),
    ],
    verify: (_) {
      verify(
        () => saveNeedSession(
          const SaveNeedSessionParams(userId: 'uuid-1', optionIds: ['opt-1']),
        ),
      ).called(1);
      verify(
        () => getRecommendations(
          const GetRecommendationsParams(optionIds: ['opt-1']),
        ),
      ).called(1);
    },
  );

  blocTest<NeedsBloc, NeedsState>(
    'sin recomendaciones entrega una lista vacía, no un error',
    build: () {
      when(
        () => getRecommendations(any()),
      ).thenAnswer((_) async => const Right([]));
      return build();
    },
    act: (b) async {
      await selectOptions(b, ['opt-1']);
      b.add(const NeedsSubmitted());
    },
    verify: (bloc) =>
        expect(bloc.state, const NeedsRecommendationsReady([])),
  );

  blocTest<NeedsBloc, NeedsState>(
    'continuar sin nada seleccionado no hace nada',
    build: build,
    act: (b) async {
      b.add(const NeedOptionsRequested());
      await Future<void>.delayed(Duration.zero);
      b.add(const NeedsSubmitted());
    },
    expect: () => [
      const NeedsLoadingOptions(),
      const NeedsOptionsReady(options: options, selectedIds: {}),
    ],
    verify: (_) {
      verifyNever(() => saveNeedSession(any()));
      verifyNever(() => getRecommendations(any()));
    },
  );

  blocTest<NeedsBloc, NeedsState>(
    'si no se puede guardar la consulta muestra el error',
    build: () {
      when(
        () => saveNeedSession(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      return build();
    },
    act: (b) async {
      await selectOptions(b, ['opt-1']);
      b.add(const NeedsSubmitted());
    },
    verify: (bloc) {
      expect(bloc.state, NeedsFailure(const NetworkFailure().message));
      verifyNever(() => getRecommendations(any()));
    },
  );

  blocTest<NeedsBloc, NeedsState>(
    'si fallan las recomendaciones muestra el error',
    build: () {
      when(
        () => getRecommendations(any()),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      return build();
    },
    act: (b) async {
      await selectOptions(b, ['opt-1']);
      b.add(const NeedsSubmitted());
    },
    verify: (bloc) =>
        expect(bloc.state, NeedsFailure(const ServerFailure().message)),
  );

  blocTest<NeedsBloc, NeedsState>(
    'sin sesión no guarda ni recomienda',
    build: () {
      when(
        () => getCurrentUser(any()),
      ).thenAnswer((_) async => const Right(null));
      return build();
    },
    act: (b) async {
      await selectOptions(b, ['opt-1']);
      b.add(const NeedsSubmitted());
    },
    verify: (bloc) {
      expect(
        bloc.state,
        NeedsFailure(const UnauthenticatedFailure().message),
      );
      verifyNever(() => saveNeedSession(any()));
    },
  );

  blocTest<NeedsBloc, NeedsState>(
    'si fallan las opciones muestra el error y permite reintentar',
    build: () {
      var calls = 0;
      when(() => getNeedOptions(any())).thenAnswer((_) async {
        calls++;
        return calls == 1
            ? const Left(NetworkFailure())
            : const Right(options);
      });
      return build();
    },
    act: (b) async {
      b.add(const NeedOptionsRequested());
      await Future<void>.delayed(Duration.zero);
      b.add(const NeedOptionsRequested());
    },
    expect: () => [
      const NeedsLoadingOptions(),
      NeedsFailure(const NetworkFailure().message),
      const NeedsLoadingOptions(),
      const NeedsOptionsReady(options: options, selectedIds: {}),
    ],
  );
}
