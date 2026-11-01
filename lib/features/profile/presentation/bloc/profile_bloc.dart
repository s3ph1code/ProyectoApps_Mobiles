import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/get_current_user.dart';
import '../../../auth/domain/usecases/sign_out.dart';
import '../../domain/usecases/get_profile.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetCurrentUser getCurrentUser;
  final GetProfile getProfile;
  final SignOut signOut;

  ProfileBloc({
    required this.getCurrentUser,
    required this.getProfile,
    required this.signOut,
  }) : super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileSignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final userResult = await getCurrentUser(const NoParams());
    await userResult.fold(
      (failure) async => emit(ProfileFailure(failure.message)),
      (user) async {
        if (user == null) {
          emit(ProfileFailure(const UnauthenticatedFailure().message));
          return;
        }

        final profileResult = await getProfile(
          GetProfileParams(userId: user.id),
        );
        profileResult.fold(
          (failure) => emit(ProfileFailure(failure.message)),
          (profile) => emit(
            ProfileLoaded(
              profile: profile,
              email: user.email,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSignOutRequested(
    ProfileSignOutRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await signOut(const NoParams());
    result.fold(
      (failure) => emit(ProfileFailure(failure.message)),
      (_) => emit(const ProfileSignedOut()),
    );
  }
}
