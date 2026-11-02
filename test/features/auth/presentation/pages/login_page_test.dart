import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/presentation/bloc/login_bloc.dart';
import 'package:doulapp/features/auth/presentation/bloc/login_event.dart';
import 'package:doulapp/features/auth/presentation/bloc/login_state.dart';
import 'package:doulapp/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc {}

void main() {
  late MockLoginBloc bloc;

  const user = AuthUser(id: 'uuid-1', email: 'camila@icesi.edu.co');

  setUp(() {
    bloc = MockLoginBloc();
  });

  Widget buildTestablePage(LoginBloc loginBloc) {
    final router = GoRouter(
      initialLocation: AppRoutes.login,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => BlocProvider<LoginBloc>.value(
            value: loginBloc,
            child: const LoginPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (_, _) => const Scaffold(
            body: Center(child: Text('Pantalla Registro')),
          ),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, _) => const Scaffold(
            body: Center(child: Text('Pantalla Recuperar')),
          ),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const Scaffold(
            body: Center(child: Text('Pantalla Perfil')),
          ),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets(
    'renderiza el formulario de inicio de sesión y envía LoginSubmitted',
    (tester) async {
      when(() => bloc.state).thenReturn(const LoginInitial());

      await tester.pumpWidget(buildTestablePage(bloc));

      expect(find.text('Bienvenida a Doulapp'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'camila@icesi.edu.co',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();

      verify(
        () => bloc.add(
          const LoginSubmitted(
            email: 'camila@icesi.edu.co',
            password: 'password123',
          ),
        ),
      ).called(1);
    },
  );

  testWidgets(
    'muestra el mensaje de error cuando el estado es LoginFailure',
    (tester) async {
      final errorMessage = const InvalidCredentialsFailure().message;
      when(() => bloc.state).thenReturn(LoginFailure(errorMessage));

      await tester.pumpWidget(buildTestablePage(bloc));

      expect(find.text(errorMessage), findsOneWidget);
    },
  );

  testWidgets(
    'navega a /profile cuando se emite LoginSuccess',
    (tester) async {
      final controller = StreamController<LoginState>.broadcast();
      addTearDown(controller.close);

      whenListen(
        bloc,
        controller.stream,
        initialState: const LoginInitial(),
      );

      await tester.pumpWidget(buildTestablePage(bloc));

      controller.add(const LoginSuccess(user));
      await tester.pumpAndSettle();

      expect(find.text('Pantalla Perfil'), findsOneWidget);
    },
  );

  testWidgets(
    'navega a /register al pulsar el botón de crear cuenta',
    (tester) async {
      when(() => bloc.state).thenReturn(const LoginInitial());

      await tester.pumpWidget(buildTestablePage(bloc));

      await tester.tap(find.byKey(const Key('login_to_register_button')));
      await tester.pumpAndSettle();

      expect(find.text('Pantalla Registro'), findsOneWidget);
    },
  );

  testWidgets('ofrece recuperar el acceso desde el inicio de sesión', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(const LoginInitial());

    await tester.pumpWidget(buildTestablePage(bloc));
    await tester.tap(find.byKey(const Key('login_to_forgot_button')));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Recuperar'), findsOneWidget);
  });
}
