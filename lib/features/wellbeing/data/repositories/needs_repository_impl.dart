import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/need_option.dart';
import '../../domain/entities/recommendation.dart';
import '../../domain/repositories/needs_repository.dart';
import '../datasources/needs_remote_datasource.dart';

class NeedsRepositoryImpl implements NeedsRepository {
  final NeedsRemoteDataSource remoteDataSource;

  NeedsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<NeedOption>>> getNeedOptions() {
    return _guard(remoteDataSource.fetchNeedOptions);
  }

  @override
  Future<Either<Failure, List<Recommendation>>> getRecommendations({
    required List<String> optionIds,
  }) {
    return _guard(
      () => remoteDataSource.fetchRecommendations(optionIds: optionIds),
    );
  }

  @override
  Future<Either<Failure, String>> saveNeedSession({
    required String userId,
    required List<String> optionIds,
  }) {
    return _guard(
      () => remoteDataSource.insertNeedSession(
        userId: userId,
        optionIds: optionIds,
      ),
    );
  }

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
