import 'package:doulapp/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('sin foto muestra las iniciales', (tester) async {
    await tester.pumpWidget(wrap(const ProfileAvatar(initials: 'KM')));

    expect(find.text('KM'), findsOneWidget);
    expect(find.byKey(const Key('profile_avatar_image')), findsNothing);
  });

  testWidgets('con foto usa la imagen', (tester) async {
    await tester.pumpWidget(
      wrap(const ProfileAvatar(initials: 'KM', avatarUrl: 'http://x/a.png')),
    );

    expect(find.byKey(const Key('profile_avatar_image')), findsOneWidget);
  });

  testWidgets('si la foto no carga vuelve a las iniciales', (tester) async {
    await tester.pumpWidget(
      wrap(const ProfileAvatar(initials: 'KM', avatarUrl: 'http://x/a.png')),
    );
    await tester.pumpAndSettle();

    // En pruebas la red devuelve error: debe verse el respaldo, sin excepción.
    expect(find.text('KM'), findsOneWidget);
  });

  test('initialsOf toma las dos primeras iniciales o D', () {
    expect(initialsOf('Karla Mendoza'), 'KM');
    expect(initialsOf('  camila '), 'C');
    expect(initialsOf('   '), 'D');
  });
}
