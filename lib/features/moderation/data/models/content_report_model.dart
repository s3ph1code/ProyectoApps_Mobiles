import '../../domain/entities/content_report.dart';
import '../../domain/entities/report_reason.dart';
import '../../domain/entities/report_status.dart';
import '../../domain/entities/reported_content.dart';

class ContentReportModel extends ContentReport {
  const ContentReportModel({
    required super.id,
    required super.reason,
    super.details,
    required super.status,
    required super.createdAt,
    super.reviewedAt,
    super.reporterName,
    required super.content,
  });

  /// Fila de `content_reports` con la reportadora (`reporter`) y el contenido
  /// (`post` o `comment`, solo uno) embebidos. Un perfil privado llega nulo.
  factory ContentReportModel.fromJson(Map<String, dynamic> json) {
    final post = json['post'] as Map<String, dynamic>?;
    final comment = json['comment'] as Map<String, dynamic>?;
    final target = post ?? comment;
    if (target == null) {
      throw const FormatException('El reporte no apunta a ningún contenido.');
    }

    final author = target['author'] as Map<String, dynamic>?;
    final reporter = json['reporter'] as Map<String, dynamic>?;
    final reviewedAt = json['reviewed_at'] as String?;

    return ContentReportModel(
      id: json['id'] as String,
      reason: ReportReason.fromCode(json['reason_code'] as String),
      details: json['details'] as String?,
      status:
          ReportStatus.fromCode(json['status'] as String) ??
          ReportStatus.pending,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: reviewedAt == null ? null : DateTime.parse(reviewedAt),
      reporterName: reporter?['display_name'] as String?,
      content: ReportedContent(
        kind: post != null
            ? ReportedContentKind.post
            : ReportedContentKind.comment,
        id: target['id'] as String,
        body: target['body'] as String,
        authorId: target['author_id'] as String,
        authorName: author?['display_name'] as String?,
        status: ContentStatus.fromCode(target['status'] as String),
      ),
    );
  }
}
