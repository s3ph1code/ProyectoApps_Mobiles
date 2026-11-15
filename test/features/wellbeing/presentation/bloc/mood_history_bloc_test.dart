import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/usecases/get_current_user.dart';
import 'package:doulapp/features/wellbeing/domain/entities/mood_checkin.dart';
import 'package:doulapp/features/wellbeing/domain/usecases/get_mood_history.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/mood_history_bloc.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/mood_history_event.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/mood_history_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockGetMoodHistory extends Mock implements GetMoodHistory {}

void main() {
  late MockGetCurrentUser getCurrentUser;
  late MockGetMoodHistory getMoodHistory;

  const user = AuthUser(id: 'uuid-1', email: 'ana@icesi.edu.co');
  final history = [
    MoodCheckin(
      id: 'c-2',
      moodScore: 2,
      note: 'Noche larga',
      recordedAt: DateTime.utc(2026, 11, 12),
    ),
    MoodCheckin(
      id: 'c-1',
      moodScore: 4,
      recordedAt: DateTime.utc(2026, 11, 10),
    ),
  ];

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetMoodHistoryParams(userId: ''));
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    getMoodHistory = MockGetMoodHistory();
    when(
      () => getCurrentUser(any()),
    ).thenAnswer((_) async => const Right(user));
  });

  MoodHistoryBloc build() => MoodHistoryBloc(
    getCurrentUser: getCurrentUser,
    getMoodHistory: getMoodHistory,
  );

  blocTest<MoodHistoryBloc, MoodHistoryState>(
    'carga los últimos 30 registros de la usuaria actual',
    build: () {
      when(
        () => getMoodHistory(any()),
      ).thenAnswer((_) async => Right(history));
      return build();
    },
    act: (b) => b.add(const MoodHistoryRequested()),
    expect: () => [const MoodHistoryLoading(), MoodHistoryLoaded(history)],
    verify: (_) => verify(
      () => getMoodHistory(
        const GetMoodHistoryParams(
          userId: 'uuid-1',
          limit: GetMoodHistory.defaultLimit,
        ),
      ),
    ).called(1),
  );

  blocTest<MoodHistoryBloc, MoodHistoryState>(
    'sin registros emite un historial vacío, no un error',
    build: () {
      when(
        () => getMoodHistory(any()),
      ).thenAnswer((_) async => const Right([]));
      return build();
    },
    act: (b) => b.add(const MoodHistoryRequested()),
    expect: () => [const MoodHistoryLoading(), const MoodHistoryLoaded([])],
  );

  blocTest<MoodHistoryBloc, MoodHistoryState>(
    'si la carga falla emite el error y permite reintentar',
    build: () {
      var calls = 0;
      when(() => getMoodHistory(any())).thenAnswer((_) async {
        calls++;
        return calls == 1 ? const Left(NetworkFailure()) : Right(history);
      });
      return build();
    },
    act: (b) async {
      b.add(const MoodHistoryRequested());
      await Future<void>.delayed(Duration.zero);
      b.add(const MoodHistoryRequested());
    },
    expect: () => [
      const MoodHistoryLoading(),
      MoodHistoryFailure(const NetworkFailure().message),
      const MoodHistoryLoading(),
      MoodHistoryLoaded(history),
    ],
  );

  blocTest<MoodHistoryBloc, MoodHistoryState>(
    'sin sesión emite el error y no consulta el historial',
    build: () {
      when(
        () => getCurrentUser(any()),
      ).thenAnswer((_) async => const Right(null));
      return build();
    },
    act: (b) => b.add(const MoodHistoryRequested()),
    expect: () => [
      const MoodHistoryLoading(),
      MoodHistoryFailure(const UnauthenticatedFailure().message),
    ],
    verify: (_) => verifyNever(() => getMoodHistory(any())),
  );

  blocTest<MoodHistoryBloc, MoodHistoryState>(
    'si no se puede leer la sesión muestra ese error',
    build: () {
      when(
        () => getCurrentUser(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      return build();
    },
    act: (b) => b.add(const MoodHistoryRequested()),
    expect: () => [
      const MoodHistoryLoading(),
      MoodHistoryFailure(const NetworkFailure().message),
    ],
  );

  blocTest<MoodHistoryBloc, MoodHistoryState>(
    'ignora una segunda petición mientras ya está cargando',
    build: () {
      when(() => getMoodHistory(any())).thenAnswer((_) async => Right(history));
      return build();
    },
    act: (b) {
      b.add(const MoodHistoryRequested());
      b.add(const MoodHistoryRequested());
    },
    expect: () => [const MoodHistoryLoading(), MoodHistoryLoaded(history)],
    verify: (_) => verify(() => getMoodHistory(any())).called(1),
  );
}
