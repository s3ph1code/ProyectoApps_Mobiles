import 'package:doulapp/core/theme/app_theme.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/usecases/get_current_user.dart';
import 'package:doulapp/features/blocking/domain/usecases/block_params.dart';
import 'package:doulapp/features/blocking/domain/usecases/block_user.dart';
import 'package:doulapp/features/blocking/domain/usecases/unblock_user.dart';
import 'package:doulapp/features/blocking/presentation/bloc/block_user_bloc.dart';
import 'package:doulapp/features/blocking/presentation/widgets/block_user_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockBlockUser extends Mock implements BlockUser {}

class MockUnblockUser extends Mock implements UnblockUser {}

void main() {
  late MockBlockUser blockUser;
  late MockUnblockUser unblockUser;
  late MockGetCurrentUser getCurrentUser;
  late BlockUserBloc bloc;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const BlockParams(blockerId: 'a', blockedId: 'b'));
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    when(() => getCurrentUser(any())).thenAnswer(
      (_) async => const Right(AuthUser(id: 'me', email: 'me@doulapp.co')),
    );
    blockUser = MockBlockUser();
    unblockUser = MockUnblockUser();
    when(() => blockUser(any())).thenAnswer((_) async => const Right(unit));
    when(() => unblockUser(any())).thenAnswer((_) async => const Right(unit));
  });

  tearDown(() => bloc.close());

  Future<void> show(WidgetTester t, {String? name = 'Ana'}) {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    // El bloc se crea dentro de la prueba para que viva en su zona de tiempo.
    bloc = BlockUserBloc(
      getCurrentUser: getCurrentUser,
      blockUser: blockUser,
      unblockUser: unblockUser,
    );
    return t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: BlocProvider.value(
            value: bloc,
            child: Center(
              child: BlockUserMenu(authorId: 'ana-id', authorName: name),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openConfirmation(WidgetTester t) async {
    await t.tap(find.byKey(const Key('block_menu_ana-id')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('block_menu_option')));
    await t.pumpAndSettle();
  }

  testWidgets('el «⋯» abre una hoja con la opción de bloquear', (t) async {
    await show(t);

    await t.tap(find.byKey(const Key('block_menu_ana-id')));
    await t.pumpAndSettle();

    expect(find.text('Bloquear a Ana'), findsOneWidget);
  });

  testWidgets('pide confirmación con una explicación tranquila', (t) async {
    await show(t);

    await openConfirmation(t);

    expect(find.text('¿Bloquear a Ana?'), findsOneWidget);
    expect(find.textContaining('No se enterará'), findsOneWidget);
    verifyZeroInteractions(blockUser);
  });

  testWidgets('cancelar no bloquea a nadie', (t) async {
    await show(t);
    await openConfirmation(t);

    await t.tap(find.byKey(const Key('block_cancel')));
    await t.pumpAndSettle();

    verifyZeroInteractions(blockUser);
    expect(find.text('Bloqueaste a Ana'), findsNothing);
  });

  testWidgets('confirmar bloquea y avisa con «Deshacer»', (t) async {
    await show(t);
    await openConfirmation(t);

    await t.tap(find.byKey(const Key('block_confirm')));
    await t.pumpAndSettle();

    verify(
      () => blockUser(const BlockParams(blockerId: 'me', blockedId: 'ana-id')),
    ).called(1);
    expect(find.text('Bloqueaste a Ana'), findsOneWidget);

    await t.tap(find.text('Deshacer'));
    await t.pumpAndSettle();

    verify(
      () =>
          unblockUser(const BlockParams(blockerId: 'me', blockedId: 'ana-id')),
    ).called(1);
  });

  testWidgets('sin nombre habla de «esta usuaria»', (t) async {
    await show(t, name: null);

    await t.tap(find.byKey(const Key('block_menu_ana-id')));
    await t.pumpAndSettle();

    expect(find.text('Bloquear a esta usuaria'), findsOneWidget);
  });

  testWidgets('si falla, explica y no promete el bloqueo', (t) async {
    when(
      () => blockUser(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    await show(t);
    await openConfirmation(t);

    await t.tap(find.byKey(const Key('block_confirm')));
    await t.pumpAndSettle();

    expect(find.text(const NetworkFailure().message), findsOneWidget);
    expect(find.text('Bloqueaste a Ana'), findsNothing);
  });
}
