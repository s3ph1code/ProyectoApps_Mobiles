import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/activities/domain/entities/activity.dart';
import 'package:doulapp/features/activities/domain/entities/activity_modality.dart';
import 'package:doulapp/features/activities/domain/usecases/get_activity_by_id.dart';
import 'package:doulapp/features/activities/presentation/bloc/activity_detail_bloc.dart';
import 'package:doulapp/features/activities/presentation/bloc/activity_detail_event.dart';
import 'package:doulapp/features/activities/presentation/bloc/activity_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetActivityById extends Mock implements GetActivityById {}

void main() {
  late MockGetActivityById getActivityById;

  const activity = Activity(
    id: 'act-1',
    categoryId: 'cat-1',
    title: 'Respiración 4-7-8',
    description: 'Una pausa para bajar el ritmo.',
    modality: ActivityModality.practice,
    durationMinutes: 3,
    contentText: 'Inhala 4, sostén 7, suelta 8.',
  );

  setUpAll(
    () => registerFallbackValue(const GetActivityByIdParams(activityId: '')),
  );

  setUp(() {
    getActivityById = MockGetActivityById();
    when(
      () => getActivityById(any()),
    ).thenAnswer((_) async => const Right(activity));
  });

  ActivityDetailBloc build() =>
      ActivityDetailBloc(getActivityById: getActivityById);

  blocTest<ActivityDetailBloc, ActivityDetailState>(
    'carga la actividad del id que llega por la ruta',
    build: build,
    act: (b) => b.add(const ActivityDetailRequested('act-1')),
    expect: () => [
      const ActivityDetailLoading(),
      const ActivityDetailLoaded(activity),
    ],
    verify: (_) => verify(
      () => getActivityById(const GetActivityByIdParams(activityId: 'act-1')),
    ).called(1),
  );

  blocTest<ActivityDetailBloc, ActivityDetailState>(
    'una actividad inexistente emite un estado propio, no un error normal',
    build: () {
      when(
        () => getActivityById(any()),
      ).thenAnswer((_) async => const Left(ActivityNotFoundFailure()));
      return build();
    },
    act: (b) => b.add(const ActivityDetailRequested('act-9')),
    expect: () => [
      const ActivityDetailLoading(),
      ActivityDetailNotFound(const ActivityNotFoundFailure().message),
    ],
  );

  blocTest<ActivityDetailBloc, ActivityDetailState>(
    'si falla la carga emite el error y permite reintentar',
    build: () {
      var calls = 0;
      when(() => getActivityById(any())).thenAnswer((_) async {
        calls++;
        return calls == 1
            ? const Left(NetworkFailure())
            : const Right(activity);
      });
      return build();
    },
    act: (b) async {
      b.add(const ActivityDetailRequested('act-1'));
      await Future<void>.delayed(Duration.zero);
      b.add(const ActivityDetailRequested('act-1'));
    },
    expect: () => [
      const ActivityDetailLoading(),
      ActivityDetailFailure(const NetworkFailure().message),
      const ActivityDetailLoading(),
      const ActivityDetailLoaded(activity),
    ],
  );

  blocTest<ActivityDetailBloc, ActivityDetailState>(
    'con una carga en vuelo, una segunda petición no dispara otra consulta',
    build: () {
      // El Completer mantiene la primera consulta abierta, que es el caso
      // real que el guardia evita: tocar «Reintentar» dos veces seguidas
      // mientras la red todavía responde.
      final enVuelo = Completer<Either<Failure, Activity>>();
      when(() => getActivityById(any())).thenAnswer((_) => enVuelo.future);
      return build();
    },
    act: (b) async {
      b.add(const ActivityDetailRequested('act-1'));
      await Future<void>.delayed(Duration.zero);
      b.add(const ActivityDetailRequested('act-1'));
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [const ActivityDetailLoading()],
    verify: (_) => verify(() => getActivityById(any())).called(1),
  );
}
