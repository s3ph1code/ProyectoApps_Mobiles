import 'package:doulapp/features/blocking/data/models/blocked_user_model.dart';
import 'package:doulapp/features/blocking/domain/entities/blocked_user.dart';

final blockedAna = BlockedUser(
  userId: 'ana-id',
  displayName: 'Ana',
  blockedAt: DateTime.utc(2026, 11, 20),
);

final blockedAnonymous = BlockedUser(
  userId: 'anon-id',
  blockedAt: DateTime.utc(2026, 11, 21),
);

final blockedRow = {
  'blocked_id': 'ana-id',
  'created_at': '2026-11-20T00:00:00+00:00',
  'blocked': {'display_name': 'Ana'},
};

final blockedModelAna = BlockedUserModel(
  userId: 'ana-id',
  displayName: 'Ana',
  blockedAt: DateTime.utc(2026, 11, 20),
);
