import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_user.dart';

sealed class RegisterState extends Equatable {
  const RegisterState();

  @override
  List<Object?> get props => [];
}

class RegisterInitial extends RegisterState {
  const RegisterInitial();
}

class RegisterLoading extends RegisterState {
  const RegisterLoading();
}

class RegisterSuccess extends RegisterState {
  final AuthUser user;

  const RegisterSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class RegisterFailure extends RegisterState {
  final String message;

  const RegisterFailure(this.message);

  @override
  List<Object?> get props => [message];
}
