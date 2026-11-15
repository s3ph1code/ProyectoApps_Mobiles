import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/wellbeing/domain/entities/mood_checkin.dart';
import 'package:doulapp/features/wellbeing/domain/repositories/mood_repository.dart';
import 'package:doulapp/features/wellbeing/domain/usecases/get_mood_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMoodRepository extends Mock implements MoodRepository {}

void main() {
  late MockMoodRepository repository;
  late GetMoodHistory useCase;

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

  setUp(() {
    repository = MockMoodRepository();
    useCase = GetMoodHistory(repository);
    when(
      () => repository.getHistory(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => Right(history));
  });

  test('devuelve el historial tal como lo entrega el repositorio', () async {
    final result = await useCase(const GetMoodHistoryParams(userId: 'u'));

    expect(result, Right<Failure, List<MoodCheckin>>(history));
  });

  test('pide los últimos 30 registros cuando no se indica un límite', () async {
    await useCase(const GetMoodHistoryParams(userId: 'u'));

    verify(() => repository.getHistory(userId: 'u', limit: 30)).called(1);
  });

  test('respeta un límite menor indicado por quien llama', () async {
    await useCase(const GetMoodHistoryParams(userId: 'u', limit: 10));

    verify(() => repository.getHistory(userId: 'u', limit: 10)).called(1);
  });

  test('acota un límite mayor al máximo permitido', () async {
    await useCase(const GetMoodHistoryParams(userId: 'u', limit: 500));

    verify(
      () => repository.getHistory(
        userId: 'u',
        limit: GetMoodHistory.maxLimit,
      ),
    ).called(1);
  });

  for (final limit in [0, -5]) {
    test('un límite de $limit se acota a un registro', () async {
      await useCase(GetMoodHistoryParams(userId: 'u', limit: limit));

      verify(() => repository.getHistory(userId: 'u', limit: 1)).called(1);
    });
  }

  test('propaga el fallo del repositorio', () async {
    when(
      () => repository.getHistory(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await useCase(const GetMoodHistoryParams(userId: 'u'));

    expect(result, const Left<Failure, List<MoodCheckin>>(NetworkFailure()));
  });
}
