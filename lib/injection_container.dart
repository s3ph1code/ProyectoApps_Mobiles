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
import 'features/preferences/data/datasources/preferences_remote_datasource.dart';
import 'features/preferences/data/repositories/preferences_repository_impl.dart';
import 'features/preferences/domain/repositories/preferences_repository.dart';
import 'features/preferences/domain/usecases/get_preferences.dart';
import 'features/preferences/domain/usecases/update_preferences.dart';
import 'features/preferences/presentation/bloc/preferences_bloc.dart';
import 'features/profile/data/datasources/profile_remote_datasource.dart';
import 'features/wellbeing/data/datasources/mood_remote_datasource.dart';
import 'features/wellbeing/data/repositories/mood_repository_impl.dart';
import 'features/wellbeing/domain/repositories/mood_repository.dart';
import 'features/wellbeing/domain/usecases/save_mood_checkin.dart';
import 'features/wellbeing/presentation/bloc/mood_checkin_bloc.dart';
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

  sl.registerFactory(
    () => MoodCheckinBloc(getCurrentUser: sl(), saveMoodCheckin: sl()),
  );
}
