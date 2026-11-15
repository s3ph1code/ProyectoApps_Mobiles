import 'package:doulapp/features/activities/domain/entities/activity_modality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cada código de la base tiene su etiqueta en español', () {
    expect(ActivityModality.fromCode('read').label, 'Leer');
    expect(ActivityModality.fromCode('listen').label, 'Escuchar');
    expect(ActivityModality.fromCode('watch').label, 'Ver');
    expect(ActivityModality.fromCode('do').label, 'Hacer');
  });

  test('los códigos cubren exactamente los que acepta la migración', () {
    expect(ActivityModality.values.map((m) => m.code).toSet(), {
      'read',
      'listen',
      'watch',
      'do',
    });
  });

  test('un código desconocido no rompe la lista', () {
    expect(ActivityModality.fromCode('podcast'), ActivityModality.practice);
    expect(ActivityModality.fromCode('').label, isNotEmpty);
  });
}
