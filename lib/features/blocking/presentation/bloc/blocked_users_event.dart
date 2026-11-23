import 'package:equatable/equatable.dart';

import '../../domain/entities/blocked_user.dart';

sealed class BlockedUsersEvent extends Equatable {
  const BlockedUsersEvent();

  @override
  List<Object?> get props => [];
}

class BlockedUsersRequested extends BlockedUsersEvent {
  const BlockedUsersRequested();
}

/// Desbloquear desde la lista: la fila sale al instante.
class BlockedUserUnblocked extends BlockedUsersEvent {
  final BlockedUser user;

  const BlockedUserUnblocked(this.user);

  @override
  List<Object?> get props => [user];
}

/// «Deshacer» tras desbloquear: vuelve a bloquear a la misma usuaria.
class BlockedUserRestored extends BlockedUsersEvent {
  final BlockedUser user;

  const BlockedUserRestored(this.user);

  @override
  List<Object?> get props => [user];
}
