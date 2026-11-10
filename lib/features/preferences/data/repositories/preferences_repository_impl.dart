import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../datasources/preferences_remote_datasource.dart';
import '../models/user_preferences_model.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  final PreferencesRemoteDataSource remoteDataSource;

  PreferencesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserPreferences>> getPreferences(String userId) {
    return _run(() => remoteDataSource.getPreferences(userId));
  }

  @override
  Future<Either<Failure, UserPreferences>> updatePreferences(
    String userId,
    UserPreferences preferences,
  ) {
    return _run(
      () => remoteDataSource.updatePreferences(
        userId,
        UserPreferencesModel.fromEntity(preferences),
      ),
    );
  }

  Future<Either<Failure, UserPreferences>> _run(
    Future<UserPreferencesModel> Function() action,
  ) async {
    try {
      return Right(await action());
    } on UnauthenticatedException {
      return const Left(UnauthenticatedFailure());
    } on AuthException {
      return const Left(UnauthenticatedFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException {
      return const Left(ServerFailure());
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
