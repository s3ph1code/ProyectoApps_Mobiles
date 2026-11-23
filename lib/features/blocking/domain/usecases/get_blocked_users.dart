import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/blocked_user.dart';
import '../repositories/block_repository.dart';

/// Recibe el id de la usuaria de la sesión.
class GetBlockedUsers implements UseCase<List<BlockedUser>, String> {
  final BlockRepository repository;

  GetBlockedUsers(this.repository);

  @override
  Future<Either<Failure, List<BlockedUser>>> call(String userId) {
    return repository.getBlockedUsers(userId);
  }
}
