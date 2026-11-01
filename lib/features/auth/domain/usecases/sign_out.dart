import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class SignOut implements UseCase<void, NoParams> {
  final AuthRepository repository;

  SignOut(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) => repository.signOut();
}
