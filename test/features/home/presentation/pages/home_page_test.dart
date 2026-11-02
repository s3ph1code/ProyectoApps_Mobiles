import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/home/presentation/pages/home_page.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:doulapp/features/profile/domain/entities/profile.dart';
import 'package:doulapp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:doulapp/features/profile/presentation/bloc/profile_event.dart';
import 'package:doulapp/features/profile/presentation/bloc/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

void main() {
  late MockProfileBloc bloc;

  final profile = Profile(
    id: 'uuid-1',
    displayName: 'Karla Mendoza',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 2, 1),
    updatedAt: DateTime.utc(2026, 2, 1),
  );

  setUp(() => bloc = MockProfileBloc());

  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget buildPage() {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => BlocProvider<ProfileBloc>.value(
            value: bloc,
            child: const HomePage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.forMe,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Para mí')),
        ),
        GoRoute(
          path: AppRoutes.support,
          builder: (_, _) => const Scaffold(body: Text('Pantalla Apoyo')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('saluda con el primer nombre del perfil', (tester) async {
    useTallScreen(tester);
    when(() => bloc.state).thenReturn(
      ProfileLoaded(profile: profile, email: 'karla@icesi.edu.co'),
    );

    await tester.pumpWidget(buildPage());

    expect(find.text('Hola, Karla'), findsOneWidget);
    expect(find.text('¿Cómo estás hoy?'), findsOneWidget);
  });

  testWidgets('saluda sin nombre mientras el perfil carga', (tester) async {
    useTallScreen(tester);
    when(() => bloc.state).thenReturn(const ProfileLoading());

    await tester.pumpWidget(buildPage());

    expect(find.text('Hola'), findsOneWidget);
  });

  testWidgets('muestra la tarjeta destacada y las seis opciones', (tester) async {
    useTallScreen(tester);
    when(() => bloc.state).thenReturn(const ProfileLoading());

    await tester.pumpWidget(buildPage());

    expect(find.text('¿Tienes unos minutos\npara ti?'), findsOneWidget);
    expect(find.text('¿QUÉ NECESITAS HOY?'), findsOneWidget);
    for (final title in [
      'Para mí',
      'Red de apoyo',
      'Aprende sobre ti',
      'Historias reales',
      'Mi bienestar',
      'Recursos cerca de ti',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('Próximamente'), findsNWidgets(4));
  });

  testWidgets('Para mí y Red de apoyo abren sus pestañas', (tester) async {
    useTallScreen(tester);
    when(() => bloc.state).thenReturn(const ProfileLoading());

    await tester.pumpWidget(buildPage());
    await tester.tap(find.byKey(const Key('home_card_for_me')));
    await tester.pumpAndSettle();
    expect(find.text('Pantalla Para mí'), findsOneWidget);

    await tester.pumpWidget(buildPage());
    await tester.tap(find.byKey(const Key('home_card_support')));
    await tester.pumpAndSettle();
    expect(find.text('Pantalla Apoyo'), findsOneWidget);
  });

  testWidgets('las secciones Próximamente avisan sin navegar', (tester) async {
    useTallScreen(tester);
    when(() => bloc.state).thenReturn(const ProfileLoading());

    await tester.pumpWidget(buildPage());
    await tester.tap(find.byKey(const Key('home_card_learn')));
    await tester.pumpAndSettle();

    expect(find.text('Estamos preparando esto'), findsOneWidget);
    expect(
      find.text(
        'Esta sección estará disponible en una próxima versión de Doulapp.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('coming_soon_ok_button')));
    await tester.pumpAndSettle();

    expect(find.text('Estamos preparando esto'), findsNothing);
    expect(find.text('Hola'), findsOneWidget);
  });
}
