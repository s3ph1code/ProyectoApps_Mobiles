import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/usecases/get_current_user.dart';
import 'package:doulapp/features/wellbeing/domain/entities/mood_checkin.dart';
import 'package:doulapp/features/wellbeing/domain/usecases/save_mood_checkin.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/mood_checkin_bloc.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/mood_checkin_event.dart';
import 'package:doulapp/features/wellbeing/presentation/bloc/mood_checkin_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockSaveMoodCheckin extends Mock implements SaveMoodCheckin {}

void main() {
  late MockGetCurrentUser getCurrentUser;
  late MockSaveMoodCheckin saveMoodCheckin;

  const user = AuthUser(id: 'uuid-1', email: 'ana@icesi.edu.co');
  final saved = MoodCheckin(
    id: 'c-1',
    moodScore: 4,
    note: 'Bien',
    recordedAt: DateTime.utc(2026, 11, 10),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const SaveMoodCheckinParams(userId: '', moodScore: 1),
    );
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    saveMoodCheckin = MockSaveMoodCheckin();
    when(
      () => getCurrentUser(any()),
    ).thenAnswer((_) async => const Right(user));
  });

  MoodCheckinBloc build() => MoodCheckinBloc(
    getCurrentUser: getCurrentUser,
    saveMoodCheckin: saveMoodCheckin,
  );

  blocTest<MoodCheckinBloc, MoodCheckinState>(
    'guarda el check-in de la usuaria actual y emite éxito',
    build: () {
      when(() => saveMoodCheckin(any())).thenAnswer((_) async => Right(saved));
      return build();
    },
    act: (b) => b.add(const MoodCheckinSubmitted(moodScore: 4, note: 'Bien')),
    expect: () => [const MoodCheckinSaving(), MoodCheckinSuccess(saved)],
    verify: (_) => verify(
      () => saveMoodCheckin(
        const SaveMoodCheckinParams(
          userId: 'uuid-1',
          moodScore: 4,
          note: 'Bien',
        ),
      ),
    ).called(1),
  );

  blocTest<MoodCheckinBloc, MoodCheckinState>(
    'sin ánimo elegido emite el fallo de validación',
    build: () {
      when(
        () => saveMoodCheckin(any()),
      ).thenAnswer((_) async => const Left(MoodScoreRequiredFailure()));
      return build();
    },
    act: (b) => b.add(const MoodCheckinSubmitted(moodScore: null)),
    expect: () => [
      const MoodCheckinSaving(),
      MoodCheckinFailure(const MoodScoreRequiredFailure().message),
    ],
  );

  blocTest<MoodCheckinBloc, MoodCheckinState>(
    'si el guardado falla emite el error y permite reintentar',
    build: () {
      var calls = 0;
      when(() => saveMoodCheckin(any())).thenAnswer((_) async {
        calls++;
        return calls == 1 ? const Left(NetworkFailure()) : Right(saved);
      });
      return build();
    },
    act: (b) async {
      b.add(const MoodCheckinSubmitted(moodScore: 4));
      await Future<void>.delayed(Duration.zero);
      b.add(const MoodCheckinSubmitted(moodScore: 4));
    },
    expect: () => [
      const MoodCheckinSaving(),
      MoodCheckinFailure(const NetworkFailure().message),
      const MoodCheckinSaving(),
      MoodCheckinSuccess(saved),
    ],
  );

  blocTest<MoodCheckinBloc, MoodCheckinState>(
    'sin sesión emite el error y no guarda',
    build: () {
      when(
        () => getCurrentUser(any()),
      ).thenAnswer((_) async => const Right(null));
      return build();
    },
    act: (b) => b.add(const MoodCheckinSubmitted(moodScore: 4)),
    expect: () => [
      const MoodCheckinSaving(),
      MoodCheckinFailure(const UnauthenticatedFailure().message),
    ],
    verify: (_) => verifyNever(() => saveMoodCheckin(any())),
  );

  blocTest<MoodCheckinBloc, MoodCheckinState>(
    'si no se puede leer la sesión muestra ese error',
    build: () {
      when(
        () => getCurrentUser(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      return build();
    },
    act: (b) => b.add(const MoodCheckinSubmitted(moodScore: 4)),
    expect: () => [
      const MoodCheckinSaving(),
      MoodCheckinFailure(const NetworkFailure().message),
    ],
  );
}
