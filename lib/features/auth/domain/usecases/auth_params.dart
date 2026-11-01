import 'package:equatable/equatable.dart';

class EmailPasswordParams extends Equatable {
  final String email;
  final String password;

  const EmailPasswordParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}
