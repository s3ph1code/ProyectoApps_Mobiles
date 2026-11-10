import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_preferences.dart';
import '../repositories/preferences_repository.dart';

class UpdatePreferences
    implements UseCase<UserPreferences, UpdatePreferencesParams> {
  final PreferencesRepository repository;

  UpdatePreferences(this.repository);

  @override
  Future<Either<Failure, UserPreferences>> call(
    UpdatePreferencesParams params,
  ) {
    return repository.updatePreferences(params.userId, params.preferences);
  }
}

class UpdatePreferencesParams extends Equatable {
  final String userId;
  final UserPreferences preferences;

  const UpdatePreferencesParams({
    required this.userId,
    required this.preferences,
  });

  @override
  List<Object?> get props => [userId, preferences];
}
