import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:doulapp/features/auth/presentation/bloc/forgot_password_event.dart';
import 'package:doulapp/features/auth/presentation/bloc/forgot_password_state.dart';
import 'package:doulapp/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockForgotPasswordBloc
    extends MockBloc<ForgotPasswordEvent, ForgotPasswordState>
    implements ForgotPasswordBloc {}

void main() {
  late MockForgotPasswordBloc bloc;

  setUpAll(() {
    registerFallbackValue(const ForgotPasswordSubmitted(email: ''));
  });

  setUp(() => bloc = MockForgotPasswordBloc());

  Widget buildPage() {
    final router = GoRouter(
      initialLocation: AppRoutes.forgotPassword,
      routes: [
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, _) => BlocProvider<ForgotPasswordBloc>.value(
            value: bloc,
            child: const ForgotPasswordPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Login')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('envía el correo escrito', (tester) async {
    when(() => bloc.state).thenReturn(const ForgotPasswordInitial());

    await tester.pumpWidget(buildPage());

    expect(find.text('Recuperar acceso'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('forgot_email_field')),
      'camila@icesi.edu.co',
    );
    await tester.tap(find.byKey(const Key('forgot_submit_button')));
    await tester.pump();

    verify(
      () => bloc.add(
        const ForgotPasswordSubmitted(email: 'camila@icesi.edu.co'),
      ),
    ).called(1);
  });

  testWidgets('confirma el envío sin revelar si la cuenta existe', (
    tester,
  ) async {
    when(() => bloc.state)
        .thenReturn(const ForgotPasswordSuccess('camila@icesi.edu.co'));

    await tester.pumpWidget(buildPage());

    expect(
      find.textContaining('Si camila@icesi.edu.co tiene una cuenta'),
      findsOneWidget,
    );
    expect(find.text('Enviar de nuevo'), findsOneWidget);
  });

  testWidgets('muestra el mensaje de error', (tester) async {
    when(() => bloc.state)
        .thenReturn(const ForgotPasswordFailure('Ese correo no es válido.'));

    await tester.pumpWidget(buildPage());

    expect(find.text('Ese correo no es válido.'), findsOneWidget);
  });

  testWidgets('permite volver al inicio de sesión', (tester) async {
    when(() => bloc.state).thenReturn(const ForgotPasswordInitial());

    await tester.pumpWidget(buildPage());
    await tester.tap(find.byKey(const Key('forgot_to_login_button')));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Login'), findsOneWidget);
  });
}
