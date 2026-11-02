import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Widget buildPage() {
    final router = GoRouter(
      initialLocation: AppRoutes.onboarding,
      routes: [
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, _) => const OnboardingPage(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Inicio')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('onboarding_next_button')));
    await tester.pumpAndSettle();
  }

  testWidgets('empieza en el primer paso con el botón Continuar', (tester) async {
    await tester.pumpWidget(buildPage());

    expect(find.text('Aquí también\nestás tú.'), findsOneWidget);
    expect(
      find.text(
        'Un espacio para acompañarte durante una etapa llena de cambios.',
      ),
      findsOneWidget,
    );
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Saltar'), findsOneWidget);
  });

  testWidgets('avanza por los tres pasos y termina con Comenzar', (tester) async {
    await tester.pumpWidget(buildPage());

    await next(tester);
    expect(find.text('Pequeños momentos\ntambién cuentan.'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);

    await next(tester);
    expect(find.text('No tienes que pedir\nayuda sola.'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);
    expect(find.text('Continuar'), findsNothing);

    await next(tester);
    expect(find.text('Pantalla Inicio'), findsOneWidget);
  });

  testWidgets('también se puede avanzar deslizando', (tester) async {
    await tester.pumpWidget(buildPage());

    await tester.drag(
      find.byKey(const Key('onboarding_pages')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pequeños momentos\ntambién cuentan.'), findsOneWidget);
  });

  testWidgets('Saltar lleva directo al inicio', (tester) async {
    await tester.pumpWidget(buildPage());

    await tester.tap(find.byKey(const Key('onboarding_skip_button')));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Inicio'), findsOneWidget);
  });
}
