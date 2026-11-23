import 'package:doulapp/features/administration/data/models/managed_user_model.dart';
import 'package:doulapp/features/administration/domain/entities/managed_user.dart';
import 'package:doulapp/features/profile/domain/entities/app_role.dart';

const ana = ManagedUser(
  id: 'ana-id',
  displayName: 'Ana',
  roles: [AppRole.user],
);

const lucia = ManagedUser(
  id: 'lucia-id',
  displayName: 'Lucía',
  roles: [AppRole.user, AppRole.moderator],
);

const root = ManagedUser(
  id: 'root-id',
  displayName: 'Admin',
  roles: [AppRole.user, AppRole.admin],
);

const anonymous = ManagedUser(id: 'anon-id', roles: [AppRole.user]);

final profileRowAna = {
  'id': 'ana-id',
  'display_name': 'Ana',
  'user_roles': [
    {
      'roles': {'code': 'user'},
    },
  ],
};

final profileRowLucia = {
  'id': 'lucia-id',
  'display_name': 'Lucía',
  'user_roles': [
    {
      'roles': {'code': 'user'},
    },
    {
      'roles': {'code': 'moderator'},
    },
  ],
};

final teamRows = [
  {
    'user_id': 'lucia-id',
    'roles': {'code': 'moderator'},
    'profile': {'display_name': 'Lucía'},
  },
  {
    'user_id': 'root-id',
    'roles': {'code': 'admin'},
    'profile': {'display_name': 'Admin'},
  },
  {
    'user_id': 'lucia-id',
    'roles': {'code': 'admin'},
    'profile': {'display_name': 'Lucía'},
  },
];

ManagedUserModel get anaModel =>
    ManagedUserModel.fromProfileJson(profileRowAna);
