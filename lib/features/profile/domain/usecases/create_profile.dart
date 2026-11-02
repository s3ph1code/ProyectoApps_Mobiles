import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class CreateProfile implements UseCase<Profile, CreateProfileParams> {
  final ProfileRepository repository;

  CreateProfile(this.repository);

  @override
  Future<Either<Failure, Profile>> call(CreateProfileParams params) {
    return repository.createProfile(
      userId: params.userId,
      displayName: params.displayName,
    );
  }
}

class CreateProfileParams extends Equatable {
  final String userId;
  final String displayName;

  const CreateProfileParams({required this.userId, required this.displayName});

  @override
  List<Object?> get props => [userId, displayName];
}
