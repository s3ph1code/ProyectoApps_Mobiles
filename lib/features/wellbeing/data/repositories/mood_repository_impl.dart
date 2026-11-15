import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/mood_checkin.dart';
import '../../domain/repositories/mood_repository.dart';
import '../datasources/mood_remote_datasource.dart';

class MoodRepositoryImpl implements MoodRepository {
  final MoodRemoteDataSource remoteDataSource;

  MoodRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, MoodCheckin>> saveCheckin({
    required String userId,
    required int moodScore,
    String? note,
  }) {
    return _guard(
      () => remoteDataSource.insertCheckin(
        userId: userId,
        moodScore: moodScore,
        note: note,
      ),
    );
  }

  @override
  Future<Either<Failure, List<MoodCheckin>>> getHistory({
    required String userId,
    required int limit,
  }) {
    return _guard(
      () => remoteDataSource.fetchCheckins(userId: userId, limit: limit),
    );
  }

  /// Convierte las excepciones del datasource en el `Failure` que la
  /// presentación muestra.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
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
