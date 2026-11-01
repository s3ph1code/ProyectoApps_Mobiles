import 'package:equatable/equatable.dart';

/// Resultado de error que viaja de los repositorios hacia la presentación.
///
/// `message` ya está escrito en español y listo para mostrarse: explica qué
/// pasó y qué hacer. El BLoC lo reenvía tal cual, la UI no lo reescribe.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure()
      : super('El correo o la contraseña no coinciden. Revísalos e inténtalo otra vez.');
}

class EmailAlreadyRegisteredFailure extends Failure {
  const EmailAlreadyRegisteredFailure()
      : super('Ese correo ya tiene una cuenta. Inicia sesión o usa otro correo.');
}

class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure()
      : super('La contraseña necesita al menos 8 caracteres.');
}

class InvalidEmailFailure extends Failure {
  const InvalidEmailFailure()
      : super('Ese correo no tiene un formato válido.');
}

class EmailNotConfirmedFailure extends Failure {
  const EmailNotConfirmedFailure()
      : super('Falta confirmar tu correo. Abre el enlace que te enviamos y vuelve a entrar.');
}

class TooManyAttemptsFailure extends Failure {
  const TooManyAttemptsFailure()
      : super('Hubo demasiados intentos seguidos. Espera un momento y vuelve a probar.');
}

class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure()
      : super('Tu sesión terminó. Inicia sesión para continuar.');
}

class NetworkFailure extends Failure {
  const NetworkFailure()
      : super('No hay conexión. Revisa tu internet y vuelve a intentarlo.');
}

class ServerFailure extends Failure {
  const ServerFailure()
      : super('El servicio no respondió. Inténtalo en un momento.');
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure()
      : super('Algo no funcionó como esperábamos. Inténtalo de nuevo.');
}
