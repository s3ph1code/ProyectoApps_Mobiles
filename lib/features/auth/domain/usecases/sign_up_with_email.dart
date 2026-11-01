import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';
import 'auth_params.dart';

class SignUpWithEmail implements UseCase<AuthUser, EmailPasswordParams> {
  final AuthRepository repository;

  SignUpWithEmail(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(EmailPasswordParams params) {
    return repository.signUp(email: params.email, password: params.password);
  }
}
