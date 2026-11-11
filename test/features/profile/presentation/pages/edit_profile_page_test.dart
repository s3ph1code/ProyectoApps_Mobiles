import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:doulapp/features/profile/domain/entities/profile.dart';
import 'package:doulapp/features/profile/presentation/bloc/avatar_bloc.dart';
import 'package:doulapp/features/profile/presentation/bloc/avatar_event.dart';
import 'package:doulapp/features/profile/presentation/bloc/avatar_state.dart';
import 'package:doulapp/features/profile/presentation/bloc/edit_profile_bloc.dart';
import 'package:doulapp/features/profile/presentation/bloc/edit_profile_event.dart';
import 'package:doulapp/features/profile/presentation/bloc/edit_profile_state.dart';
import 'package:doulapp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:doulapp/features/profile/presentation/bloc/profile_event.dart';
import 'package:doulapp/features/profile/presentation/bloc/profile_state.dart';
import 'package:doulapp/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockEditProfileBloc extends MockBloc<EditProfileEvent, EditProfileState>
    implements EditProfileBloc {}

class MockAvatarBloc extends MockBloc<AvatarEvent, AvatarState>
    implements AvatarBloc {}

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

void main() {
  late MockEditProfileBloc editBloc;
  late MockProfileBloc profileBloc;
  late MockAvatarBloc avatarBloc;

  final profile = Profile(
    id: 'uuid-1',
    displayName: 'Camila',
    bio: 'Tomando un día a la vez.',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 2, 1),
    updatedAt: DateTime.utc(2026, 2, 1),
  );

  setUpAll(() {
    registerFallbackValue(const ProfileLoadRequested());
    registerFallbackValue(
      EditProfileSubmitted(profile: profile, displayName: ''),
    );
  });

  setUp(() {
    editBloc = MockEditProfileBloc();
    profileBloc = MockProfileBloc();
    avatarBloc = MockAvatarBloc();
    when(() => avatarBloc.state).thenReturn(const AvatarInitial());
    when(() => editBloc.state).thenReturn(const EditProfileInitial());
    when(
      () => profileBloc.state,
    ).thenReturn(ProfileLoaded(profile: profile, email: 'camila@icesi.edu.co'));
  });

  Widget buildPage() {
    final router = GoRouter(
      // Arranca en la edición: go_router apila el resumen debajo, así que
      // volver tiene a dónde ir.
      initialLocation: AppRoutes.editProfile,
      routes: [
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const Scaffold(body: Text('Resumen del perfil')),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, _) => MultiBlocProvider(
                providers: [
                  BlocProvider<ProfileBloc>.value(value: profileBloc),
                  BlocProvider<EditProfileBloc>.value(value: editBloc),
                  BlocProvider<AvatarBloc>.value(value: avatarBloc),
                ],
                child: const EditProfilePage(),
              ),
            ),
          ],
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('muestra el nombre y la bio actuales', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.text('Camila'), findsOneWidget);
    expect(find.text('Tomando un día a la vez.'), findsOneWidget);
  });

  testWidgets('al guardar envía lo escrito al BLoC', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('edit_profile_name_field')),
      'Camila Ríos',
    );
    await tester.enterText(
      find.byKey(const Key('edit_profile_bio_field')),
      'Nueva bio',
    );
    await tester.ensureVisible(find.byKey(const Key('edit_profile_save_button')));
    await tester.tap(find.byKey(const Key('edit_profile_save_button')));
    await tester.pump();

    verify(
      () => editBloc.add(
        EditProfileSubmitted(
          profile: profile,
          displayName: 'Camila Ríos',
          bio: 'Nueva bio',
        ),
      ),
    ).called(1);
  });

  testWidgets('mientras guarda deshabilita el botón y los campos', (
    tester,
  ) async {
    when(() => editBloc.state).thenReturn(const EditProfileSaving());

    await tester.pumpWidget(buildPage());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final save = tester.widget<ElevatedButton>(
      find.byKey(const Key('edit_profile_save_button')),
    );
    expect(save.onPressed, isNull);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('edit_profile_name_field')))
          .enabled,
      isFalse,
    );
  });

  testWidgets('si falla, muestra el mensaje y conserva lo escrito', (
    tester,
  ) async {
    whenListen(
      editBloc,
      Stream.fromIterable([const EditProfileFailure('No hay conexión.')]),
      initialState: const EditProfileInitial(),
    );

    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('edit_profile_name_field')),
      'Otro nombre',
    );
    editBloc.emit(const EditProfileFailure('No hay conexión.'));
    await tester.pumpAndSettle();

    expect(find.text('No hay conexión.'), findsOneWidget);
    expect(find.text('Otro nombre'), findsOneWidget);
  });

  testWidgets('al guardar con éxito recarga el perfil y vuelve', (
    tester,
  ) async {
    whenListen(
      editBloc,
      Stream.fromIterable([EditProfileSuccess(profile)]),
      initialState: const EditProfileInitial(),
    );

    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    verify(() => profileBloc.add(const ProfileLoadRequested())).called(1);
    expect(find.text('Resumen del perfil'), findsOneWidget);
    expect(find.byType(EditProfilePage), findsNothing);
  });

  testWidgets('cancelar vuelve sin guardar', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('edit_profile_cancel_button')),
    );
    await tester.tap(find.byKey(const Key('edit_profile_cancel_button')));
    await tester.pumpAndSettle();

    expect(find.text('Resumen del perfil'), findsOneWidget);
    verifyNever(() => editBloc.add(any()));
  });
}
