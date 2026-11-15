import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/support/presentation/pages/support_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  /// El resto del proyecto prueba a 390 x 844; el viewport por omisión de
  /// 800 x 600 no se parece a ningún teléfono y dejaba el botón de la hoja
  /// fuera de la pantalla.
  void useSmallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget buildPage() {
    final router = GoRouter(
      initialLocation: AppRoutes.support,
      routes: [
        GoRoute(
          path: AppRoutes.support,
          builder: (_, _) => const SupportPage(),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('muestra el título y las opciones de red de apoyo', (
    tester,
  ) async {
    useSmallPhone(tester);
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('support_title')), findsOneWidget);
    expect(find.text('Red de apoyo'), findsOneWidget);
    expect(find.text('Líneas de orientación y apoyo'), findsOneWidget);
    expect(find.text('Comunidad de madres'), findsOneWidget);
    expect(find.text('Tus personas de confianza'), findsOneWidget);
    expect(find.text('Próximamente'), findsOneWidget);
  });

  testWidgets('comunidad abre el modal de Próximamente', (tester) async {
    useSmallPhone(tester);
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('support_card_community')));
    await tester.pumpAndSettle();

    expect(find.text('Estamos preparando esto'), findsOneWidget);
    expect(find.byKey(const Key('coming_soon_ok_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('coming_soon_ok_button')));
    await tester.pumpAndSettle();
    expect(find.text('Estamos preparando esto'), findsNothing);
  });

  testWidgets('líneas de apoyo abre la información de orientación', (
    tester,
  ) async {
    useSmallPhone(tester);
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('support_card_helpline')));
    await tester.pumpAndSettle();

    expect(find.text('Líneas de orientación y escucha'), findsOneWidget);
    expect(find.text('Línea 106 (Colombia) — Salud mental y apoyo emocional'), findsOneWidget);
    expect(find.byKey(const Key('support_modal_ok_button')), findsOneWidget);

    // La hoja es más alta que la pantalla: hay que desplazarla.
    await tester.ensureVisible(
      find.byKey(const Key('support_modal_ok_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('support_modal_ok_button')));
    await tester.pumpAndSettle();
    expect(find.text('Líneas de orientación y escucha'), findsNothing);
  });
}
