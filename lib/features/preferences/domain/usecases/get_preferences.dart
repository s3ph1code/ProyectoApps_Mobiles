import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_preferences.dart';
import '../repositories/preferences_repository.dart';

class GetPreferences implements UseCase<UserPreferences, GetPreferencesParams> {
  final PreferencesRepository repository;

  GetPreferences(this.repository);

  @override
  Future<Either<Failure, UserPreferences>> call(GetPreferencesParams params) {
    return repository.getPreferences(params.userId);
  }
}

class GetPreferencesParams extends Equatable {
  final String userId;

  const GetPreferencesParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
