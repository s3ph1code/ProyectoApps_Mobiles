import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/wellbeing/domain/entities/mood_checkin.dart';
import 'package:doulapp/features/wellbeing/domain/repositories/mood_repository.dart';
import 'package:doulapp/features/wellbeing/domain/usecases/save_mood_checkin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMoodRepository extends Mock implements MoodRepository {}

void main() {
  late MockMoodRepository repository;
  late SaveMoodCheckin useCase;

  final saved = MoodCheckin(
    id: 'c-1',
    moodScore: 4,
    recordedAt: DateTime.utc(2026, 11, 10),
  );

  setUp(() {
    repository = MockMoodRepository();
    useCase = SaveMoodCheckin(repository);
    when(
      () => repository.saveCheckin(
        userId: any(named: 'userId'),
        moodScore: any(named: 'moodScore'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => Right(saved));
  });

  test('guarda el ánimo con la nota recortada', () async {
    final result = await useCase(
      const SaveMoodCheckinParams(
        userId: 'u',
        moodScore: 4,
        note: '  Dormí un poco  ',
      ),
    );

    expect(result, Right<Failure, MoodCheckin>(saved));
    verify(
      () => repository.saveCheckin(
        userId: 'u',
        moodScore: 4,
        note: 'Dormí un poco',
      ),
    ).called(1);
  });

  test('una nota vacía o en blanco se guarda como ausente', () async {
    await useCase(
      const SaveMoodCheckinParams(userId: 'u', moodScore: 3, note: '   '),
    );

    verify(
      () => repository.saveCheckin(userId: 'u', moodScore: 3, note: null),
    ).called(1);
  });

  test('acepta una nota de exactamente 500 caracteres', () async {
    final result = await useCase(
      SaveMoodCheckinParams(
        userId: 'u',
        moodScore: 5,
        note: 'a' * SaveMoodCheckin.maxNoteLength,
      ),
    );

    expect(result.isRight(), isTrue);
  });

  test('rechaza una nota de más de 500 caracteres', () async {
    final result = await useCase(
      SaveMoodCheckinParams(userId: 'u', moodScore: 5, note: 'a' * 501),
    );

    expect(result, const Left<Failure, MoodCheckin>(MoodNoteTooLongFailure()));
    verifyNever(
      () => repository.saveCheckin(
        userId: any(named: 'userId'),
        moodScore: any(named: 'moodScore'),
        note: any(named: 'note'),
      ),
    );
  });

  for (final score in <int?>[null, 0, 6, -1]) {
    test('rechaza el ánimo $score', () async {
      final result = await useCase(
        SaveMoodCheckinParams(userId: 'u', moodScore: score),
      );

      expect(
        result,
        const Left<Failure, MoodCheckin>(MoodScoreRequiredFailure()),
      );
    });
  }

  test('propaga el fallo del repositorio', () async {
    when(
      () => repository.saveCheckin(
        userId: any(named: 'userId'),
        moodScore: any(named: 'moodScore'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await useCase(
      const SaveMoodCheckinParams(userId: 'u', moodScore: 2),
    );

    expect(result, const Left<Failure, MoodCheckin>(NetworkFailure()));
  });
}
