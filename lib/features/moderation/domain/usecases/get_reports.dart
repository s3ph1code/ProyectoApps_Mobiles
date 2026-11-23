import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/content_report.dart';
import '../entities/report_status.dart';
import '../repositories/moderation_repository.dart';
import 'resolve_moderator.dart';

class GetReports implements UseCase<List<ContentReport>, GetReportsParams> {
  final ResolveModerator resolveModerator;
  final ModerationRepository repository;

  GetReports({required this.resolveModerator, required this.repository});

  @override
  Future<Either<Failure, List<ContentReport>>> call(
    GetReportsParams params,
  ) async {
    final access = await resolveModerator(const NoParams());
    return access.fold(
      (failure) => Left(failure),
      (_) => repository.getReports(params.status),
    );
  }
}

class GetReportsParams extends Equatable {
  final ReportStatus status;

  const GetReportsParams({this.status = ReportStatus.pending});

  @override
  List<Object?> get props => [status];
}
