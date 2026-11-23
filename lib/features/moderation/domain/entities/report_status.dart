/// Estado de un reporte; coincide con `content_reports.status`.
enum ReportStatus {
  pending('pending', 'Pendiente'),
  reviewing('reviewing', 'En revisión'),
  resolved('resolved', 'Resuelto'),
  dismissed('dismissed', 'Descartado');

  const ReportStatus(this.code, this.label);

  final String code;
  final String label;

  /// `null` si el código no corresponde a un estado conocido.
  static ReportStatus? fromCode(String code) {
    for (final status in values) {
      if (status.code == code) return status;
    }
    return null;
  }
}
