import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/content_report.dart';
import '../../domain/entities/report_status.dart';
import '../../domain/entities/reported_content.dart';
import '../../domain/repositories/moderation_repository.dart';
import '../datasources/moderation_remote_datasource.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  final ModerationRemoteDataSource remoteDataSource;

  ModerationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ContentReport>>> getReports(ReportStatus status) {
    return _run<List<ContentReport>>(() => remoteDataSource.getReports(status));
  }

  @override
  Future<Either<Failure, Unit>> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    required String reviewerId,
  }) {
    return _run(() async {
      await remoteDataSource.updateReportStatus(
        reportId: reportId,
        status: status,
        reviewerId: reviewerId,
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> setContentStatus({
    required ReportedContentKind kind,
    required String contentId,
    required ContentStatus status,
  }) {
    return _run(() async {
      await remoteDataSource.setContentStatus(
        kind: kind,
        contentId: contentId,
        status: status,
      );
      return unit;
    });
  }

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
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
