import 'package:equatable/equatable.dart';

import '../../domain/entities/managed_user.dart';

sealed class RoleAdminEvent extends Equatable {
  const RoleAdminEvent();

  @override
  List<Object?> get props => [];
}

/// Abre la pantalla: carga el equipo de moderación.
class RoleAdminStarted extends RoleAdminEvent {
  const RoleAdminStarted();
}

/// Busca por nombre; con texto vacío vuelve a mostrar el equipo.
class RoleAdminSearchSubmitted extends RoleAdminEvent {
  final String query;

  const RoleAdminSearchSubmitted(this.query);

  @override
  List<Object?> get props => [query];
}

/// Reintenta la última búsqueda.
class RoleAdminRetried extends RoleAdminEvent {
  const RoleAdminRetried();
}

class RoleAdminModeratorToggled extends RoleAdminEvent {
  final ManagedUser user;

  /// `true` asigna el rol de moderadora; `false` lo quita.
  final bool makeModerator;

  const RoleAdminModeratorToggled({
    required this.user,
    required this.makeModerator,
  });

  @override
  List<Object?> get props => [user, makeModerator];
}
