import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/auth/domain/entities/auth_user.dart';

/// Mantiene el usuario de la sesión actual y avisa al router cuando cambia,
/// para que reevalúe qué rutas puede ver la usuaria.
class SessionNotifier extends ChangeNotifier {
  SessionNotifier({
    required AuthUser? initialUser,
    required Stream<AuthUser?> changes,
  }) : _user = initialUser {
    _subscription = changes.listen((user) {
      if (user == _user) return;
      _user = user;
      notifyListeners();
    });
  }

  AuthUser? _user;
  late final StreamSubscription<AuthUser?> _subscription;

  AuthUser? get user => _user;

  bool get isAuthenticated => _user != null;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
