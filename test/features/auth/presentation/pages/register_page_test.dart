import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/presentation/bloc/register_bloc.dart';
import 'package:doulapp/features/auth/presentation/bloc/register_event.dart';
import 'package:doulapp/features/auth/presentation/bloc/register_state.dart';
import 'package:doulapp/features/auth/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockRegisterBloc extends MockBloc<RegisterEvent, RegisterState>
    implements RegisterBloc {}

void main() {
  late MockRegisterBloc bloc;

  const user = AuthUser(id: 'uuid-1', email: 'camila@icesi.edu.co');

  setUp(() {
    bloc = MockRegisterBloc();
  });

  Widget buildTestablePage(RegisterBloc registerBloc) {
    final router = GoRouter(
      initialLocation: AppRoutes.register,
      routes: [
        GoRoute(
          path: AppRoutes.register,
          builder: (_, _) => BlocProvider<RegisterBloc>.value(
            value: registerBloc,
            child: const RegisterPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const Scaffold(
            body: Center(child: Text('Pantalla Login')),
          ),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, _) => const Scaffold(
            body: Center(child: Text('Pantalla Onboarding')),
          ),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets(
    'renderiza el formulario de registro y envía RegisterSubmitted',
    (tester) async {
      when(() => bloc.state).thenReturn(const RegisterInitial());

      await tester.pumpWidget(buildTestablePage(bloc));

      expect(find.text('Crear tu cuenta'), findsOneWidget);
      expect(find.text('Crear mi cuenta'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        'camila@icesi.edu.co',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm_password_field')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pump();

      verify(
        () => bloc.add(
          const RegisterSubmitted(
            email: 'camila@icesi.edu.co',
            password: 'password123',
          ),
        ),
      ).called(1);
    },
  );

  testWidgets(
    'muestra advertencia comprensible si las contraseñas no coinciden',
    (tester) async {
      when(() => bloc.state).thenReturn(const RegisterInitial());

      await tester.pumpWidget(buildTestablePage(bloc));

      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        'camila@icesi.edu.co',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm_password_field')),
        'otraClave999',
      );

      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pump();

      expect(
        find.text(
          'Las contraseñas no coinciden. Revisa que ambas sean iguales.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'muestra el mensaje de error cuando el estado es RegisterFailure',
    (tester) async {
      final errorMessage = const EmailAlreadyRegisteredFailure().message;
      when(() => bloc.state).thenReturn(RegisterFailure(errorMessage));

      await tester.pumpWidget(buildTestablePage(bloc));

      expect(find.text(errorMessage), findsOneWidget);
    },
  );

  testWidgets(
    'navega a /onboarding cuando se emite RegisterSuccess',
    (tester) async {
      final controller = StreamController<RegisterState>.broadcast();
      addTearDown(controller.close);

      whenListen(
        bloc,
        controller.stream,
        initialState: const RegisterInitial(),
      );

      await tester.pumpWidget(buildTestablePage(bloc));

      controller.add(const RegisterSuccess(user));
      await tester.pumpAndSettle();

      expect(find.text('Pantalla Onboarding'), findsOneWidget);
    },
  );
}
