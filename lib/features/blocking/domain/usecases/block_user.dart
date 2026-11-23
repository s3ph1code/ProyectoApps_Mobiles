import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/block_repository.dart';
import 'block_params.dart';

class BlockUser implements UseCase<Unit, BlockParams> {
  final BlockRepository repository;

  BlockUser(this.repository);

  @override
  Future<Either<Failure, Unit>> call(BlockParams params) {
    if (params.blockerId == params.blockedId) {
      return Future.value(const Left(CannotBlockSelfFailure()));
    }
    return repository.blockUser(
      blockerId: params.blockerId,
      blockedId: params.blockedId,
    );
  }
}
