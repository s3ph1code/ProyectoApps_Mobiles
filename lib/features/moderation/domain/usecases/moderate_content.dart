import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/report_status.dart';
import '../entities/reported_content.dart';
import '../repositories/moderation_repository.dart';
import 'resolve_moderator.dart';

/// Oculta o elimina el contenido reportado. Al actuar sobre él, el reporte
/// queda resuelto: la moderadora no tiene que hacerlo en un paso aparte.
class ModerateContent implements UseCase<Unit, ModerateContentParams> {
  final ResolveModerator resolveModerator;
  final ModerationRepository repository;

  ModerateContent({required this.resolveModerator, required this.repository});

  @override
  Future<Either<Failure, Unit>> call(ModerateContentParams params) async {
    final access = await resolveModerator(const NoParams());
    final moderator = access.fold((_) => null, (m) => m);
    if (moderator == null) {
      return access.map((_) => unit);
    }

    final changed = await repository.setContentStatus(
      kind: params.kind,
      contentId: params.contentId,
      status: params.action.resultingStatus,
    );
    if (changed.isLeft()) return changed;

    return repository.updateReportStatus(
      reportId: params.reportId,
      status: ReportStatus.resolved,
      reviewerId: moderator.userId,
    );
  }
}

class ModerateContentParams extends Equatable {
  final String reportId;
  final ReportedContentKind kind;
  final String contentId;
  final ModerationAction action;

  const ModerateContentParams({
    required this.reportId,
    required this.kind,
    required this.contentId,
    required this.action,
  });

  @override
  List<Object?> get props => [reportId, kind, contentId, action];
}
