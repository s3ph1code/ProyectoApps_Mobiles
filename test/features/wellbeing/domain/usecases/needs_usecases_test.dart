import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/wellbeing/domain/entities/need_option.dart';
import 'package:doulapp/features/wellbeing/domain/entities/recommendation.dart';
import 'package:doulapp/features/wellbeing/domain/repositories/needs_repository.dart';
import 'package:doulapp/features/wellbeing/domain/usecases/get_need_options.dart';
import 'package:doulapp/features/wellbeing/domain/usecases/get_recommendations.dart';
import 'package:doulapp/features/wellbeing/domain/usecases/save_need_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNeedsRepository extends Mock implements NeedsRepository {}

void main() {
  late MockNeedsRepository repository;

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

  setUp(() => repository = MockNeedsRepository());

  group('GetNeedOptions', () {
    test('devuelve las opciones activas', () async {
      when(
        () => repository.getNeedOptions(),
      ).thenAnswer((_) async => const Right(options));

      final result = await GetNeedOptions(repository)(const NoParams());

      expect(result.getOrElse(() => []), options);
    });

    test('propaga el fallo', () async {
      when(
        () => repository.getNeedOptions(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await GetNeedOptions(repository)(const NoParams());

      expect(
        result.swap().getOrElse(() => const UnexpectedFailure()),
        const NetworkFailure(),
      );
    });
  });

  group('GetRecommendations', () {
    setUp(() {
      when(
        () => repository.getRecommendations(optionIds: any(named: 'optionIds')),
      ).thenAnswer((_) async => const Right(recommendations));
    });

    test('consulta las recomendaciones de las opciones elegidas', () async {
      final result = await GetRecommendations(repository)(
        const GetRecommendationsParams(optionIds: ['opt-1', 'opt-2']),
      );

      expect(result.getOrElse(() => []), recommendations);
      verify(
        () => repository.getRecommendations(optionIds: ['opt-1', 'opt-2']),
      ).called(1);
    });

    test('sin ninguna opción elegida no consulta nada', () async {
      final result = await GetRecommendations(repository)(
        const GetRecommendationsParams(optionIds: []),
      );

      expect(
        result.swap().getOrElse(() => const UnexpectedFailure()),
        const NeedSelectionRequiredFailure(),
      );
      verifyNever(
        () => repository.getRecommendations(optionIds: any(named: 'optionIds')),
      );
    });

    test('ignora opciones repetidas', () async {
      await GetRecommendations(repository)(
        const GetRecommendationsParams(optionIds: ['opt-1', 'opt-1', 'opt-2']),
      );

      verify(
        () => repository.getRecommendations(optionIds: ['opt-1', 'opt-2']),
      ).called(1);
    });
  });

  group('SaveNeedSession', () {
    setUp(() {
      when(
        () => repository.saveNeedSession(
          userId: any(named: 'userId'),
          optionIds: any(named: 'optionIds'),
        ),
      ).thenAnswer((_) async => const Right('sess-1'));
    });

    test('guarda la consulta de la usuaria con sus opciones', () async {
      final result = await SaveNeedSession(repository)(
        const SaveNeedSessionParams(userId: 'u', optionIds: ['opt-1']),
      );

      expect(result.getOrElse(() => ''), 'sess-1');
      verify(
        () => repository.saveNeedSession(userId: 'u', optionIds: ['opt-1']),
      ).called(1);
    });

    test('sin opciones no guarda nada', () async {
      final result = await SaveNeedSession(repository)(
        const SaveNeedSessionParams(userId: 'u', optionIds: []),
      );

      expect(
        result.swap().getOrElse(() => const UnexpectedFailure()),
        const NeedSelectionRequiredFailure(),
      );
      verifyNever(
        () => repository.saveNeedSession(
          userId: any(named: 'userId'),
          optionIds: any(named: 'optionIds'),
        ),
      );
    });
  });
}
