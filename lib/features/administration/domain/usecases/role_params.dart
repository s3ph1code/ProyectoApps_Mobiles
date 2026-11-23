import 'package:equatable/equatable.dart';

import '../../../profile/domain/entities/app_role.dart';

class RoleParams extends Equatable {
  final String userId;
  final AppRole role;

  const RoleParams({required this.userId, required this.role});

  @override
  List<Object?> get props => [userId, role];
}
