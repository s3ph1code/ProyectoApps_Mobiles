import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/usecases/auth_params.dart';
import '../../domain/usecases/sign_up_with_email.dart';
import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final SignUpWithEmail signUp;

  RegisterBloc({required this.signUp}) : super(const RegisterInitial()) {
    on<RegisterSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    final email = event.email.trim();
    final password = event.password;

    if (email.isEmpty || !email.contains('@')) {
      emit(RegisterFailure(const InvalidEmailFailure().message));
      return;
    }

    if (password.length < 8) {
      emit(RegisterFailure(const WeakPasswordFailure().message));
      return;
    }

    emit(const RegisterLoading());

    final result = await signUp(
      EmailPasswordParams(email: email, password: password),
    );

    result.fold(
      (failure) => emit(RegisterFailure(failure.message)),
      (user) => emit(RegisterSuccess(user)),
    );
  }
}
