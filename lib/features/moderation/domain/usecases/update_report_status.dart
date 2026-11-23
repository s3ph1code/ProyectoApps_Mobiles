import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/report_status.dart';
import '../repositories/moderation_repository.dart';
import 'resolve_moderator.dart';

/// Cambia el estado de un reporte y deja registrado quién lo revisó.
class UpdateReportStatus implements UseCase<Unit, UpdateReportStatusParams> {
  final ResolveModerator resolveModerator;
  final ModerationRepository repository;

  UpdateReportStatus({
    required this.resolveModerator,
    required this.repository,
  });

  @override
  Future<Either<Failure, Unit>> call(UpdateReportStatusParams params) async {
    final access = await resolveModerator(const NoParams());
    return access.fold(
      (failure) async => Left(failure),
      (moderator) => repository.updateReportStatus(
        reportId: params.reportId,
        status: params.status,
        reviewerId: moderator.userId,
      ),
    );
  }
}

class UpdateReportStatusParams extends Equatable {
  final String reportId;
  final ReportStatus status;

  const UpdateReportStatusParams({
    required this.reportId,
    required this.status,
  });

  @override
  List<Object?> get props => [reportId, status];
}
