import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/usecases/auth_params.dart';
import 'package:doulapp/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:doulapp/features/auth/presentation/bloc/register_bloc.dart';
import 'package:doulapp/features/auth/presentation/bloc/register_event.dart';
import 'package:doulapp/features/auth/presentation/bloc/register_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSignUpWithEmail extends Mock implements SignUpWithEmail {}

void main() {
  late MockSignUpWithEmail signUp;

  const user = AuthUser(id: 'uuid-1', email: 'ana@icesi.edu.co');

  setUpAll(() {
    registerFallbackValue(
      const EmailPasswordParams(
        email: 'ana@icesi.edu.co',
        password: 'password123',
      ),
    );
  });

  setUp(() {
    signUp = MockSignUpWithEmail();
  });

  RegisterBloc buildBloc() => RegisterBloc(signUp: signUp);

  group('RegisterSubmitted', () {
    blocTest<RegisterBloc, RegisterState>(
      'emite [RegisterLoading, RegisterSuccess] cuando el registro es exitoso',
      build: () {
        when(
          () => signUp(
            const EmailPasswordParams(
              email: 'ana@icesi.edu.co',
              password: 'password123',
            ),
          ),
        ).thenAnswer((_) async => const Right(user));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const RegisterSubmitted(
          email: '  ana@icesi.edu.co  ',
          password: 'password123',
        ),
      ),
      expect: () => [
        const RegisterLoading(),
        const RegisterSuccess(user),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'emite [RegisterFailure] sin llamar al caso de uso si el correo es inválido',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const RegisterSubmitted(email: 'sin-arroba', password: 'password123'),
      ),
      expect: () => [
        RegisterFailure(const InvalidEmailFailure().message),
      ],
      verify: (_) {
        verifyNever(() => signUp(any()));
      },
    );

    blocTest<RegisterBloc, RegisterState>(
      'emite [RegisterFailure] sin llamar al caso de uso si la contraseña tiene menos de 8 caracteres',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const RegisterSubmitted(email: 'ana@icesi.edu.co', password: '1234567'),
      ),
      expect: () => [
        RegisterFailure(const WeakPasswordFailure().message),
      ],
      verify: (_) {
        verifyNever(() => signUp(any()));
      },
    );

    blocTest<RegisterBloc, RegisterState>(
      'emite [RegisterLoading, RegisterFailure] cuando el correo ya está registrado',
      build: () {
        when(() => signUp(any())).thenAnswer(
          (_) async => const Left(EmailAlreadyRegisteredFailure()),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const RegisterSubmitted(
          email: 'ana@icesi.edu.co',
          password: 'password123',
        ),
      ),
      expect: () => [
        const RegisterLoading(),
        RegisterFailure(const EmailAlreadyRegisteredFailure().message),
      ],
    );
  });
}
