import 'dart:async';

import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/core/router/session_notifier.dart';
import 'package:doulapp/core/widgets/app_shell.dart';
import 'package:doulapp/core/widgets/coming_soon.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  GoRoute page(String path, String text) => GoRoute(
        path: path,
        builder: (_, _) => Scaffold(body: Center(child: Text(text))),
      );

  GoRouter buildRouter({SessionNotifier? session}) {
    return GoRouter(
      initialLocation: AppRoutes.home,
      refreshListenable: session,
      redirect: session == null
          ? null
          : (_, state) => AppRouter.redirectFor(
                isAuthenticated: session.isAuthenticated,
                location: state.matchedLocation,
              ),
      routes: [
        page(AppRoutes.login, 'Pantalla Login'),
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => AppShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [page(AppRoutes.home, 'Pestaña Inicio')]),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.forMe,
                  builder: (_, _) => const ComingSoonPage(title: 'Para mí'),
                ),
              ],
            ),
            StatefulShellBranch(routes: [page(AppRoutes.support, 'Pestaña Apoyo')]),
            StatefulShellBranch(routes: [page(AppRoutes.profile, 'Pestaña Perfil')]),
          ],
        ),
      ],
    );
  }

  testWidgets('muestra las cuatro pestañas y abre Inicio', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    for (final label in ['Inicio', 'Para mí', 'Apoyo', 'Perfil']) {
      expect(find.byKey(Key('nav_$label')), findsOneWidget, reason: label);
    }
    expect(find.text('Pestaña Inicio'), findsOneWidget);
  });

  testWidgets('cambia de pestaña al tocar la navegación', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_Perfil')));
    await tester.pumpAndSettle();
    expect(find.text('Pestaña Perfil'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_Apoyo')));
    await tester.pumpAndSettle();
    expect(find.text('Pestaña Apoyo'), findsOneWidget);
  });

  testWidgets('una pestaña sin módulo explica que llegará pronto', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_Para mí')));
    await tester.pumpAndSettle();

    expect(find.text('Estamos preparando esto'), findsOneWidget);

    await tester.tap(find.byKey(const Key('coming_soon_home_button')));
    await tester.pumpAndSettle();
    expect(find.text('Pestaña Inicio'), findsOneWidget);
  });

  testWidgets('con sesión no se puede volver al login', (tester) async {
    final session = SessionNotifier(
      initialUser: const AuthUser(id: 'uuid-1', email: 'ana@icesi.edu.co'),
      changes: const Stream<AuthUser?>.empty(),
    );
    addTearDown(session.dispose);

    final router = buildRouter(session: session);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.go(AppRoutes.login);
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Login'), findsNothing);
    expect(find.text('Pestaña Inicio'), findsOneWidget);
  });

  testWidgets('al cerrarse la sesión el router lleva al login', (tester) async {
    final changes = StreamController<AuthUser?>();
    addTearDown(changes.close);
    final session = SessionNotifier(
      initialUser: const AuthUser(id: 'uuid-1', email: 'ana@icesi.edu.co'),
      changes: changes.stream,
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: buildRouter(session: session)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pestaña Inicio'), findsOneWidget);

    changes.add(null);
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Login'), findsOneWidget);
  });
}
