import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';
import 'auth_params.dart';

class SendPasswordReset implements UseCase<void, EmailParams> {
  final AuthRepository repository;

  SendPasswordReset(this.repository);

  @override
  Future<Either<Failure, void>> call(EmailParams params) =>
      repository.sendPasswordReset(params.email);
}
