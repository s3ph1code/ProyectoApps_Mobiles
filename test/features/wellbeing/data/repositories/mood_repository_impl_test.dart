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

  final model = MoodCheckinModel(
    id: 'c-1',
    moodScore: 4,
    recordedAt: DateTime.utc(2026, 11, 10),
  );

  setUp(() {
    dataSource = MockMoodDataSource();
    repository = MoodRepositoryImpl(remoteDataSource: dataSource);
  });

  When<Future<MoodCheckinModel>> stub() => when(
    () => dataSource.insertCheckin(
      userId: any(named: 'userId'),
      moodScore: any(named: 'moodScore'),
      note: any(named: 'note'),
    ),
  );

  Future<Either<Failure, MoodCheckin>> save() =>
      repository.saveCheckin(userId: 'u', moodScore: 4);

  test('devuelve el check-in guardado', () async {
    stub().thenAnswer((_) async => model);

    expect(await save(), Right<Failure, MoodCheckin>(model));
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

      expect(await save(), Left<Failure, MoodCheckin>(pair.$2));
    });
  });

  test('un error inesperado se vuelve UnexpectedFailure', () async {
    stub().thenThrow(StateError('boom'));

    expect(await save(), const Left<Failure, MoodCheckin>(UnexpectedFailure()));
  });
}
