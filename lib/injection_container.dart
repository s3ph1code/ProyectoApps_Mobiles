import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/router/session_notifier.dart';
import 'core/usecase/usecase.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/send_password_reset.dart';
import 'features/auth/domain/usecases/sign_in_with_email.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up_with_email.dart';
import 'features/auth/domain/usecases/watch_auth_state.dart';
import 'features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'features/auth/presentation/bloc/login_bloc.dart';
import 'features/auth/presentation/bloc/register_bloc.dart';
import 'features/community/data/datasources/community_remote_datasource.dart';
import 'features/community/data/repositories/community_repository_impl.dart';
import 'features/community/domain/repositories/community_repository.dart';
import 'features/community/domain/usecases/create_post.dart';
import 'features/community/domain/usecases/get_community_categories.dart';
import 'features/community/domain/usecases/get_post_by_id.dart';
import 'features/community/domain/usecases/get_post_comments.dart';
import 'features/community/domain/usecases/get_posts.dart';
import 'features/community/presentation/bloc/create_post_bloc.dart';
import 'features/community/presentation/bloc/feed_bloc.dart';
import 'features/community/presentation/bloc/post_detail_bloc.dart';
import 'features/preferences/data/datasources/preferences_remote_datasource.dart';
import 'features/preferences/data/repositories/preferences_repository_impl.dart';
import 'features/preferences/domain/repositories/preferences_repository.dart';
import 'features/preferences/domain/usecases/get_preferences.dart';
import 'features/preferences/domain/usecases/update_preferences.dart';
import 'features/preferences/presentation/bloc/preferences_bloc.dart';
import 'features/profile/data/datasources/profile_remote_datasource.dart';
import 'features/activities/data/datasources/activities_remote_datasource.dart';
import 'features/activities/data/repositories/activities_repository_impl.dart';
import 'features/activities/domain/repositories/activities_repository.dart';
import 'features/activities/domain/usecases/abandon_activity_session.dart';
import 'features/activities/domain/usecases/finish_activity_session.dart';
import 'features/activities/domain/usecases/get_activities.dart';
import 'features/activities/domain/usecases/get_activity_by_id.dart';
import 'features/activities/domain/usecases/get_activity_categories.dart';
import 'features/activities/domain/usecases/get_saved_activities.dart';
import 'features/activities/domain/usecases/save_activity.dart';
import 'features/activities/domain/usecases/start_activity_session.dart';
import 'features/activities/domain/usecases/unsave_activity.dart';
import 'features/activities/presentation/bloc/activities_bloc.dart';
import 'features/activities/presentation/bloc/activity_detail_bloc.dart';
import 'features/activities/presentation/bloc/activity_session_bloc.dart';
import 'features/activities/presentation/bloc/saved_activities_bloc.dart';
import 'features/activities/presentation/services/link_opener.dart';
import 'features/wellbeing/data/datasources/mood_remote_datasource.dart';
import 'features/wellbeing/data/datasources/needs_remote_datasource.dart';
import 'features/wellbeing/data/repositories/mood_repository_impl.dart';
import 'features/wellbeing/data/repositories/needs_repository_impl.dart';
import 'features/wellbeing/domain/repositories/mood_repository.dart';
import 'features/wellbeing/domain/repositories/needs_repository.dart';
import 'features/wellbeing/domain/usecases/get_mood_history.dart';
import 'features/wellbeing/domain/usecases/get_need_options.dart';
import 'features/wellbeing/domain/usecases/get_recommendations.dart';
import 'features/wellbeing/domain/usecases/save_mood_checkin.dart';
import 'features/wellbeing/domain/usecases/save_need_session.dart';
import 'features/wellbeing/presentation/bloc/mood_checkin_bloc.dart';
import 'features/wellbeing/presentation/bloc/mood_history_bloc.dart';
import 'features/wellbeing/presentation/bloc/needs_bloc.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/domain/usecases/create_profile.dart';
import 'features/profile/domain/usecases/get_profile.dart';
import 'features/profile/domain/usecases/get_user_roles.dart';
import 'features/profile/domain/usecases/remove_avatar.dart';
import 'features/profile/domain/usecases/update_profile.dart';
import 'features/profile/domain/usecases/upload_avatar.dart';
import 'features/profile/presentation/bloc/avatar_bloc.dart';
import 'features/profile/presentation/bloc/edit_profile_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerLazySingleton<SupabaseClient>(() => SupabaseConfig.client);

  _registerAuth();
  _registerProfile();
  _registerPreferences();
  _registerWellbeing();
  _registerActivities();
  _registerCommunity();

  // La sesión que Supabase restauró al arrancar decide la primera pantalla.
  final current = await sl<GetCurrentUser>()(const NoParams());
  sl.registerLazySingleton(
    () => SessionNotifier(
      initialUser: current.fold((_) => null, (user) => user),
      changes: sl<WatchAuthState>()(const NoParams()),
    ),
  );
}

void _registerAuth() {
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => SignUpWithEmail(sl()));
  sl.registerLazySingleton(() => SignInWithEmail(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => WatchAuthState(sl()));
  sl.registerLazySingleton(() => SendPasswordReset(sl()));

  sl.registerFactory(() => LoginBloc(signIn: sl()));
  sl.registerFactory(() => RegisterBloc(signUp: sl()));
  sl.registerFactory(() => ForgotPasswordBloc(sendPasswordReset: sl()));
}

void _registerProfile() {
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => CreateProfile(sl()));
  sl.registerLazySingleton(() => GetProfile(sl()));
  sl.registerLazySingleton(() => GetUserRoles(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));
  sl.registerLazySingleton(() => UploadAvatar(sl()));
  sl.registerLazySingleton(() => RemoveAvatar(sl()));

  sl.registerFactory(
    () => ProfileBloc(
      getCurrentUser: sl(),
      getProfile: sl(),
      getUserRoles: sl(),
      signOut: sl(),
    ),
  );
  sl.registerFactory(() => EditProfileBloc(updateProfile: sl()));
  sl.registerFactory(() => AvatarBloc(uploadAvatar: sl(), removeAvatar: sl()));
}

void _registerPreferences() {
  sl.registerLazySingleton<PreferencesRemoteDataSource>(
    () => PreferencesRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<PreferencesRepository>(
    () => PreferencesRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetPreferences(sl()));
  sl.registerLazySingleton(() => UpdatePreferences(sl()));

  sl.registerFactory(
    () => PreferencesBloc(
      getCurrentUser: sl(),
      getPreferences: sl(),
      updatePreferences: sl(),
    ),
  );
}

void _registerWellbeing() {
  sl.registerLazySingleton<MoodRemoteDataSource>(
    () => MoodRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<MoodRepository>(
    () => MoodRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => SaveMoodCheckin(sl()));
  sl.registerLazySingleton(() => GetMoodHistory(sl()));

  sl.registerFactory(
    () => MoodCheckinBloc(getCurrentUser: sl(), saveMoodCheckin: sl()),
  );
  sl.registerFactory(
    () => MoodHistoryBloc(getCurrentUser: sl(), getMoodHistory: sl()),
  );

  sl.registerLazySingleton<NeedsRemoteDataSource>(
    () => NeedsRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<NeedsRepository>(
    () => NeedsRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetNeedOptions(sl()));
  sl.registerLazySingleton(() => GetRecommendations(sl()));
  sl.registerLazySingleton(() => SaveNeedSession(sl()));

  sl.registerFactory(
    () => NeedsBloc(
      getCurrentUser: sl(),
      getNeedOptions: sl(),
      getRecommendations: sl(),
      saveNeedSession: sl(),
    ),
  );
}

void _registerActivities() {
  sl.registerLazySingleton<ActivitiesRemoteDataSource>(
    () => ActivitiesRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<ActivitiesRepository>(
    () => ActivitiesRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetActivityCategories(sl()));
  sl.registerLazySingleton(() => GetActivities(sl()));
  sl.registerLazySingleton(() => GetActivityById(sl()));
  sl.registerLazySingleton<LinkOpener>(() => const UrlLauncherLinkOpener());
  sl.registerLazySingleton(() => StartActivitySession(sl()));
  sl.registerLazySingleton(() => FinishActivitySession(sl()));
  sl.registerLazySingleton(() => AbandonActivitySession(sl()));
  sl.registerLazySingleton(() => GetSavedActivities(sl()));
  sl.registerLazySingleton(() => SaveActivity(sl()));
  sl.registerLazySingleton(() => UnsaveActivity(sl()));

  sl.registerFactory(
    () => ActivitiesBloc(getActivityCategories: sl(), getActivities: sl()),
  );
  sl.registerFactory(() => ActivityDetailBloc(getActivityById: sl()));
  sl.registerFactory(
    () => ActivitySessionBloc(
      getCurrentUser: sl(),
      startActivitySession: sl(),
      finishActivitySession: sl(),
      abandonActivitySession: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => SavedActivitiesBloc(
      getCurrentUser: sl(),
      getSavedActivities: sl(),
      saveActivity: sl(),
      unsaveActivity: sl(),
    ),
  );
}

void _registerCommunity() {
  sl.registerLazySingleton<CommunityRemoteDataSource>(
    () => CommunityRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<CommunityRepository>(
    () => CommunityRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetCommunityCategories(sl()));
  sl.registerLazySingleton(() => GetPosts(sl()));
  sl.registerLazySingleton(() => GetPostById(sl()));
  sl.registerLazySingleton(() => GetPostComments(sl()));
  sl.registerLazySingleton(() => CreatePost(sl()));

  sl.registerFactory(
    () => FeedBloc(getCommunityCategories: sl(), getPosts: sl()),
  );
  sl.registerFactory(
    () => PostDetailBloc(getPostById: sl(), getPostComments: sl()),
  );
  sl.registerFactory(
    () => CreatePostBloc(getCommunityCategories: sl(), createPost: sl()),
  );
}
