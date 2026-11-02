import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:doulapp/features/profile/domain/entities/app_role.dart';
import 'package:doulapp/features/profile/domain/entities/profile.dart';
import 'package:doulapp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:doulapp/features/profile/presentation/bloc/profile_event.dart';
import 'package:doulapp/features/profile/presentation/bloc/profile_state.dart';
import 'package:doulapp/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

void main() {
  late MockProfileBloc bloc;

  final sampleProfile = Profile(
    id: 'uuid-1',
    displayName: 'Camila',
    bio: 'Tomando un día a la vez.',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 2, 1),
    updatedAt: DateTime.utc(2026, 2, 1),
  );

  setUp(() {
    bloc = MockProfileBloc();
  });

  Widget buildTestablePage(ProfileBloc profileBloc) {
    final router = GoRouter(
      initialLocation: AppRoutes.profile,
      routes: [
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => BlocProvider<ProfileBloc>.value(
            value: profileBloc,
            child: const ProfilePage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const Scaffold(
            body: Center(child: Text('Pantalla Login')),
          ),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets(
    'muestra el resumen del perfil con iniciales, rol y privacidad',
    (tester) async {
      useTallScreen(tester);
      when(() => bloc.state).thenReturn(
        ProfileLoaded(
          profile: sampleProfile,
          email: 'camila@icesi.edu.co',
          roles: const [AppRole.user, AppRole.moderator],
        ),
      );

      await tester.pumpWidget(buildTestablePage(bloc));

      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Camila'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('Tu espacio personal'), findsOneWidget);
      expect(find.text('Moderadora'), findsOneWidget);
      expect(find.text('Privacidad'), findsOneWidget);
      expect(
        find.text('Tú decides qué se comparte y con quién.'),
        findsOneWidget,
      );
      expect(find.text('Tu red solo ve lo que tú envías'), findsOneWidget);
      expect(find.text('Doulapp · versión 1.0'), findsOneWidget);
    },
  );

  testWidgets('no muestra la etiqueta de rol si no se pudo consultar', (
    tester,
  ) async {
    useTallScreen(tester);
    when(() => bloc.state).thenReturn(
      ProfileLoaded(profile: sampleProfile, email: 'camila@icesi.edu.co'),
    );

    await tester.pumpWidget(buildTestablePage(bloc));

    expect(find.byKey(const Key('profile_role_chip')), findsNothing);
  });

  testWidgets('Mi información muestra los datos de la cuenta', (tester) async {
    useTallScreen(tester);
    when(() => bloc.state).thenReturn(
      ProfileLoaded(
        profile: sampleProfile,
        email: 'camila@icesi.edu.co',
        roles: const [AppRole.user],
      ),
    );

    await tester.pumpWidget(buildTestablePage(bloc));
    await tester.tap(find.byKey(const Key('profile_row_info')));
    await tester.pumpAndSettle();

    expect(find.text('Mi información'), findsNWidgets(2));
    expect(find.text('camila@icesi.edu.co'), findsOneWidget);
    expect(find.text('Usuaria'), findsNWidgets(2));
    expect(find.text('Activa'), findsOneWidget);
    expect(find.text('1 de febrero de 2026'), findsOneWidget);
    expect(find.text('Tomando un día a la vez.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('account_info_close_button')));
    await tester.pumpAndSettle();

    expect(find.text('camila@icesi.edu.co'), findsNothing);
  });

  testWidgets('las opciones que aún no existen avisan sin navegar', (
    tester,
  ) async {
    useTallScreen(tester);
    when(() => bloc.state).thenReturn(
      ProfileLoaded(profile: sampleProfile, email: 'camila@icesi.edu.co'),
    );

    await tester.pumpWidget(buildTestablePage(bloc));

    for (final key in [
      'profile_privacy_button',
      'profile_row_network',
      'profile_row_notifications',
      'profile_row_help',
    ]) {
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      expect(find.text('Estamos preparando esto'), findsOneWidget, reason: key);

      await tester.tap(find.byKey(const Key('coming_soon_ok_button')));
      await tester.pumpAndSettle();
    }

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Pantalla Login'), findsNothing);
  });

  group('initialsOf', () {
    test('toma la inicial de las dos primeras palabras', () {
      expect(initialsOf('Karla Mendoza'), 'KM');
      expect(initialsOf('  ana maría  gómez '), 'AM');
    });

    test('con una sola palabra usa una inicial', () {
      expect(initialsOf('Camila'), 'C');
    });

    test('con nombre vacío usa la D de Doulapp', () {
      expect(initialsOf('   '), 'D');
    });
  });

  test('formatDate escribe la fecha en español', () {
    expect(formatDate(DateTime.utc(2026, 11, 2)), '2 de noviembre de 2026');
  });

  testWidgets(
    'muestra el mensaje de error y permite reintentar la carga',
    (tester) async {
      final errorMessage = const NetworkFailure().message;
      when(() => bloc.state).thenReturn(ProfileFailure(errorMessage));

      await tester.pumpWidget(buildTestablePage(bloc));

      expect(find.text(errorMessage), findsOneWidget);

      await tester.tap(find.text('Volver a intentar'));
      await tester.pump();

      verify(() => bloc.add(const ProfileLoadRequested())).called(1);
    },
  );

  testWidgets(
    'navega a /login cuando se emite ProfileSignedOut',
    (tester) async {
      useTallScreen(tester);
      final controller = StreamController<ProfileState>.broadcast();
      addTearDown(controller.close);

      when(() => bloc.state).thenReturn(
        ProfileLoaded(profile: sampleProfile, email: 'camila@icesi.edu.co'),
      );
      whenListen(bloc, controller.stream);

      await tester.pumpWidget(buildTestablePage(bloc));

      await tester.tap(find.text('Cerrar sesión'));
      verify(() => bloc.add(const ProfileSignOutRequested())).called(1);

      controller.add(const ProfileSignedOut());
      await tester.pumpAndSettle();

      expect(find.text('Pantalla Login'), findsOneWidget);
    },
  );
}
