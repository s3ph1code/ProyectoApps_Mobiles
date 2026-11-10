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
  }) async {
    try {
      return Right(
        await remoteDataSource.insertCheckin(
          userId: userId,
          moodScore: moodScore,
          note: note,
        ),
      );
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
