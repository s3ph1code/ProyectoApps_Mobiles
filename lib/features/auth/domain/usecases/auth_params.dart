import 'package:equatable/equatable.dart';

class EmailPasswordParams extends Equatable {
  final String email;
  final String password;

  const EmailPasswordParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Datos del registro: además de las credenciales, el nombre con el que la
/// usuaria quiere que la llamen.
class SignUpParams extends EmailPasswordParams {
  final String? displayName;

  const SignUpParams({
    required super.email,
    required super.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [...super.props, displayName];
}
