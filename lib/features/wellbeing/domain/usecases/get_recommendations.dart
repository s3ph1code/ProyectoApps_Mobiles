import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/recommendation.dart';
import '../repositories/needs_repository.dart';

/// Las sugerencias para lo que la usuaria eligió.
///
/// Sin ninguna opción no hay nada que recomendar, así que no se consulta.
class GetRecommendations
    implements UseCase<List<Recommendation>, GetRecommendationsParams> {
  final NeedsRepository repository;

  GetRecommendations(this.repository);

  @override
  Future<Either<Failure, List<Recommendation>>> call(
    GetRecommendationsParams params,
  ) {
    final optionIds = params.optionIds.toSet().toList();

    if (optionIds.isEmpty) {
      return Future.value(const Left(NeedSelectionRequiredFailure()));
    }

    return repository.getRecommendations(optionIds: optionIds);
  }
}

class GetRecommendationsParams extends Equatable {
  final List<String> optionIds;

  const GetRecommendationsParams({required this.optionIds});

  @override
  List<Object?> get props => [optionIds];
}
