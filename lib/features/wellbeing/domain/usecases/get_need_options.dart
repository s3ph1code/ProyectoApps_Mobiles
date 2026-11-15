import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/need_option.dart';
import '../repositories/needs_repository.dart';

/// Las opciones de «No sé qué necesito».
class GetNeedOptions implements UseCase<List<NeedOption>, NoParams> {
  final NeedsRepository repository;

  GetNeedOptions(this.repository);

  @override
  Future<Either<Failure, List<NeedOption>>> call(NoParams params) {
    return repository.getNeedOptions();
  }
}
