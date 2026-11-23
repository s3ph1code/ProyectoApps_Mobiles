import 'package:equatable/equatable.dart';

import '../../domain/entities/content_report.dart';

class ReportDetailState extends Equatable {
  final ContentReport report;
  final bool isWorking;

  /// Aviso de un solo uso; cada uno trae su [noticeId] para no repetirse.
  final String? notice;
  final bool noticeIsError;
  final int noticeId;

  const ReportDetailState({
    required this.report,
    this.isWorking = false,
    this.notice,
    this.noticeIsError = false,
    this.noticeId = 0,
  });

  @override
  List<Object?> get props => [
    report,
    isWorking,
    notice,
    noticeIsError,
    noticeId,
  ];
}
