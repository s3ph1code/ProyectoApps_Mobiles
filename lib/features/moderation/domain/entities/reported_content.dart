import 'package:equatable/equatable.dart';

enum ReportedContentKind {
  post('Publicación'),
  comment('Comentario');

  const ReportedContentKind(this.label);

  final String label;
}

/// Estado de una publicación o comentario; coincide con `status` en
/// `posts` y `comments`.
enum ContentStatus {
  published('published', 'Visible'),
  hidden('hidden', 'Oculto'),
  removed('removed', 'Eliminado');

  const ContentStatus(this.code, this.label);

  final String code;
  final String label;

  static ContentStatus fromCode(String code) {
    for (final status in values) {
      if (status.code == code) return status;
    }
    return published;
  }
}

/// Qué puede hacer la moderación con el contenido reportado.
enum ModerationAction {
  hide(ContentStatus.hidden),
  remove(ContentStatus.removed);

  const ModerationAction(this.resultingStatus);

  final ContentStatus resultingStatus;
}

/// La publicación o el comentario al que apunta un reporte.
class ReportedContent extends Equatable {
  final ReportedContentKind kind;
  final String id;
  final String body;
  final String authorId;
  final String? authorName;
  final ContentStatus status;

  const ReportedContent({
    required this.kind,
    required this.id,
    required this.body,
    required this.authorId,
    this.authorName,
    this.status = ContentStatus.published,
  });

  ReportedContent copyWith({ContentStatus? status}) => ReportedContent(
    kind: kind,
    id: id,
    body: body,
    authorId: authorId,
    authorName: authorName,
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [kind, id, body, authorId, authorName, status];
}
