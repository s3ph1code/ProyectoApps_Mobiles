/// Motivo del reporte; coincide con `content_reports.reason_code`.
enum ReportReason {
  spam('spam', 'Spam'),
  harassment('harassment', 'Acoso'),
  misinformation('misinformation', 'Desinformación'),
  inappropriate('inappropriate', 'Contenido inapropiado'),
  other('other', 'Otro motivo');

  const ReportReason(this.code, this.label);

  final String code;
  final String label;

  /// Un código desconocido se muestra como «Otro motivo».
  static ReportReason fromCode(String code) {
    for (final reason in values) {
      if (reason.code == code) return reason;
    }
    return other;
  }
}
