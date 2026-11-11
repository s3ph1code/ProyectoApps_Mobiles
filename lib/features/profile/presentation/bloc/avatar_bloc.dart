import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/remove_avatar.dart';
import '../../domain/usecases/upload_avatar.dart';
import 'avatar_event.dart';
import 'avatar_state.dart';

class AvatarBloc extends Bloc<AvatarEvent, AvatarState> {
  final UploadAvatar uploadAvatar;
  final RemoveAvatar removeAvatar;

  AvatarBloc({required this.uploadAvatar, required this.removeAvatar})
    : super(const AvatarInitial()) {
    on<AvatarUploadRequested>(_onUpload);
    on<AvatarRemoveRequested>(_onRemove);
  }

  Future<void> _onUpload(
    AvatarUploadRequested event,
    Emitter<AvatarState> emit,
  ) async {
    // Una operación a la vez: evita subidas dobles al tocar dos veces.
    if (state is AvatarWorking) return;
    emit(const AvatarWorking());

    final result = await uploadAvatar(
      UploadAvatarParams(profile: event.profile, image: event.image),
    );

    result.fold(
      (failure) => emit(AvatarFailure(failure.message)),
      (profile) => emit(AvatarSuccess(profile)),
    );
  }

  Future<void> _onRemove(
    AvatarRemoveRequested event,
    Emitter<AvatarState> emit,
  ) async {
    if (state is AvatarWorking) return;
    emit(const AvatarWorking());

    final result = await removeAvatar(
      RemoveAvatarParams(profile: event.profile),
    );

    result.fold(
      (failure) => emit(AvatarFailure(failure.message)),
      (profile) => emit(AvatarSuccess(profile)),
    );
  }
}
