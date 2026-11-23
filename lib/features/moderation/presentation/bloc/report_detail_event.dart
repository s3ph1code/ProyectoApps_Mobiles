import 'package:equatable/equatable.dart';

import '../../domain/entities/report_status.dart';
import '../../domain/entities/reported_content.dart';

sealed class ReportDetailEvent extends Equatable {
  const ReportDetailEvent();

  @override
  List<Object?> get props => [];
}

class ReportStatusChanged extends ReportDetailEvent {
  final ReportStatus status;

  const ReportStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class ContentModerationRequested extends ReportDetailEvent {
  final ModerationAction action;

  const ContentModerationRequested(this.action);

  @override
  List<Object?> get props => [action];
}
