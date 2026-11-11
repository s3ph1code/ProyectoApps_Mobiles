import 'dart:typed_data';

import 'package:doulapp/features/profile/presentation/services/avatar_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Uint8List bytes(List<int> head) =>
      Uint8List.fromList([...head, ...List.filled(16, 0)]);

  test('reconoce JPG', () {
    expect(detectImageMimeType(bytes([0xFF, 0xD8, 0xFF, 0xE0])), 'image/jpeg');
  });

  test('reconoce PNG', () {
    expect(
      detectImageMimeType(
        bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
      ),
      'image/png',
    );
  });

  test('reconoce WebP', () {
    final webp = Uint8List.fromList([
      ...'RIFF'.codeUnits,
      0,
      0,
      0,
      0,
      ...'WEBP'.codeUnits,
      0,
      0,
    ]);
    expect(detectImageMimeType(webp), 'image/webp');
  });

  test('no reconoce GIF, texto ni archivos vacíos', () {
    expect(detectImageMimeType(bytes('GIF89a'.codeUnits)), isNull);
    expect(detectImageMimeType(bytes('hola'.codeUnits)), isNull);
    expect(detectImageMimeType(Uint8List(0)), isNull);
  });
}
