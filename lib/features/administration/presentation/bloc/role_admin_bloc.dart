import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../profile/domain/entities/app_role.dart';
import '../../domain/usecases/assign_role.dart';
import '../../domain/usecases/remove_role.dart';
import '../../domain/usecases/role_params.dart';
import '../../domain/usecases/search_users.dart';
import 'role_admin_event.dart';
import 'role_admin_state.dart';

/// Administración → asignar y quitar el rol de moderadora.
class RoleAdminBloc extends Bloc<RoleAdminEvent, RoleAdminState> {
  final SearchUsers searchUsers;
  final AssignRole assignRole;
  final RemoveRole removeRole;

  int _noticeId = 0;

  RoleAdminBloc({
    required this.searchUsers,
    required this.assignRole,
    required this.removeRole,
  }) : super(const RoleAdminState()) {
    on<RoleAdminStarted>((_, emit) => _search(emit, ''));
    on<RoleAdminSearchSubmitted>((event, emit) => _search(emit, event.query));
    on<RoleAdminRetried>((_, emit) => _search(emit, state.query));
    on<RoleAdminModeratorToggled>(_onToggled);
  }

  Future<void> _search(Emitter<RoleAdminState> emit, String rawQuery) async {
    final query = rawQuery.trim();
    final previous = state;
    emit(
      RoleAdminState(
        status: RoleAdminStatus.loading,
        query: query,
        users: previous.users,
      ),
    );

    final result = await searchUsers(SearchUsersParams(query: query));
    result.fold(
      (failure) {
        if (failure is SearchTooShortFailure) {
          // Se queda lo que había y se explica; no es un fallo de carga.
          emit(
            previous.copyWith(
              status: RoleAdminStatus.ready,
              notice: failure.message,
              noticeIsError: true,
              noticeId: ++_noticeId,
            ),
          );
        } else if (failure is AdminForbiddenFailure) {
          emit(const RoleAdminState(status: RoleAdminStatus.forbidden));
        } else {
          emit(
            RoleAdminState(
              status: RoleAdminStatus.failure,
              query: query,
              errorMessage: failure.message,
            ),
          );
        }
      },
      (users) => emit(
        RoleAdminState(
          status: RoleAdminStatus.ready,
          query: query,
          users: users,
        ),
      ),
    );
  }

  Future<void> _onToggled(
    RoleAdminModeratorToggled event,
    Emitter<RoleAdminState> emit,
  ) async {
    if (state.workingUserId != null) return;
    final user = event.user;
    emit(state.copyWith(workingUserId: () => user.id));

    final params = RoleParams(userId: user.id, role: AppRole.moderator);
    final result = event.makeModerator
        ? await assignRole(params)
        : await removeRole(params);

    result.fold(
      (failure) => emit(
        state.copyWith(
          workingUserId: () => null,
          notice: failure.message,
          noticeIsError: true,
          noticeId: ++_noticeId,
        ),
      ),
      (_) {
        final updated = event.makeModerator
            ? user.withRole(AppRole.moderator)
            : user.withoutRole(AppRole.moderator);
        emit(
          state.copyWith(
            workingUserId: () => null,
            users: [
              for (final u in state.users)
                if (u.id == user.id) updated else u,
            ],
            notice: event.makeModerator
                ? '${_name(user)} ahora es moderadora.'
                : '${_name(user)} ya no es moderadora.',
            noticeId: ++_noticeId,
          ),
        );
      },
    );
  }

  String _name(user) {
    final name = (user.displayName as String?)?.trim() ?? '';
    return name.isEmpty ? 'Esta usuaria' : name;
  }
}
