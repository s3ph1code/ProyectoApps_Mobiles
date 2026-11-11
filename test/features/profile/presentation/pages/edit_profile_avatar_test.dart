import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:doulapp/features/profile/domain/entities/avatar_image.dart';
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
import 'package:doulapp/features/profile/presentation/services/avatar_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockAvatarBloc extends MockBloc<AvatarEvent, AvatarState>
    implements AvatarBloc {}

class MockEditProfileBloc extends MockBloc<EditProfileEvent, EditProfileState>
    implements EditProfileBloc {}

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class FakePicker implements AvatarPicker {
  AvatarImage? result;
  Object? error;
  AvatarSource? lastSource;

  @override
  Future<AvatarImage?> pick(AvatarSource source) async {
    lastSource = source;
    if (error != null) throw error!;
    return result;
  }
}

void main() {
  late MockAvatarBloc avatarBloc;
  late MockEditProfileBloc editBloc;
  late MockProfileBloc profileBloc;
  late FakePicker picker;

  Profile makeProfile({String? avatarUrl}) => Profile(
    id: 'u',
    displayName: 'Camila',
    avatarUrl: avatarUrl,
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 2, 1),
    updatedAt: DateTime.utc(2026, 2, 1),
  );

  final image = AvatarImage(
    bytes: Uint8List.fromList([1, 2, 3]),
    mimeType: 'image/png',
  );

  setUpAll(() {
    registerFallbackValue(const ProfileLoadRequested());
    registerFallbackValue(AvatarRemoveRequested(_placeholder));
    registerFallbackValue(
      EditProfileSubmitted(profile: _placeholder, displayName: ''),
    );
  });

  setUp(() {
    avatarBloc = MockAvatarBloc();
    editBloc = MockEditProfileBloc();
    profileBloc = MockProfileBloc();
    picker = FakePicker();
    when(() => avatarBloc.state).thenReturn(const AvatarInitial());
    when(() => editBloc.state).thenReturn(const EditProfileInitial());
    when(() => profileBloc.isClosed).thenReturn(false);
  });

  void useProfile(Profile profile) => when(
    () => profileBloc.state,
  ).thenReturn(ProfileLoaded(profile: profile, email: 'c@icesi.edu.co'));

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget buildPage() {
    final router = GoRouter(
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
                child: EditProfilePage(picker: picker),
              ),
            ),
          ],
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  Future<void> chooseGallery(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('edit_profile_change_photo_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('avatar_source_gallery')));
    await tester.pumpAndSettle();
  }

  testWidgets('sin foto ofrece agregarla y no muestra «Quitar foto»', (
    tester,
  ) async {
    usePhone(tester);
    useProfile(makeProfile());
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.text('Agregar foto'), findsOneWidget);
    expect(
      find.byKey(const Key('edit_profile_remove_photo_button')),
      findsNothing,
    );
    expect(find.text('C'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con foto ofrece cambiarla o quitarla', (tester) async {
    usePhone(tester);
    useProfile(makeProfile(avatarUrl: 'http://x/avatars/u/1.png'));
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.text('Cambiar foto'), findsOneWidget);
    expect(
      find.byKey(const Key('edit_profile_remove_photo_button')),
      findsOneWidget,
    );
  });

  testWidgets('elegir de la galería sube la imagen al BLoC', (tester) async {
    usePhone(tester);
    final profile = makeProfile();
    useProfile(profile);
    picker.result = image;
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await chooseGallery(tester);

    expect(picker.lastSource, AvatarSource.gallery);
    verify(
      () =>
          avatarBloc.add(AvatarUploadRequested(profile: profile, image: image)),
    ).called(1);
  });

  testWidgets('cerrar el selector sin elegir no sube nada', (tester) async {
    usePhone(tester);
    useProfile(makeProfile());
    picker.result = null;
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await chooseGallery(tester);

    verifyNever(() => avatarBloc.add(any()));
  });

  testWidgets('si no se puede abrir la galería avisa con claridad', (
    tester,
  ) async {
    usePhone(tester);
    useProfile(makeProfile());
    picker.error = Exception('permiso denegado');
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await chooseGallery(tester);

    expect(find.textContaining('No pudimos abrir tus fotos'), findsOneWidget);
    verifyNever(() => avatarBloc.add(any()));
  });

  testWidgets('quitar la foto lo envía al BLoC', (tester) async {
    usePhone(tester);
    final profile = makeProfile(avatarUrl: 'http://x/avatars/u/1.png');
    useProfile(profile);
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit_profile_remove_photo_button')));

    verify(() => avatarBloc.add(AvatarRemoveRequested(profile))).called(1);
  });

  testWidgets('mientras sube muestra progreso y bloquea los botones', (
    tester,
  ) async {
    usePhone(tester);
    useProfile(makeProfile());
    when(() => avatarBloc.state).thenReturn(const AvatarWorking());
    await tester.pumpWidget(buildPage());
    await tester.pump();

    expect(
      find.byKey(const Key('edit_profile_avatar_loading')),
      findsOneWidget,
    );
    final button = tester.widget<TextButton>(
      find.byKey(const Key('edit_profile_change_photo_button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('si la imagen no cumple muestra el aviso y conserva la foto', (
    tester,
  ) async {
    usePhone(tester);
    useProfile(makeProfile(avatarUrl: 'http://x/avatars/u/1.png'));
    when(() => avatarBloc.state).thenReturn(
      const AvatarFailure('La foto pesa más de 2 MB. Elige una más liviana.'),
    );
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit_profile_avatar_error')), findsOneWidget);
    expect(find.textContaining('más de 2 MB'), findsOneWidget);
    expect(find.text('Cambiar foto'), findsOneWidget);
  });

  testWidgets('tras un error de red «Reintentar» vuelve a subir la imagen', (
    tester,
  ) async {
    usePhone(tester);
    final profile = makeProfile();
    useProfile(profile);
    picker.result = image;
    final states = StreamController<AvatarState>.broadcast();
    addTearDown(states.close);
    whenListen(avatarBloc, states.stream, initialState: const AvatarInitial());
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();
    await chooseGallery(tester);
    clearInteractions(avatarBloc);

    states.add(const AvatarFailure('No hay conexión.'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit_profile_avatar_retry_button')));

    verify(
      () =>
          avatarBloc.add(AvatarUploadRequested(profile: profile, image: image)),
    ).called(1);
  });

  testWidgets('guardar el nombre después de cambiar la foto no la pisa', (
    tester,
  ) async {
    usePhone(tester);
    final updated = makeProfile(avatarUrl: 'http://x/avatars/u/2.png');
    useProfile(makeProfile());
    whenListen(
      avatarBloc,
      Stream.value(AvatarSuccess(updated)),
      initialState: const AvatarInitial(),
    );
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('edit_profile_save_button')),
    );
    await tester.tap(find.byKey(const Key('edit_profile_save_button')));
    await tester.pump();

    verify(
      () => editBloc.add(
        EditProfileSubmitted(profile: updated, displayName: 'Camila', bio: ''),
      ),
    ).called(1);
  });

  testWidgets('si solo cambió la foto y se cancela, el perfil se recarga', (
    tester,
  ) async {
    usePhone(tester);
    useProfile(makeProfile());
    whenListen(
      avatarBloc,
      Stream.value(AvatarSuccess(makeProfile(avatarUrl: 'http://x/a.png'))),
      initialState: const AvatarInitial(),
    );
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();
    verifyNever(() => profileBloc.add(any()));

    await tester.ensureVisible(
      find.byKey(const Key('edit_profile_cancel_button')),
    );
    await tester.tap(find.byKey(const Key('edit_profile_cancel_button')));
    await tester.pumpAndSettle();

    verify(() => profileBloc.add(const ProfileLoadRequested())).called(1);
  });

  testWidgets('sin cambios de foto, salir no recarga el perfil', (
    tester,
  ) async {
    usePhone(tester);
    useProfile(makeProfile());
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('edit_profile_cancel_button')),
    );
    await tester.tap(find.byKey(const Key('edit_profile_cancel_button')));
    await tester.pumpAndSettle();

    verifyNever(() => profileBloc.add(any()));
  });
}

final _placeholder = Profile(
  id: 'p',
  displayName: 'p',
  accountStatus: AccountStatus.active,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
