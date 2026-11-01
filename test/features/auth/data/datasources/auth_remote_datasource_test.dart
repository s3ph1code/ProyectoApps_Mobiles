import 'package:doulapp/core/error/exceptions.dart' as app;
import 'package:doulapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

class MockUser extends Mock implements supabase.User {}

class MockAuthResponse extends Mock implements supabase.AuthResponse {}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late AuthRemoteDataSourceImpl dataSource;

  const email = 'ana@icesi.edu.co';
  const password = 'contrasena-larga';

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    dataSource = AuthRemoteDataSourceImpl(client: client);
  });

  supabase.AuthResponse responseWith(supabase.User? user) {
    final response = MockAuthResponse();
    when(() => response.user).thenReturn(user);
    return response;
  }

  supabase.User userWith({String id = 'uuid-1', String? email = email}) {
    final user = MockUser();
    when(() => user.id).thenReturn(id);
    when(() => user.email).thenReturn(email);
    return user;
  }

  group('signUp', () {
    test('recorta el correo antes de enviarlo', () async {
      final response = responseWith(userWith());
      when(() => auth.signUp(email: email, password: password))
          .thenAnswer((_) async => response);

      final result = await dataSource.signUp(email: '  $email  ', password: password);

      expect(result.email, email);
      verify(() => auth.signUp(email: email, password: password)).called(1);
    });

    test('lanza AuthException si Supabase no devuelve usuario', () async {
      final response = responseWith(null);
      when(() => auth.signUp(email: email, password: password))
          .thenAnswer((_) async => response);

      expect(
        () => dataSource.signUp(email: email, password: password),
        throwsA(isA<app.AuthException>()),
      );
    });

    test('conserva el código de error de Supabase', () async {
      when(() => auth.signUp(email: email, password: password)).thenThrow(
        const supabase.AuthException('User already registered', code: 'email_exists'),
      );

      await expectLater(
        () => dataSource.signUp(email: email, password: password),
        throwsA(
          isA<app.AuthException>().having((e) => e.code, 'code', 'email_exists'),
        ),
      );
    });
  });

  group('signIn', () {
    test('devuelve el usuario autenticado', () async {
      final response = responseWith(userWith());
      when(() => auth.signInWithPassword(email: email, password: password))
          .thenAnswer((_) async => response);

      final result = await dataSource.signIn(email: email, password: password);

      expect(result.id, 'uuid-1');
      expect(result.email, email);
    });

    test('un fallo de red se convierte en NetworkException', () async {
      when(() => auth.signInWithPassword(email: email, password: password))
          .thenThrow(supabase.AuthRetryableFetchException());

      expect(
        () => dataSource.signIn(email: email, password: password),
        throwsA(isA<app.NetworkException>()),
      );
    });

    test('usa el statusCode cuando no hay código', () async {
      when(() => auth.signInWithPassword(email: email, password: password))
          .thenThrow(const supabase.AuthException('Boom', statusCode: '400'));

      await expectLater(
        () => dataSource.signIn(email: email, password: password),
        throwsA(isA<app.AuthException>().having((e) => e.code, 'code', '400')),
      );
    });
  });

  group('getCurrentUser', () {
    test('devuelve null cuando no hay sesión', () async {
      when(() => auth.currentUser).thenReturn(null);

      expect(await dataSource.getCurrentUser(), isNull);
    });

    test('un usuario sin correo se trata como dato del servidor inválido', () async {
      final user = userWith(email: null);
      when(() => auth.currentUser).thenReturn(user);

      expect(
        () => dataSource.getCurrentUser(),
        throwsA(isA<app.ServerException>()),
      );
    });
  });

  group('signOut', () {
    test('delega en Supabase', () async {
      when(() => auth.signOut()).thenAnswer((_) async {});

      await dataSource.signOut();

      verify(() => auth.signOut()).called(1);
    });
  });
}
