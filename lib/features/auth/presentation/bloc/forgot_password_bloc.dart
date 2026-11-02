import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/usecases/auth_params.dart';
import '../../domain/usecases/send_password_reset.dart';
import 'forgot_password_event.dart';
import 'forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final SendPasswordReset sendPasswordReset;

  ForgotPasswordBloc({required this.sendPasswordReset})
      : super(const ForgotPasswordInitial()) {
    on<ForgotPasswordSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    final email = event.email.trim();

    if (email.isEmpty || !email.contains('@')) {
      emit(ForgotPasswordFailure(const InvalidEmailFailure().message));
      return;
    }

    emit(const ForgotPasswordLoading());

    final result = await sendPasswordReset(EmailParams(email: email));

    result.fold(
      (failure) => emit(ForgotPasswordFailure(failure.message)),
      (_) => emit(ForgotPasswordSuccess(email)),
    );
  }
}
