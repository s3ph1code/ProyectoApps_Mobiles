import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/get_current_user.dart';
import '../../domain/entities/blocked_user.dart';
import '../../domain/usecases/block_params.dart';
import '../../domain/usecases/block_user.dart';
import '../../domain/usecases/get_blocked_users.dart';
import '../../domain/usecases/unblock_user.dart';
import 'blocked_users_event.dart';
import 'blocked_users_state.dart';

/// Perfil → Privacidad → Usuarias bloqueadas.
class BlockedUsersBloc extends Bloc<BlockedUsersEvent, BlockedUsersState> {
  final GetCurrentUser getCurrentUser;
  final GetBlockedUsers getBlockedUsers;
  final BlockUser blockUser;
  final UnblockUser unblockUser;

  int _noticeId = 0;

  BlockedUsersBloc({
    required this.getCurrentUser,
    required this.getBlockedUsers,
    required this.blockUser,
    required this.unblockUser,
  }) : super(const BlockedUsersInitial()) {
    on<BlockedUsersRequested>(_onRequested);
    on<BlockedUserUnblocked>(_onUnblocked);
    on<BlockedUserRestored>(_onRestored);
  }

  Future<void> _onRequested(
    BlockedUsersRequested event,
    Emitter<BlockedUsersState> emit,
  ) async {
    emit(const BlockedUsersLoading());
    final userId = await _currentUserId();
    if (userId == null) {
      emit(const BlockedUsersFailure('Inicia sesión para ver esta lista.'));
      return;
    }

    final result = await getBlockedUsers(userId);
    result.fold(
      (failure) => emit(BlockedUsersFailure(failure.message)),
      (users) => emit(BlockedUsersLoaded(users: users)),
    );
  }

  Future<void> _onUnblocked(
    BlockedUserUnblocked event,
    Emitter<BlockedUsersState> emit,
  ) async {
    final current = state;
    if (current is! BlockedUsersLoaded) return;

    final userId = await _currentUserId();
    if (userId == null) return;

    // La fila sale al instante; si falla, vuelve a su sitio.
    emit(
      BlockedUsersLoaded(
        users: [
          for (final u in current.users)
            if (u.userId != event.user.userId) u,
        ],
        justUnblocked: event.user,
        noticeId: ++_noticeId,
      ),
    );

    final result = await unblockUser(
      BlockParams(blockerId: userId, blockedId: event.user.userId),
    );
    result.fold(
      (failure) => emit(
        BlockedUsersLoaded(
          users: current.users,
          errorMessage: failure.message,
          noticeId: ++_noticeId,
        ),
      ),
      (_) {},
    );
  }

  Future<void> _onRestored(
    BlockedUserRestored event,
    Emitter<BlockedUsersState> emit,
  ) async {
    final current = state;
    if (current is! BlockedUsersLoaded) return;

    final userId = await _currentUserId();
    if (userId == null) return;

    final result = await blockUser(
      BlockParams(blockerId: userId, blockedId: event.user.userId),
    );
    result.fold(
      (failure) => emit(
        BlockedUsersLoaded(
          users: current.users,
          errorMessage: failure.message,
          noticeId: ++_noticeId,
        ),
      ),
      (_) => emit(
        BlockedUsersLoaded(
          users: _byMostRecent([...current.users, event.user]),
        ),
      ),
    );
  }

  List<BlockedUser> _byMostRecent(List<BlockedUser> users) {
    return [...users]..sort((a, b) => b.blockedAt.compareTo(a.blockedAt));
  }

  Future<String?> _currentUserId() async {
    final result = await getCurrentUser(const NoParams());
    return result.fold((_) => null, (user) => user?.id);
  }
}
