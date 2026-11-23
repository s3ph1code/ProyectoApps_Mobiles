import 'package:doulapp/features/moderation/data/models/content_report_model.dart';
import 'package:doulapp/features/moderation/domain/entities/content_report.dart';
import 'package:doulapp/features/moderation/domain/entities/report_reason.dart';
import 'package:doulapp/features/moderation/domain/entities/report_status.dart';
import 'package:doulapp/features/moderation/domain/entities/reported_content.dart';

final postReport = ContentReport(
  id: 'rep-1',
  reason: ReportReason.harassment,
  details: 'Insulta a otra usuaria',
  status: ReportStatus.pending,
  createdAt: DateTime.utc(2026, 11, 20, 10),
  reporterName: 'Lucía',
  content: const ReportedContent(
    kind: ReportedContentKind.post,
    id: 'post-1',
    body: 'Texto de la publicación reportada',
    authorId: 'author-1',
    authorName: 'Ana',
  ),
);

final commentReport = ContentReport(
  id: 'rep-2',
  reason: ReportReason.spam,
  status: ReportStatus.pending,
  createdAt: DateTime.utc(2026, 11, 21, 10),
  content: const ReportedContent(
    kind: ReportedContentKind.comment,
    id: 'comment-1',
    body: 'Compra seguidores aquí',
    authorId: 'author-2',
  ),
);

final postReportRow = {
  'id': 'rep-1',
  'reason_code': 'harassment',
  'details': 'Insulta a otra usuaria',
  'status': 'pending',
  'created_at': '2026-11-20T10:00:00+00:00',
  'reviewed_at': null,
  'reporter': {'display_name': 'Lucía'},
  'post': {
    'id': 'post-1',
    'body': 'Texto de la publicación reportada',
    'status': 'published',
    'author_id': 'author-1',
    'author': {'display_name': 'Ana'},
  },
  'comment': null,
};

final commentReportRow = {
  'id': 'rep-2',
  'reason_code': 'spam',
  'details': null,
  'status': 'pending',
  'created_at': '2026-11-21T10:00:00+00:00',
  'reviewed_at': null,
  'reporter': null,
  'post': null,
  'comment': {
    'id': 'comment-1',
    'body': 'Compra seguidores aquí',
    'status': 'published',
    'author_id': 'author-2',
    'author': null,
  },
};

ContentReportModel get postReportModel =>
    ContentReportModel.fromJson(postReportRow);
