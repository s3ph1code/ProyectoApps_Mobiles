import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/needs_repository.dart';

/// Deja la consulta en el historial de la usuaria.
class SaveNeedSession implements UseCase<String, SaveNeedSessionParams> {
  final NeedsRepository repository;

  SaveNeedSession(this.repository);

  @override
  Future<Either<Failure, String>> call(SaveNeedSessionParams params) {
    final optionIds = params.optionIds.toSet().toList();

    if (optionIds.isEmpty) {
      return Future.value(const Left(NeedSelectionRequiredFailure()));
    }

    return repository.saveNeedSession(
      userId: params.userId,
      optionIds: optionIds,
    );
  }
}

class SaveNeedSessionParams extends Equatable {
  final String userId;
  final List<String> optionIds;

  const SaveNeedSessionParams({required this.userId, required this.optionIds});

  @override
  List<Object?> get props => [userId, optionIds];
}
