import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:doulapp/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:doulapp/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:doulapp/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:doulapp/features/profile/domain/entities/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockOnboardingBloc extends MockBloc<OnboardingEvent, OnboardingState>
    implements OnboardingBloc {}

void main() {
  late MockOnboardingBloc bloc;

  final sampleProfile = Profile(
    id: 'uuid-1',
    displayName: 'Camila',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 2, 1),
    updatedAt: DateTime.utc(2026, 2, 1),
  );

  setUp(() {
    bloc = MockOnboardingBloc();
  });

  Widget buildTestablePage(OnboardingBloc onboardingBloc) {
    final router = GoRouter(
      initialLocation: AppRoutes.onboarding,
      routes: [
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, _) => BlocProvider<OnboardingBloc>.value(
            value: onboardingBloc,
            child: const OnboardingPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const Scaffold(
            body: Center(child: Text('Pantalla Perfil')),
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
    'renderiza el onboarding, permite cambiar diapositiva y envía OnboardingSubmitted',
    (tester) async {
      when(() => bloc.state).thenReturn(const OnboardingInitial());

      await tester.pumpWidget(buildTestablePage(bloc));

      expect(find.text('Aquí también estás tú.'), findsOneWidget);
      expect(find.text('¿Cómo quieres que te llamemos?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_slide_card')));
      await tester.pumpAndSettle();

      expect(find.text('Pequeños momentos también cuentan.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('onboarding_name_field')),
        'Camila',
      );
      await tester.tap(find.byKey(const Key('onboarding_submit_button')));
      await tester.pump();

      verify(
        () => bloc.add(const OnboardingSubmitted(displayName: 'Camila')),
      ).called(1);
    },
  );

  testWidgets(
    'muestra el mensaje de error cuando el estado es OnboardingFailure',
    (tester) async {
      const errorMessage = 'Escribe cómo te gustaría que te llamemos.';
      when(() => bloc.state).thenReturn(const OnboardingFailure(errorMessage));

      await tester.pumpWidget(buildTestablePage(bloc));

      expect(find.text(errorMessage), findsOneWidget);
    },
  );

  testWidgets(
    'navega a /profile cuando se emite OnboardingSuccess',
    (tester) async {
      final controller = StreamController<OnboardingState>.broadcast();
      addTearDown(controller.close);

      whenListen(
        bloc,
        controller.stream,
        initialState: const OnboardingInitial(),
      );

      await tester.pumpWidget(buildTestablePage(bloc));

      controller.add(OnboardingSuccess(sampleProfile));
      await tester.pumpAndSettle();

      expect(find.text('Pantalla Perfil'), findsOneWidget);
    },
  );
}
