import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/core/widgets/coming_soon.dart';
import 'package:doulapp/core/widgets/placeholder_page.dart';
import 'package:doulapp/features/activities/domain/entities/activity.dart';
import 'package:doulapp/features/activities/domain/entities/activity_modality.dart';
import 'package:doulapp/features/activities/presentation/bloc/activity_session_bloc.dart';
import 'package:doulapp/features/activities/presentation/bloc/activity_session_event.dart';
import 'package:doulapp/features/activities/presentation/bloc/activity_session_state.dart';
import 'package:doulapp/features/activities/presentation/bloc/saved_activities_bloc.dart';
import 'package:doulapp/features/activities/presentation/bloc/saved_activities_event.dart';
import 'package:doulapp/features/activities/presentation/bloc/saved_activities_state.dart';
import 'package:doulapp/features/activities/presentation/pages/activity_session_page.dart';
import 'package:doulapp/features/activities/presentation/pages/saved_activities_page.dart';
import 'package:doulapp/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:doulapp/features/auth/presentation/bloc/forgot_password_event.dart';
import 'package:doulapp/features/auth/presentation/bloc/forgot_password_state.dart';
import 'package:doulapp/features/auth/presentation/bloc/login_bloc.dart';
import 'package:doulapp/features/auth/presentation/bloc/login_event.dart';
import 'package:doulapp/features/auth/presentation/bloc/login_state.dart';
import 'package:doulapp/features/auth/presentation/bloc/register_bloc.dart';
import 'package:doulapp/features/auth/presentation/bloc/register_event.dart';
import 'package:doulapp/features/auth/presentation/bloc/register_state.dart';
import 'package:doulapp/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:doulapp/features/auth/presentation/pages/login_page.dart';
import 'package:doulapp/features/auth/presentation/pages/register_page.dart';
import 'package:doulapp/features/community/domain/entities/community_category.dart';
import 'package:doulapp/features/community/domain/entities/post.dart';
import 'package:doulapp/features/community/domain/entities/post_comment.dart';
import 'package:doulapp/features/community/domain/entities/post_type.dart';
import 'package:doulapp/features/community/domain/entities/post_visibility.dart';
import 'package:doulapp/features/community/presentation/bloc/create_post_bloc.dart';
import 'package:doulapp/features/community/presentation/bloc/create_post_event.dart';
import 'package:doulapp/features/community/presentation/bloc/create_post_state.dart';
import 'package:doulapp/features/community/presentation/bloc/feed_bloc.dart';
import 'package:doulapp/features/community/presentation/bloc/feed_event.dart';
import 'package:doulapp/features/community/presentation/bloc/feed_state.dart';
import 'package:doulapp/features/community/presentation/bloc/post_detail_bloc.dart';
import 'package:doulapp/features/community/presentation/bloc/post_detail_event.dart';
import 'package:doulapp/features/community/presentation/bloc/post_detail_state.dart';
import 'package:doulapp/features/community/presentation/pages/create_post_page.dart';
import 'package:doulapp/features/community/presentation/pages/feed_page.dart';
import 'package:doulapp/features/community/presentation/pages/post_detail_page.dart';
import 'package:doulapp/features/for_me/presentation/pages/for_me_page.dart';
import 'package:doulapp/features/home/presentation/pages/home_page.dart';
import 'package:doulapp/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:doulapp/features/profile/domain/entities/app_role.dart';
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
import 'package:doulapp/features/profile/presentation/pages/profile_page.dart';
import 'package:doulapp/features/splash/presentation/pages/splash_page.dart';
import 'package:doulapp/features/support/presentation/pages/support_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc {}

class MockRegisterBloc extends MockBloc<RegisterEvent, RegisterState>
    implements RegisterBloc {}

class MockForgotBloc extends MockBloc<ForgotPasswordEvent, ForgotPasswordState>
    implements ForgotPasswordBloc {}

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockAvatarBloc extends MockBloc<AvatarEvent, AvatarState>
    implements AvatarBloc {}

class MockEditProfileBloc extends MockBloc<EditProfileEvent, EditProfileState>
    implements EditProfileBloc {}

class MockActivitySessionBloc
    extends MockBloc<ActivitySessionEvent, ActivitySessionState>
    implements ActivitySessionBloc {}

class MockSavedActivitiesBloc
    extends MockBloc<SavedActivitiesEvent, SavedActivitiesState>
    implements SavedActivitiesBloc {}

class MockFeedBloc extends MockBloc<FeedEvent, FeedState> implements FeedBloc {}

class MockPostDetailBloc extends MockBloc<PostDetailEvent, PostDetailState>
    implements PostDetailBloc {}

class MockCreatePostBloc extends MockBloc<CreatePostEvent, CreatePostState>
    implements CreatePostBloc {}

/// Pinta cada pantalla en un teléfono de 390 × 844 y falla si algo se
/// desborda. La fuente de pruebas es más ancha que Inter, así que si cabe
/// aquí, cabe en el dispositivo.
void main() {
  final profile = Profile(
    id: 'uuid-1',
    displayName: 'Karla Mendoza',
    bio: 'Tomando un día a la vez.',
    accountStatus: AccountStatus.active,
    createdAt: DateTime.utc(2026, 2, 1),
    updatedAt: DateTime.utc(2026, 2, 1),
  );

  Future<void> pumpOnPhone(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('splash', (tester) async {
    await pumpOnPhone(
      tester,
      const SplashPage(nextRoute: '/', duration: Duration(hours: 1)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('login', (tester) async {
    final bloc = MockLoginBloc();
    when(() => bloc.state).thenReturn(const LoginInitial());
    await pumpOnPhone(
      tester,
      BlocProvider<LoginBloc>.value(value: bloc, child: const LoginPage()),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('registro con un error visible', (tester) async {
    final bloc = MockRegisterBloc();
    when(() => bloc.state).thenReturn(
      const RegisterFailure('Ese correo ya tiene una cuenta. Inicia sesión.'),
    );
    await pumpOnPhone(
      tester,
      BlocProvider<RegisterBloc>.value(
        value: bloc,
        child: const RegisterPage(),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('recuperar acceso', (tester) async {
    final bloc = MockForgotBloc();
    when(
      () => bloc.state,
    ).thenReturn(const ForgotPasswordSuccess('ana@icesi.edu.co'));
    await pumpOnPhone(
      tester,
      BlocProvider<ForgotPasswordBloc>.value(
        value: bloc,
        child: const ForgotPasswordPage(),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding', (tester) async {
    await pumpOnPhone(tester, const OnboardingPage());
    expect(tester.takeException(), isNull);
  });

  testWidgets('inicio', (tester) async {
    final bloc = MockProfileBloc();
    when(
      () => bloc.state,
    ).thenReturn(ProfileLoaded(profile: profile, email: 'karla@icesi.edu.co'));
    await pumpOnPhone(
      tester,
      BlocProvider<ProfileBloc>.value(value: bloc, child: const HomePage()),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('perfil', (tester) async {
    final bloc = MockProfileBloc();
    when(() => bloc.state).thenReturn(
      ProfileLoaded(
        profile: profile,
        email: 'karla@icesi.edu.co',
        roles: const [AppRole.user, AppRole.admin],
      ),
    );
    await pumpOnPhone(
      tester,
      BlocProvider<ProfileBloc>.value(value: bloc, child: const ProfilePage()),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('editar perfil con un error visible', (tester) async {
    final profileBloc = MockProfileBloc();
    final editBloc = MockEditProfileBloc();
    final avatarBloc = MockAvatarBloc();
    when(() => avatarBloc.state).thenReturn(const AvatarInitial());
    when(
      () => profileBloc.state,
    ).thenReturn(ProfileLoaded(profile: profile, email: 'karla@icesi.edu.co'));
    when(() => editBloc.state).thenReturn(
      const EditProfileFailure('El nombre puede tener hasta 100 caracteres.'),
    );
    await pumpOnPhone(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<ProfileBloc>.value(value: profileBloc),
          BlocProvider<EditProfileBloc>.value(value: editBloc),
          BlocProvider<AvatarBloc>.value(value: avatarBloc),
        ],
        child: const EditProfilePage(),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pestaña sin módulo', (tester) async {
    await pumpOnPhone(tester, const ComingSoonPage(title: 'Para mí'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pestaña Para mí', (tester) async {
    await pumpOnPhone(tester, const ForMePage());
    expect(tester.takeException(), isNull);
  });

  testWidgets('pestaña Red de apoyo', (tester) async {
    await pumpOnPhone(tester, const SupportPage());
    expect(tester.takeException(), isNull);
  });

  testWidgets('pantalla de placeholder de función', (tester) async {
    await pumpOnPhone(
      tester,
      const FeaturePlaceholderPage(
        title: 'Microdescansos',
        subtitle: 'Pausas breves para respirar y descansar.',
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sesión de microdescanso en curso (390×844)', (tester) async {
    final bloc = MockActivitySessionBloc();
    const activity = Activity(
      id: 'act-1',
      categoryId: 'cat-1',
      title: 'Respiración 4-7-8',
      description: 'Una pausa para bajar el ritmo.',
      contentText: 'Inhala en 4, sostén en 7 y exhala en 8.',
      modality: ActivityModality.practice,
      durationMinutes: 3,
    );
    when(() => bloc.state).thenReturn(
      const ActivitySessionActive(activity: activity, elapsedSeconds: 45),
    );
    await pumpOnPhone(
      tester,
      BlocProvider<ActivitySessionBloc>.value(
        value: bloc,
        child: const ActivitySessionPage(activity: activity),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('actividades guardadas (390×844)', (tester) async {
    final bloc = MockSavedActivitiesBloc();
    const activity = Activity(
      id: 'act-1',
      categoryId: 'cat-1',
      title: 'Respiración diafragmática',
      description: 'Una pausa para conectar con tu respiración.',
      modality: ActivityModality.practice,
      durationMinutes: 5,
    );
    when(() => bloc.state).thenReturn(
      const SavedActivitiesLoaded(activities: [activity], savedIds: {'act-1'}),
    );
    await pumpOnPhone(
      tester,
      BlocProvider<SavedActivitiesBloc>.value(
        value: bloc,
        child: const SavedActivitiesPage(),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  group('comunidad', () {
    const categories = [
      CommunityCategory(
        id: 'c1',
        name: 'Primeras semanas',
        slug: 'primeras-semanas',
      ),
      CommunityCategory(
        id: 'c2',
        name: 'Cuerpo y recuperación',
        slug: 'cuerpo',
      ),
      CommunityCategory(id: 'c3', name: 'Sueño y cansancio', slug: 'sueno'),
    ];
    final post = Post(
      id: 'p1',
      authorId: 'a1',
      authorName: 'María Fernanda de los Ángeles Rodríguez',
      type: PostType.experience,
      body: 'Le pedí a mi hermana que viniera dos tardes por semana. ' * 6,
      visibility: PostVisibility.community,
      createdAt: DateTime.utc(2026, 3, 3),
      categories: categories,
      reactionCount: 1280,
      commentCount: 342,
    );

    testWidgets('feed (390×844)', (tester) async {
      final bloc = MockFeedBloc();
      when(() => bloc.state).thenReturn(
        FeedLoaded(
          categories: categories,
          posts: [post, post],
          hasMore: true,
          isLoadingMore: true,
        ),
      );
      await pumpOnPhone(
        tester,
        BlocProvider<FeedBloc>.value(value: bloc, child: const FeedPage()),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('detalle de publicación (390×844)', (tester) async {
      final bloc = MockPostDetailBloc();
      when(() => bloc.state).thenReturn(
        PostDetailLoaded(
          post: post,
          comments: [
            PostComment(
              id: 'k1',
              postId: 'p1',
              authorId: 'a2',
              authorName: 'Alejandra Valentina Gómez Restrepo',
              body: 'Qué bueno que te diste ese espacio.',
              createdAt: DateTime.utc(2026, 3, 4),
            ),
            PostComment(
              id: 'k2',
              postId: 'p1',
              authorId: 'a3',
              parentCommentId: 'k1',
              body: 'Igual yo.',
              createdAt: DateTime.utc(2026, 3, 5),
            ),
          ],
        ),
      );
      await pumpOnPhone(
        tester,
        BlocProvider<PostDetailBloc>.value(
          value: bloc,
          child: const PostDetailPage(postId: 'p1'),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('escribir con un error visible (390×844)', (tester) async {
      final bloc = MockCreatePostBloc();
      when(() => bloc.state).thenReturn(
        const CreatePostState(
          status: CreatePostStatus.editing,
          categories: categories,
          selectedCategoryIds: {'c1', 'c3'},
          body: 'Hola',
          errorMessage:
              'Elige al menos una categoría para que otras madres te encuentren.',
        ),
      );
      await pumpOnPhone(
        tester,
        BlocProvider<CreatePostBloc>.value(
          value: bloc,
          child: const CreatePostPage(),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
