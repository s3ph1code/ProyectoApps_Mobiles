import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/auth/domain/usecases/auth_params.dart';
import 'package:doulapp/features/auth/domain/usecases/send_password_reset.dart';
import 'package:doulapp/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:doulapp/features/auth/presentation/bloc/forgot_password_event.dart';
import 'package:doulapp/features/auth/presentation/bloc/forgot_password_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSendPasswordReset extends Mock implements SendPasswordReset {}

void main() {
  late MockSendPasswordReset sendPasswordReset;

  setUpAll(() {
    registerFallbackValue(const EmailParams(email: 'ana@icesi.edu.co'));
  });

  setUp(() => sendPasswordReset = MockSendPasswordReset());

  ForgotPasswordBloc buildBloc() =>
      ForgotPasswordBloc(sendPasswordReset: sendPasswordReset);

  blocTest<ForgotPasswordBloc, ForgotPasswordState>(
    'emite [Loading, Success] con el correo recortado',
    build: () {
      when(
        () => sendPasswordReset(const EmailParams(email: 'ana@icesi.edu.co')),
      ).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      const ForgotPasswordSubmitted(email: '  ana@icesi.edu.co  '),
    ),
    expect: () => [
      const ForgotPasswordLoading(),
      const ForgotPasswordSuccess('ana@icesi.edu.co'),
    ],
  );

  blocTest<ForgotPasswordBloc, ForgotPasswordState>(
    'emite Failure sin llamar al caso de uso si el correo no es válido',
    build: buildBloc,
    act: (bloc) => bloc.add(const ForgotPasswordSubmitted(email: 'sin-arroba')),
    expect: () => [ForgotPasswordFailure(const InvalidEmailFailure().message)],
    verify: (_) => verifyNever(() => sendPasswordReset(any())),
  );

  blocTest<ForgotPasswordBloc, ForgotPasswordState>(
    'emite Failure sin llamar al caso de uso si el correo está vacío',
    build: buildBloc,
    act: (bloc) => bloc.add(const ForgotPasswordSubmitted(email: '   ')),
    expect: () => [ForgotPasswordFailure(const InvalidEmailFailure().message)],
    verify: (_) => verifyNever(() => sendPasswordReset(any())),
  );

  blocTest<ForgotPasswordBloc, ForgotPasswordState>(
    'emite [Loading, Failure] con el mensaje del fallo',
    build: () {
      when(() => sendPasswordReset(any()))
          .thenAnswer((_) async => const Left(TooManyAttemptsFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      const ForgotPasswordSubmitted(email: 'ana@icesi.edu.co'),
    ),
    expect: () => [
      const ForgotPasswordLoading(),
      ForgotPasswordFailure(const TooManyAttemptsFailure().message),
    ],
  );
}
