import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/content_report.dart';
import '../entities/report_status.dart';
import '../entities/reported_content.dart';

abstract class ModerationRepository {
  /// Reportes con ese estado, del más antiguo al más reciente.
  Future<Either<Failure, List<ContentReport>>> getReports(ReportStatus status);

  Future<Either<Failure, Unit>> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    required String reviewerId,
  });

  Future<Either<Failure, Unit>> setContentStatus({
    required ReportedContentKind kind,
    required String contentId,
    required ContentStatus status,
  });
}
