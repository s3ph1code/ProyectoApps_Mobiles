const _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Cuándo se publicó algo, en palabras: «Hace 5 min», «Ayer», «3 de marzo».
/// [now] se puede fijar en las pruebas.
String formatPostDate(DateTime date, {DateTime? now}) {
  final local = date.toLocal();
  final reference = (now ?? DateTime.now()).toLocal();
  final difference = reference.difference(local);

  if (difference.inMinutes < 1) return 'Ahora';
  if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';

  final today = DateTime(reference.year, reference.month, reference.day);
  final day = DateTime(local.year, local.month, local.day);
  final days = today.difference(day).inDays;

  if (days == 0) return 'Hace ${difference.inHours} h';
  if (days == 1) return 'Ayer';
  if (days < 7) return 'Hace $days días';

  final base = '${local.day} de ${_months[local.month - 1]}';
  return local.year == reference.year ? base : '$base de ${local.year}';
}

/// Nombre que se muestra cuando el perfil de la autora no es visible.
const anonymousAuthorName = 'Una mamá de la comunidad';

String authorLabel(String? name) {
  final trimmed = name?.trim() ?? '';
  return trimmed.isEmpty ? anonymousAuthorName : trimmed;
}
