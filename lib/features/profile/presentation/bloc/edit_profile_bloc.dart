import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/update_profile.dart';
import 'edit_profile_event.dart';
import 'edit_profile_state.dart';

class EditProfileBloc extends Bloc<EditProfileEvent, EditProfileState> {
  final UpdateProfile updateProfile;

  EditProfileBloc({required this.updateProfile})
    : super(const EditProfileInitial()) {
    on<EditProfileSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    EditProfileSubmitted event,
    Emitter<EditProfileState> emit,
  ) async {
    // Evita guardar dos veces si se toca el botón mientras ya se está guardando.
    if (state is EditProfileSaving) return;

    emit(const EditProfileSaving());

    final result = await updateProfile(
      UpdateProfileParams(
        profile: event.profile,
        displayName: event.displayName,
        bio: event.bio,
      ),
    );

    result.fold(
      (failure) => emit(EditProfileFailure(failure.message)),
      (profile) => emit(EditProfileSuccess(profile)),
    );
  }
}
