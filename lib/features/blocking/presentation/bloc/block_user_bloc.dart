import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/get_current_user.dart';
import '../../domain/usecases/block_params.dart';
import '../../domain/usecases/block_user.dart';
import '../../domain/usecases/unblock_user.dart';
import 'block_user_event.dart';
import 'block_user_state.dart';

/// Bloquea y desbloquea desde el menú de una publicación o comentario.
/// Se comparte entre las pantallas de comunidad para que el «Deshacer» siga
/// funcionando aunque la pantalla donde se bloqueó ya se haya cerrado.
class BlockUserBloc extends Bloc<BlockUserEvent, BlockUserState> {
  final GetCurrentUser getCurrentUser;
  final BlockUser blockUser;
  final UnblockUser unblockUser;

  int _sequence = 0;

  BlockUserBloc({
    required this.getCurrentUser,
    required this.blockUser,
    required this.unblockUser,
  }) : super(const BlockUserInitial()) {
    on<BlockUserRequested>(_onBlock);
    on<UnblockUserRequested>(_onUnblock);
  }

  Future<void> _onBlock(
    BlockUserRequested event,
    Emitter<BlockUserState> emit,
  ) async {
    emit(const BlockUserInProgress());
    final blockerId = await _currentUserId(emit);
    if (blockerId == null) return;

    final result = await blockUser(
      BlockParams(blockerId: blockerId, blockedId: event.blockedUserId),
    );
    result.fold(
      (failure) =>
          emit(BlockUserFailure(failure.message, sequence: ++_sequence)),
      (_) => emit(
        BlockUserBlocked(
          blockedUserId: event.blockedUserId,
          blockedUserName: event.blockedUserName,
          sequence: ++_sequence,
        ),
      ),
    );
  }

  Future<void> _onUnblock(
    UnblockUserRequested event,
    Emitter<BlockUserState> emit,
  ) async {
    emit(const BlockUserInProgress());
    final blockerId = await _currentUserId(emit);
    if (blockerId == null) return;

    final result = await unblockUser(
      BlockParams(blockerId: blockerId, blockedId: event.blockedUserId),
    );
    result.fold(
      (failure) =>
          emit(BlockUserFailure(failure.message, sequence: ++_sequence)),
      (_) => emit(
        BlockUserUnblocked(
          blockedUserId: event.blockedUserId,
          sequence: ++_sequence,
        ),
      ),
    );
  }

  Future<String?> _currentUserId(Emitter<BlockUserState> emit) async {
    final result = await getCurrentUser(const NoParams());
    final user = result.fold((_) => null, (user) => user);
    if (user == null) {
      emit(
        BlockUserFailure(
          result.fold(
            (failure) => failure.message,
            (_) => const UnauthenticatedFailure().message,
          ),
          sequence: ++_sequence,
        ),
      );
    }
    return user?.id;
  }
}
