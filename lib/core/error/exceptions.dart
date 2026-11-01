/// Error devuelto por Supabase Auth: credenciales inválidas, correo ya
/// registrado, contraseña demasiado corta.
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException($code): $message';
}

/// Error del backend que no proviene de la autenticación.
class ServerException implements Exception {
  final String message;

  const ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

/// La operación necesitaba una sesión activa y no había ninguna.
class UnauthenticatedException implements Exception {
  const UnauthenticatedException();

  @override
  String toString() => 'UnauthenticatedException';
}

/// Fallo de red: sin conexión o el servidor no respondió.
class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}
