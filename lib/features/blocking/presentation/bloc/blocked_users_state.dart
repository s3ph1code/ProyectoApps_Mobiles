import 'package:equatable/equatable.dart';

import '../../domain/entities/blocked_user.dart';

sealed class BlockedUsersState extends Equatable {
  const BlockedUsersState();

  @override
  List<Object?> get props => [];
}

class BlockedUsersInitial extends BlockedUsersState {
  const BlockedUsersInitial();
}

class BlockedUsersLoading extends BlockedUsersState {
  const BlockedUsersLoading();
}

class BlockedUsersFailure extends BlockedUsersState {
  final String message;

  const BlockedUsersFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class BlockedUsersLoaded extends BlockedUsersState {
  final List<BlockedUser> users;

  /// Avisos de un solo uso: la página los muestra y no se repiten porque cada
  /// uno trae su [noticeId].
  final BlockedUser? justUnblocked;
  final String? errorMessage;
  final int noticeId;

  const BlockedUsersLoaded({
    required this.users,
    this.justUnblocked,
    this.errorMessage,
    this.noticeId = 0,
  });

  bool get isEmpty => users.isEmpty;

  @override
  List<Object?> get props => [users, justUnblocked, errorMessage, noticeId];
}
