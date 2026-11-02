import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/usecases/auth_params.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final SignInWithEmail signIn;

  LoginBloc({required this.signIn}) : super(const LoginInitial()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    final email = event.email.trim();
    final password = event.password;

    if (email.isEmpty || !email.contains('@')) {
      emit(LoginFailure(const InvalidEmailFailure().message));
      return;
    }

    if (password.isEmpty) {
      emit(const LoginFailure('Escribe tu contraseña para continuar.'));
      return;
    }

    emit(const LoginLoading());

    final result = await signIn(
      EmailPasswordParams(email: email, password: password),
    );

    result.fold(
      (failure) => emit(LoginFailure(failure.message)),
      (user) => emit(LoginSuccess(user)),
    );
  }
}
