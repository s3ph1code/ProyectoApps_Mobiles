import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/usecases/auth_params.dart';
import 'package:doulapp/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:doulapp/features/auth/presentation/bloc/login_bloc.dart';
import 'package:doulapp/features/auth/presentation/bloc/login_event.dart';
import 'package:doulapp/features/auth/presentation/bloc/login_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSignInWithEmail extends Mock implements SignInWithEmail {}

void main() {
  late MockSignInWithEmail signIn;

  const user = AuthUser(id: 'uuid-1', email: 'ana@icesi.edu.co');

  setUpAll(() {
    registerFallbackValue(
      const EmailPasswordParams(email: 'ana@icesi.edu.co', password: 'secret'),
    );
  });

  setUp(() {
    signIn = MockSignInWithEmail();
  });

  LoginBloc buildBloc() => LoginBloc(signIn: signIn);

  group('LoginSubmitted', () {
    blocTest<LoginBloc, LoginState>(
      'emite [LoginLoading, LoginSuccess] cuando las credenciales son válidas',
      build: () {
        when(
          () => signIn(
            const EmailPasswordParams(
              email: 'ana@icesi.edu.co',
              password: 'password123',
            ),
          ),
        ).thenAnswer((_) async => const Right(user));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const LoginSubmitted(
          email: '  ana@icesi.edu.co  ',
          password: 'password123',
        ),
      ),
      expect: () => [
        const LoginLoading(),
        const LoginSuccess(user),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'emite [LoginFailure] sin llamar al caso de uso si el correo es inválido',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const LoginSubmitted(email: 'correo-invalido', password: 'password123'),
      ),
      expect: () => [
        LoginFailure(const InvalidEmailFailure().message),
      ],
      verify: (_) {
        verifyNever(() => signIn(any()));
      },
    );

    blocTest<LoginBloc, LoginState>(
      'emite [LoginFailure] sin llamar al caso de uso si la contraseña está vacía',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const LoginSubmitted(email: 'ana@icesi.edu.co', password: ''),
      ),
      expect: () => [
        const LoginFailure('Escribe tu contraseña para continuar.'),
      ],
      verify: (_) {
        verifyNever(() => signIn(any()));
      },
    );

    blocTest<LoginBloc, LoginState>(
      'emite [LoginLoading, LoginFailure] cuando las credenciales fallan en Supabase',
      build: () {
        when(() => signIn(any())).thenAnswer(
          (_) async => const Left(InvalidCredentialsFailure()),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const LoginSubmitted(
          email: 'ana@icesi.edu.co',
          password: 'wrongpassword',
        ),
      ),
      expect: () => [
        const LoginLoading(),
        LoginFailure(const InvalidCredentialsFailure().message),
      ],
    );
  });
}
