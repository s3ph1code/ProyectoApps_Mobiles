import 'package:doulapp/core/error/exceptions.dart' as app;
import 'package:doulapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

void main() {
  late MockGoTrueClient auth;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    final client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    dataSource = AuthRemoteDataSourceImpl(client: client);
  });

  test('pide a Supabase el enlace con el correo recortado', () async {
    when(() => auth.resetPasswordForEmail('ana@icesi.edu.co'))
        .thenAnswer((_) async {});

    await dataSource.sendPasswordReset('  ana@icesi.edu.co  ');

    verify(() => auth.resetPasswordForEmail('ana@icesi.edu.co')).called(1);
  });

  test('conserva el código de error de Supabase', () async {
    when(() => auth.resetPasswordForEmail(any())).thenThrow(
      const supabase.AuthException(
        'rate limit',
        code: 'over_email_send_rate_limit',
      ),
    );

    await expectLater(
      () => dataSource.sendPasswordReset('ana@icesi.edu.co'),
      throwsA(
        isA<app.AuthException>().having(
          (e) => e.code,
          'code',
          'over_email_send_rate_limit',
        ),
      ),
    );
  });

  test('un fallo de red se convierte en NetworkException', () async {
    when(() => auth.resetPasswordForEmail(any()))
        .thenThrow(supabase.AuthRetryableFetchException());

    expect(
      () => dataSource.sendPasswordReset('ana@icesi.edu.co'),
      throwsA(isA<app.NetworkException>()),
    );
  });
}
