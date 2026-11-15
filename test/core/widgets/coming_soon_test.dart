import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/core/widgets/coming_soon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  void useSmallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Una pantalla desde la que se entra a la sección pendiente, como cuando
  /// una recomendación lleva al detalle de una actividad.
  Widget buildApp({required bool pushed}) {
    final router = GoRouter(
      initialLocation: '/origen',
      routes: [
        GoRoute(
          path: '/origen',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('ir'),
                onPressed: () => context.push('/pendiente'),
                child: const Text('Pantalla de origen'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/pendiente',
          builder: (_, _) => pushed
              ? const ComingSoonPage.pushed(title: 'Microdescanso')
              : const ComingSoonPage(title: 'Microdescanso'),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Inicio')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('como destino empujado permite volver a donde estaba', (t) async {
    useSmallPhone(t);

    await t.pumpWidget(buildApp(pushed: true));
    await t.tap(find.byKey(const Key('ir')));
    await t.pumpAndSettle();

    expect(find.text('Estamos preparando esto'), findsOneWidget);
    expect(find.text('Microdescanso'), findsOneWidget);

    await t.pageBack();
    await t.pumpAndSettle();

    expect(find.text('Pantalla de origen'), findsOneWidget);
  });

  testWidgets('como pestaña ofrece volver al inicio, sin flecha', (t) async {
    useSmallPhone(t);

    await t.pumpWidget(buildApp(pushed: false));
    await t.tap(find.byKey(const Key('ir')));
    await t.pumpAndSettle();

    expect(find.byType(BackButton), findsNothing);

    await t.tap(find.byKey(const Key('coming_soon_home_button')));
    await t.pumpAndSettle();

    expect(find.text('Pantalla Inicio'), findsOneWidget);
  });
}
