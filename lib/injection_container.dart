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
import 'features/profile/data/datasources/profile_remote_datasource.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/domain/usecases/create_profile.dart';
import 'features/profile/domain/usecases/get_profile.dart';
import 'features/profile/domain/usecases/get_user_roles.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerLazySingleton<SupabaseClient>(() => SupabaseConfig.client);

  _registerAuth();
  _registerProfile();

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

  sl.registerFactory(
    () => ProfileBloc(
      getCurrentUser: sl(),
      getProfile: sl(),
      getUserRoles: sl(),
      signOut: sl(),
    ),
  );
}
