import 'package:doulapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

class MockUser extends Mock implements supabase.User {}

class MockAuthResponse extends Mock implements supabase.AuthResponse {}

void main() {
  late MockGoTrueClient auth;
  late AuthRemoteDataSourceImpl dataSource;

  const email = 'ana@icesi.edu.co';
  const password = 'contrasena-larga';

  setUp(() {
    final client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    dataSource = AuthRemoteDataSourceImpl(client: client);

    final user = MockUser();
    when(() => user.id).thenReturn('uuid-1');
    when(() => user.email).thenReturn(email);
    final response = MockAuthResponse();
    when(() => response.user).thenReturn(user);
    when(
      () => auth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => response);
  });

  test('envía el nombre recortado como display_name en la metadata', () async {
    await dataSource.signUp(
      email: email,
      password: password,
      displayName: '  Ana María  ',
    );

    verify(
      () => auth.signUp(
        email: email,
        password: password,
        data: {'display_name': 'Ana María'},
      ),
    ).called(1);
  });

  test('sin nombre no envía metadata y el perfil usa el del correo', () async {
    await dataSource.signUp(
      email: email,
      password: password,
      displayName: '   ',
    );

    verify(() => auth.signUp(email: email, password: password)).called(1);
  });
}
