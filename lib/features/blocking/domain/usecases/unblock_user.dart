import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/block_repository.dart';
import 'block_params.dart';

class UnblockUser implements UseCase<Unit, BlockParams> {
  final BlockRepository repository;

  UnblockUser(this.repository);

  @override
  Future<Either<Failure, Unit>> call(BlockParams params) {
    return repository.unblockUser(
      blockerId: params.blockerId,
      blockedId: params.blockedId,
    );
  }
}
