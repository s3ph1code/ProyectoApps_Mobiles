import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:doulapp/features/auth/domain/usecases/auth_params.dart';
import 'package:doulapp/features/auth/domain/usecases/get_current_user.dart';
import 'package:doulapp/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:doulapp/features/auth/domain/usecases/sign_out.dart';
import 'package:doulapp/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  const email = 'ana@icesi.edu.co';
  const password = 'contrasena-larga';
  const user = AuthUser(id: 'uuid-1', email: email);
  const params = EmailPasswordParams(email: email, password: password);

  setUp(() => repository = MockAuthRepository());

  test('SignUpWithEmail delega en el repositorio con el nombre', () async {
    when(
      () => repository.signUp(
        email: email,
        password: password,
        displayName: 'Ana',
      ),
    ).thenAnswer((_) async => const Right(user));

    final result = await SignUpWithEmail(repository)(
      const SignUpParams(email: email, password: password, displayName: 'Ana'),
    );

    expect(result, const Right<Failure, AuthUser>(user));
    verify(
      () => repository.signUp(
        email: email,
        password: password,
        displayName: 'Ana',
      ),
    ).called(1);
  });

  test('SignInWithEmail propaga el fallo sin reescribirlo', () async {
    when(() => repository.signIn(email: email, password: password))
        .thenAnswer((_) async => const Left(InvalidCredentialsFailure()));

    final result = await SignInWithEmail(repository)(params);

    expect(result, const Left<Failure, AuthUser>(InvalidCredentialsFailure()));
  });

  test('SignOut delega en el repositorio', () async {
    when(() => repository.signOut()).thenAnswer((_) async => const Right(null));

    final result = await SignOut(repository)(const NoParams());

    expect(result.isRight(), isTrue);
    verify(() => repository.signOut()).called(1);
  });

  test('GetCurrentUser devuelve null cuando no hay sesión', () async {
    when(() => repository.getCurrentUser())
        .thenAnswer((_) async => const Right(null));

    final result = await GetCurrentUser(repository)(const NoParams());

    expect(result, const Right<Failure, AuthUser?>(null));
  });
}
