import 'package:equatable/equatable.dart';

import '../../domain/entities/managed_user.dart';

enum RoleAdminStatus { initial, loading, ready, forbidden, failure }

class RoleAdminState extends Equatable {
  final RoleAdminStatus status;

  /// Lo último que se buscó; vacío es «el equipo».
  final String query;
  final List<ManagedUser> users;

  /// Usuaria a la que se le está cambiando el rol.
  final String? workingUserId;

  /// Mensaje del fallo de carga ([RoleAdminStatus.failure]).
  final String? errorMessage;

  /// Aviso de un solo uso; cada uno trae su [noticeId] para no repetirse.
  final String? notice;
  final bool noticeIsError;
  final int noticeId;

  const RoleAdminState({
    this.status = RoleAdminStatus.initial,
    this.query = '',
    this.users = const [],
    this.workingUserId,
    this.errorMessage,
    this.notice,
    this.noticeIsError = false,
    this.noticeId = 0,
  });

  RoleAdminState copyWith({
    RoleAdminStatus? status,
    String? query,
    List<ManagedUser>? users,
    String? Function()? workingUserId,
    String? errorMessage,
    String? notice,
    bool noticeIsError = false,
    int? noticeId,
  }) => RoleAdminState(
    status: status ?? this.status,
    query: query ?? this.query,
    users: users ?? this.users,
    workingUserId: workingUserId != null ? workingUserId() : this.workingUserId,
    errorMessage: errorMessage,
    notice: notice,
    noticeIsError: noticeIsError,
    noticeId: noticeId ?? this.noticeId,
  );

  @override
  List<Object?> get props => [
    status,
    query,
    users,
    workingUserId,
    errorMessage,
    notice,
    noticeIsError,
    noticeId,
  ];
}
