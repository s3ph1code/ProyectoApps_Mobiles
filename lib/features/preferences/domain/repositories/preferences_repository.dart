import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_preferences.dart';

abstract class PreferencesRepository {
  Future<Either<Failure, UserPreferences>> getPreferences(String userId);

  Future<Either<Failure, UserPreferences>> updatePreferences(
    String userId,
    UserPreferences preferences,
  );
}
