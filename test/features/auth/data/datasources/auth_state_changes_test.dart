import 'dart:async';

import 'package:doulapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

class MockSession extends Mock implements supabase.Session {}

class MockUser extends Mock implements supabase.User {}

void main() {
  late MockGoTrueClient auth;
  late StreamController<supabase.AuthState> controller;
  late AuthRemoteDataSourceImpl dataSource;

  supabase.AuthState stateWith(supabase.User? user) {
    final session = user == null ? null : (MockSession()..stubUser(user));
    return supabase.AuthState(
      user == null
          ? supabase.AuthChangeEvent.signedOut
          : supabase.AuthChangeEvent.signedIn,
      session,
    );
  }

  supabase.User userWith(String? email) {
    final user = MockUser();
    when(() => user.id).thenReturn('uuid-1');
    when(() => user.email).thenReturn(email);
    return user;
  }

  setUp(() {
    final client = MockSupabaseClient();
    auth = MockGoTrueClient();
    controller = StreamController<supabase.AuthState>();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.onAuthStateChange).thenAnswer((_) => controller.stream);
    dataSource = AuthRemoteDataSourceImpl(client: client);
  });

  tearDown(() => controller.close());

  test('emite el usuario cuando se inicia sesión y null al cerrarla', () async {
    final emitted = <String?>[];
    final subscription =
        dataSource.authStateChanges().listen((u) => emitted.add(u?.email));

    controller
      ..add(stateWith(userWith('ana@icesi.edu.co')))
      ..add(stateWith(null));
    await pumpEventQueue();

    expect(emitted, ['ana@icesi.edu.co', null]);
    await subscription.cancel();
  });

  test('una sesión sin correo se trata como sin sesión', () async {
    final emitted = <Object?>[];
    final subscription =
        dataSource.authStateChanges().listen((u) => emitted.add(u));

    controller.add(stateWith(userWith(null)));
    await pumpEventQueue();

    expect(emitted, [null]);
    await subscription.cancel();
  });
}

extension on MockSession {
  void stubUser(supabase.User user) => when(() => this.user).thenReturn(user);
}
