import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/for_me/presentation/pages/for_me_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Widget buildPage() {
    final router = GoRouter(
      initialLocation: AppRoutes.forMe,
      routes: [
        GoRoute(
          path: AppRoutes.forMe,
          builder: (_, _) => const ForMePage(),
        ),
        GoRoute(
          path: AppRoutes.activities,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Actividades')),
        ),
        GoRoute(
          path: AppRoutes.savedActivities,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Guardadas')),
        ),
        GoRoute(
          path: AppRoutes.needs,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Necesidades')),
        ),
        GoRoute(
          path: AppRoutes.moodCheckin,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Check-in')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('muestra el título y las opciones de autocuidado', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('for_me_title')), findsOneWidget);
    expect(find.text('Para mí'), findsOneWidget);
    expect(find.text('Microdescansos'), findsOneWidget);
    expect(find.text('Actividades guardadas'), findsOneWidget);
    expect(find.text('«No sé qué necesito»'), findsOneWidget);
    expect(find.text('Check-in de bienestar'), findsOneWidget);
  });

  testWidgets('las tarjetas navegan a sus rutas respectivas', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('for_me_card_activities')));
    await tester.pumpAndSettle();
    expect(find.text('Pantalla Actividades'), findsOneWidget);

    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('for_me_card_saved')));
    await tester.pumpAndSettle();
    expect(find.text('Pantalla Guardadas'), findsOneWidget);

    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('for_me_card_needs')));
    await tester.pumpAndSettle();
    expect(find.text('Pantalla Necesidades'), findsOneWidget);

    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('for_me_card_checkin')));
    await tester.pumpAndSettle();
    expect(find.text('Pantalla Check-in'), findsOneWidget);
  });
}
