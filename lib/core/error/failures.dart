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
    : super(
        'El correo o la contraseña no coinciden. Revísalos e inténtalo otra vez.',
      );
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
  const InvalidEmailFailure() : super('Ese correo no tiene un formato válido.');
}

class EmailNotConfirmedFailure extends Failure {
  const EmailNotConfirmedFailure()
    : super(
        'Falta confirmar tu correo. Abre el enlace que te enviamos y vuelve a entrar.',
      );
}

class TooManyAttemptsFailure extends Failure {
  const TooManyAttemptsFailure()
    : super(
        'Hubo demasiados intentos seguidos. Espera un momento y vuelve a probar.',
      );
}

class MissingNameFailure extends Failure {
  const MissingNameFailure()
    : super('Escribe cómo te gustaría que te llamemos.');
}

class NameTooLongFailure extends Failure {
  const NameTooLongFailure()
    : super('El nombre puede tener hasta 100 caracteres. Acórtalo un poco.');
}

class BioTooLongFailure extends Failure {
  const BioTooLongFailure()
    : super('Sobre ti puede tener hasta 280 caracteres. Acórtalo un poco.');
}

class AvatarTypeNotAllowedFailure extends Failure {
  const AvatarTypeNotAllowedFailure()
    : super('Esa imagen no es válida. Usa una foto JPG, PNG o WebP.');
}

class AvatarTooLargeFailure extends Failure {
  const AvatarTooLargeFailure()
    : super('La foto pesa más de 2 MB. Elige una más liviana.');
}

class MoodScoreRequiredFailure extends Failure {
  const MoodScoreRequiredFailure()
    : super('Elige cómo te sientes para poder guardar tu registro.');
}

class MoodNoteTooLongFailure extends Failure {
  const MoodNoteTooLongFailure()
    : super('La nota puede tener hasta 500 caracteres. Acórtala un poco.');
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
