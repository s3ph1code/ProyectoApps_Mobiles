import 'package:equatable/equatable.dart';

sealed class BlockUserEvent extends Equatable {
  const BlockUserEvent();

  @override
  List<Object?> get props => [];
}

/// Bloquear a la autora de una publicación o comentario.
class BlockUserRequested extends BlockUserEvent {
  final String blockedUserId;

  /// Solo para el aviso «Bloqueaste a …»; `null` si su perfil es privado.
  final String? blockedUserName;

  const BlockUserRequested({required this.blockedUserId, this.blockedUserName});

  @override
  List<Object?> get props => [blockedUserId, blockedUserName];
}

/// «Deshacer» justo después de bloquear.
class UnblockUserRequested extends BlockUserEvent {
  final String blockedUserId;

  const UnblockUserRequested(this.blockedUserId);

  @override
  List<Object?> get props => [blockedUserId];
}
