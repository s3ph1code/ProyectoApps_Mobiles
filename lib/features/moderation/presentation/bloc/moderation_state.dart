import 'package:equatable/equatable.dart';

import '../../domain/entities/content_report.dart';
import '../../domain/entities/report_status.dart';

sealed class ModerationState extends Equatable {
  const ModerationState();

  @override
  List<Object?> get props => [];
}

class ModerationInitial extends ModerationState {
  const ModerationInitial();
}

class ModerationLoading extends ModerationState {
  final ReportStatus filter;

  const ModerationLoading(this.filter);

  @override
  List<Object?> get props => [filter];
}

class ModerationLoaded extends ModerationState {
  final ReportStatus filter;
  final List<ContentReport> reports;

  const ModerationLoaded({required this.filter, required this.reports});

  @override
  List<Object?> get props => [filter, reports];
}

/// La cuenta no tiene rol de moderación.
class ModerationForbidden extends ModerationState {
  const ModerationForbidden();
}

class ModerationFailure extends ModerationState {
  final ReportStatus filter;
  final String message;

  const ModerationFailure({required this.filter, required this.message});

  @override
  List<Object?> get props => [filter, message];
}
