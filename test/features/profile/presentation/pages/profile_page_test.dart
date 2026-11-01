import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
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

  testWidgets(
    'muestra el resumen del perfil y las secciones marcadas como Próximamente sin navegar',
    (tester) async {
      when(() => bloc.state).thenReturn(
        ProfileLoaded(profile: sampleProfile, email: 'camila@icesi.edu.co'),
      );

      await tester.pumpWidget(buildTestablePage(bloc));

      expect(find.text('Tu espacio'), findsOneWidget);
      expect(find.text('Camila'), findsOneWidget);
      expect(find.text('camila@icesi.edu.co'), findsOneWidget);
      expect(find.text('Tomando un día a la vez.'), findsOneWidget);
      expect(find.text('Próximamente'), findsNWidgets(4));

      await tester.tap(find.text('Microdescansos'));
      await tester.pumpAndSettle();

      expect(find.text('Tu espacio'), findsOneWidget);
      expect(find.text('Pantalla Login'), findsNothing);
    },
  );

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
