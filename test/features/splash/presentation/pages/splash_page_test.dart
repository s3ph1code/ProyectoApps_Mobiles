import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/splash/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Widget buildPage({required String nextRoute}) {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, _) => SplashPage(
            nextRoute: nextRoute,
            duration: const Duration(milliseconds: 500),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Login')),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Perfil')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('muestra la marca y el lema de Doulapp', (tester) async {
    await tester.pumpWidget(buildPage(nextRoute: AppRoutes.login));

    expect(find.text('doulapp'), findsOneWidget);
    expect(find.text('Tu bienestar también importa.'), findsOneWidget);
    expect(
      find.text('Acompañamiento posparto, sin prejuicios.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('pasa solo a la pantalla indicada', (tester) async {
    await tester.pumpWidget(buildPage(nextRoute: AppRoutes.profile));

    expect(find.text('Pantalla Perfil'), findsNothing);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Perfil'), findsOneWidget);
  });

  testWidgets('también continúa al tocar la pantalla', (tester) async {
    await tester.pumpWidget(buildPage(nextRoute: AppRoutes.login));

    await tester.tap(find.byKey(const Key('splash_area')));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Login'), findsOneWidget);
  });
}
