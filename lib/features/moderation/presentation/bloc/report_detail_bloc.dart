import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/content_report.dart';
import '../../domain/entities/report_status.dart';
import '../../domain/entities/reported_content.dart';
import '../../domain/usecases/moderate_content.dart';
import '../../domain/usecases/update_report_status.dart';
import 'report_detail_event.dart';
import 'report_detail_state.dart';

/// Un reporte abierto: cambiarle el estado o actuar sobre su contenido.
class ReportDetailBloc extends Bloc<ReportDetailEvent, ReportDetailState> {
  final UpdateReportStatus updateReportStatus;
  final ModerateContent moderateContent;

  int _noticeId = 0;

  ReportDetailBloc({
    required ContentReport report,
    required this.updateReportStatus,
    required this.moderateContent,
  }) : super(ReportDetailState(report: report)) {
    on<ReportStatusChanged>(_onStatusChanged);
    on<ContentModerationRequested>(_onModerate);
  }

  Future<void> _onStatusChanged(
    ReportStatusChanged event,
    Emitter<ReportDetailState> emit,
  ) async {
    if (state.isWorking || event.status == state.report.status) return;
    final report = state.report;
    emit(ReportDetailState(report: report, isWorking: true));

    final result = await updateReportStatus(
      UpdateReportStatusParams(reportId: report.id, status: event.status),
    );
    result.fold(
      (failure) => emit(_notice(report, failure.message, isError: true)),
      (_) => emit(
        _notice(
          report.copyWith(
            status: event.status,
            reviewedAt: DateTime.now().toUtc(),
          ),
          'Reporte marcado como «${event.status.label.toLowerCase()}».',
        ),
      ),
    );
  }

  Future<void> _onModerate(
    ContentModerationRequested event,
    Emitter<ReportDetailState> emit,
  ) async {
    if (state.isWorking) return;
    final report = state.report;
    emit(ReportDetailState(report: report, isWorking: true));

    final result = await moderateContent(
      ModerateContentParams(
        reportId: report.id,
        kind: report.content.kind,
        contentId: report.content.id,
        action: event.action,
      ),
    );
    result.fold(
      (failure) => emit(_notice(report, failure.message, isError: true)),
      (_) => emit(
        _notice(
          report.copyWith(
            status: ReportStatus.resolved,
            reviewedAt: DateTime.now().toUtc(),
            content: report.content.copyWith(
              status: event.action.resultingStatus,
            ),
          ),
          _moderatedNotice(report.content.kind, event.action),
        ),
      ),
    );
  }

  String _moderatedNotice(ReportedContentKind kind, ModerationAction action) {
    final isPost = kind == ReportedContentKind.post;
    final done = switch (action) {
      ModerationAction.hide => isPost ? 'oculta' : 'oculto',
      ModerationAction.remove => isPost ? 'eliminada' : 'eliminado',
    };
    return '${kind.label} $done. Reporte resuelto.';
  }

  ReportDetailState _notice(
    ContentReport report,
    String message, {
    bool isError = false,
  }) => ReportDetailState(
    report: report,
    notice: message,
    noticeIsError: isError,
    noticeId: ++_noticeId,
  );
}
