import 'package:doulapp/core/error/exceptions.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/wellbeing/data/datasources/needs_remote_datasource.dart';
import 'package:doulapp/features/wellbeing/data/models/need_option_model.dart';
import 'package:doulapp/features/wellbeing/data/models/recommendation_model.dart';
import 'package:doulapp/features/wellbeing/data/repositories/needs_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNeedsDataSource extends Mock implements NeedsRemoteDataSource {}

void main() {
  late MockNeedsDataSource dataSource;
  late NeedsRepositoryImpl repository;

  const option = NeedOptionModel(
    id: 'opt-1',
    code: 'cansancio',
    label: 'Estoy muy cansada',
  );
  const recommendation = RecommendationModel(
    id: 'rec-1',
    message: 'Una pausa corta puede ayudarte.',
    priority: 10,
    activityId: 'act-1',
    destinationCode: 'activities',
  );

  setUp(() {
    dataSource = MockNeedsDataSource();
    repository = NeedsRepositoryImpl(remoteDataSource: dataSource);
  });

  final errorCases = <String, (Exception, Failure)>{
    'ServerException': (const ServerException('x'), const ServerFailure()),
    'NetworkException': (const NetworkException('x'), const NetworkFailure()),
    'UnauthenticatedException': (
      const UnauthenticatedException(),
      const UnauthenticatedFailure(),
    ),
  };

  group('getNeedOptions', () {
    test('devuelve las opciones del datasource', () async {
      when(
        () => dataSource.fetchNeedOptions(),
      ).thenAnswer((_) async => [option]);

      final result = await repository.getNeedOptions();

      expect(result.getOrElse(() => []), [option]);
    });

    errorCases.forEach((name, pair) {
      test('mapea $name a su Failure', () async {
        when(() => dataSource.fetchNeedOptions()).thenThrow(pair.$1);

        final result = await repository.getNeedOptions();

        expect(
          result.swap().getOrElse(() => const UnexpectedFailure()),
          pair.$2,
        );
      });
    });
  });

  group('getRecommendations', () {
    test('pasa las opciones al datasource', () async {
      when(
        () => dataSource.fetchRecommendations(
          optionIds: any(named: 'optionIds'),
        ),
      ).thenAnswer((_) async => [recommendation]);

      final result = await repository.getRecommendations(
        optionIds: ['opt-1'],
      );

      expect(result.getOrElse(() => []), [recommendation]);
      verify(
        () => dataSource.fetchRecommendations(optionIds: ['opt-1']),
      ).called(1);
    });

    test('un error inesperado se vuelve UnexpectedFailure', () async {
      when(
        () => dataSource.fetchRecommendations(
          optionIds: any(named: 'optionIds'),
        ),
      ).thenThrow(StateError('boom'));

      final result = await repository.getRecommendations(optionIds: ['opt-1']);

      expect(
        result.swap().getOrElse(() => const ServerFailure()),
        const UnexpectedFailure(),
      );
    });
  });

  group('saveNeedSession', () {
    test('devuelve el id de la sesión creada', () async {
      when(
        () => dataSource.insertNeedSession(
          userId: any(named: 'userId'),
          optionIds: any(named: 'optionIds'),
        ),
      ).thenAnswer((_) async => 'sess-1');

      final result = await repository.saveNeedSession(
        userId: 'u',
        optionIds: ['opt-1'],
      );

      expect(result.getOrElse(() => ''), 'sess-1');
    });

    errorCases.forEach((name, pair) {
      test('mapea $name a su Failure', () async {
        when(
          () => dataSource.insertNeedSession(
            userId: any(named: 'userId'),
            optionIds: any(named: 'optionIds'),
          ),
        ).thenThrow(pair.$1);

        final result = await repository.saveNeedSession(
          userId: 'u',
          optionIds: ['opt-1'],
        );

        expect(
          result.swap().getOrElse(() => const UnexpectedFailure()),
          pair.$2,
        );
      });
    });
  });
}
