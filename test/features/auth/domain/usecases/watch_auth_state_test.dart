import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:doulapp/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('WatchAuthState reenvía los cambios de sesión del repositorio', () {
    final repository = MockAuthRepository();
    const user = AuthUser(id: 'uuid-1', email: 'ana@icesi.edu.co');
    when(() => repository.authStateChanges())
        .thenAnswer((_) => Stream.fromIterable([user, null]));

    final stream = WatchAuthState(repository)(const NoParams());

    expect(stream, emitsInOrder([user, null]));
  });
}
