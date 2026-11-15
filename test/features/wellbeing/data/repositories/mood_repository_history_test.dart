import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/exceptions.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/wellbeing/data/datasources/mood_remote_datasource.dart';
import 'package:doulapp/features/wellbeing/data/models/mood_checkin_model.dart';
import 'package:doulapp/features/wellbeing/data/repositories/mood_repository_impl.dart';
import 'package:doulapp/features/wellbeing/domain/entities/mood_checkin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMoodDataSource extends Mock implements MoodRemoteDataSource {}

void main() {
  late MockMoodDataSource dataSource;
  late MoodRepositoryImpl repository;

  final models = [
    MoodCheckinModel(
      id: 'c-2',
      moodScore: 2,
      note: 'Noche larga',
      recordedAt: DateTime.utc(2026, 11, 12),
    ),
    MoodCheckinModel(
      id: 'c-1',
      moodScore: 4,
      recordedAt: DateTime.utc(2026, 11, 10),
    ),
  ];

  setUp(() {
    dataSource = MockMoodDataSource();
    repository = MoodRepositoryImpl(remoteDataSource: dataSource);
  });

  When<Future<List<MoodCheckinModel>>> stub() => when(
    () => dataSource.fetchCheckins(
      userId: any(named: 'userId'),
      limit: any(named: 'limit'),
    ),
  );

  Future<Either<Failure, List<MoodCheckin>>> load() =>
      repository.getHistory(userId: 'u', limit: 30);

  test('devuelve el historial y pasa el usuario y el límite', () async {
    stub().thenAnswer((_) async => models);

    expect(await load(), Right<Failure, List<MoodCheckin>>(models));
    verify(() => dataSource.fetchCheckins(userId: 'u', limit: 30)).called(1);
  });

  test('sin registros devuelve una lista vacía, no un fallo', () async {
    stub().thenAnswer((_) async => []);

    (await load()).fold(
      (failure) => fail('esperaba una lista vacía, llegó ${failure.message}'),
      (history) => expect(history, isEmpty),
    );
  });

  final cases = <String, (Exception, Failure)>{
    'ServerException': (const ServerException('x'), const ServerFailure()),
    'NetworkException': (const NetworkException('x'), const NetworkFailure()),
    'UnauthenticatedException': (
      const UnauthenticatedException(),
      const UnauthenticatedFailure(),
    ),
  };
  cases.forEach((name, pair) {
    test('mapea $name a su Failure', () async {
      stub().thenThrow(pair.$1);

      expect(await load(), Left<Failure, List<MoodCheckin>>(pair.$2));
    });
  });

  test('un error inesperado se vuelve UnexpectedFailure', () async {
    stub().thenThrow(StateError('boom'));

    expect(
      await load(),
      const Left<Failure, List<MoodCheckin>>(UnexpectedFailure()),
    );
  });
}
