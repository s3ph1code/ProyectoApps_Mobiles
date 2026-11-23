import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/blocked_user.dart';

abstract class BlockRepository {
  /// Las usuarias que [userId] bloqueó, de la más reciente a la más antigua.
  Future<Either<Failure, List<BlockedUser>>> getBlockedUsers(String userId);

  /// Bloquear a quien ya está bloqueada no falla: el resultado es el mismo.
  Future<Either<Failure, Unit>> blockUser({
    required String blockerId,
    required String blockedId,
  });

  /// Desbloquear a quien no está bloqueada tampoco falla.
  Future<Either<Failure, Unit>> unblockUser({
    required String blockerId,
    required String blockedId,
  });
}
