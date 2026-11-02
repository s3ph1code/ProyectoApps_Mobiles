import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_role.dart';
import '../repositories/profile_repository.dart';

class GetUserRoles implements UseCase<List<AppRole>, GetUserRolesParams> {
  final ProfileRepository repository;

  GetUserRoles(this.repository);

  @override
  Future<Either<Failure, List<AppRole>>> call(GetUserRolesParams params) {
    return repository.getRoles(params.userId);
  }
}

class GetUserRolesParams extends Equatable {
  final String userId;

  const GetUserRolesParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
