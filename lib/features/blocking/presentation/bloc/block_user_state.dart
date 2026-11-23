import 'package:equatable/equatable.dart';

sealed class BlockUserState extends Equatable {
  const BlockUserState();

  @override
  List<Object?> get props => [];
}

class BlockUserInitial extends BlockUserState {
  const BlockUserInitial();
}

class BlockUserInProgress extends BlockUserState {
  const BlockUserInProgress();
}

/// El bloqueo se guardó. Cada emisión es un hecho nuevo, por eso lleva un
/// [sequence]: dos bloqueos seguidos a la misma usuaria no son «el mismo».
class BlockUserBlocked extends BlockUserState {
  final String blockedUserId;
  final String? blockedUserName;
  final int sequence;

  const BlockUserBlocked({
    required this.blockedUserId,
    this.blockedUserName,
    required this.sequence,
  });

  @override
  List<Object?> get props => [blockedUserId, blockedUserName, sequence];
}

/// Se deshizo el bloqueo.
class BlockUserUnblocked extends BlockUserState {
  final String blockedUserId;
  final int sequence;

  const BlockUserUnblocked({
    required this.blockedUserId,
    required this.sequence,
  });

  @override
  List<Object?> get props => [blockedUserId, sequence];
}

class BlockUserFailure extends BlockUserState {
  final String message;
  final int sequence;

  const BlockUserFailure(this.message, {required this.sequence});

  @override
  List<Object?> get props => [message, sequence];
}
