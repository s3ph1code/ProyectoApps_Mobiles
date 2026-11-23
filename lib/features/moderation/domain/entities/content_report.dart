import 'package:equatable/equatable.dart';

import 'report_reason.dart';
import 'report_status.dart';
import 'reported_content.dart';

class ContentReport extends Equatable {
  final String id;
  final ReportReason reason;
  final String? details;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reporterName;
  final ReportedContent content;

  const ContentReport({
    required this.id,
    required this.reason,
    this.details,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reporterName,
    required this.content,
  });

  ContentReport copyWith({
    ReportStatus? status,
    DateTime? reviewedAt,
    ReportedContent? content,
  }) => ContentReport(
    id: id,
    reason: reason,
    details: details,
    status: status ?? this.status,
    createdAt: createdAt,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    reporterName: reporterName,
    content: content ?? this.content,
  );

  @override
  List<Object?> get props => [
    id,
    reason,
    details,
    status,
    createdAt,
    reviewedAt,
    reporterName,
    content,
  ];
}
