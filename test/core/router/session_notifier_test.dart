import 'dart:async';

import 'package:doulapp/core/router/session_notifier.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = AuthUser(id: 'uuid-1', email: 'ana@icesi.edu.co');
  late StreamController<AuthUser?> changes;

  setUp(() => changes = StreamController<AuthUser?>());
  tearDown(() => changes.close());

  test('parte de la sesión restaurada al arrancar', () {
    final withSession = SessionNotifier(
      initialUser: user,
      changes: changes.stream,
    );
    final withoutSession = SessionNotifier(
      initialUser: null,
      changes: const Stream<AuthUser?>.empty(),
    );

    expect(withSession.isAuthenticated, isTrue);
    expect(withSession.user, user);
    expect(withoutSession.isAuthenticated, isFalse);

    withSession.dispose();
    withoutSession.dispose();
  });

  test('avisa a los oyentes cuando la sesión cambia', () async {
    final notifier = SessionNotifier(initialUser: null, changes: changes.stream);
    var notifications = 0;
    notifier.addListener(() => notifications++);

    changes.add(user);
    await pumpEventQueue();
    expect(notifier.isAuthenticated, isTrue);

    changes.add(null);
    await pumpEventQueue();
    expect(notifier.isAuthenticated, isFalse);
    expect(notifications, 2);

    notifier.dispose();
  });

  test('no avisa cuando llega el mismo usuario', () async {
    final notifier = SessionNotifier(initialUser: user, changes: changes.stream);
    var notifications = 0;
    notifier.addListener(() => notifications++);

    changes.add(user);
    await pumpEventQueue();

    expect(notifications, 0);
    notifier.dispose();
  });
}
