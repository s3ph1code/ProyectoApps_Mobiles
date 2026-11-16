import 'package:doulapp/features/community/presentation/utils/community_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 15, 18, 0);

  group('formatPostDate', () {
    test('menos de un minuto es «Ahora»', () {
      expect(
        formatPostDate(now.subtract(const Duration(seconds: 20)), now: now),
        'Ahora',
      );
    });

    test('minutos y horas del mismo día', () {
      expect(
        formatPostDate(now.subtract(const Duration(minutes: 5)), now: now),
        'Hace 5 min',
      );
      expect(
        formatPostDate(now.subtract(const Duration(hours: 3)), now: now),
        'Hace 3 h',
      );
    });

    test('ayer y los últimos días', () {
      expect(formatPostDate(DateTime(2026, 11, 14, 23), now: now), 'Ayer');
      expect(
        formatPostDate(DateTime(2026, 11, 12, 9), now: now),
        'Hace 3 días',
      );
    });

    test('más de una semana muestra la fecha, con año si es otro', () {
      expect(formatPostDate(DateTime(2026, 3, 3), now: now), '3 de marzo');
      expect(
        formatPostDate(DateTime(2025, 12, 24), now: now),
        '24 de diciembre de 2025',
      );
    });
  });

  group('authorLabel', () {
    test('sin nombre visible muestra un nombre genérico', () {
      expect(authorLabel(null), anonymousAuthorName);
      expect(authorLabel('  '), anonymousAuthorName);
      expect(authorLabel(' Ana '), 'Ana');
    });
  });
}
