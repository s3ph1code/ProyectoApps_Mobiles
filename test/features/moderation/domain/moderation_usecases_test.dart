import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/auth/domain/entities/auth_user.dart';
import 'package:doulapp/features/auth/domain/usecases/get_current_user.dart';
import 'package:doulapp/features/moderation/domain/entities/report_status.dart';
import 'package:doulapp/features/moderation/domain/entities/reported_content.dart';
import 'package:doulapp/features/moderation/domain/repositories/moderation_repository.dart';
import 'package:doulapp/features/moderation/domain/usecases/get_reports.dart';
import 'package:doulapp/features/moderation/domain/usecases/moderate_content.dart';
import 'package:doulapp/features/moderation/domain/usecases/resolve_moderator.dart';
import 'package:doulapp/features/moderation/domain/usecases/update_report_status.dart';
import 'package:doulapp/features/profile/domain/entities/app_role.dart';
import 'package:doulapp/features/profile/domain/usecases/get_user_roles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockGetUserRoles extends Mock implements GetUserRoles {}

class MockRepository extends Mock implements ModerationRepository {}

void main() {
  late MockGetCurrentUser getCurrentUser;
  late MockGetUserRoles getUserRoles;
  late MockRepository repository;
  late ResolveModerator resolveModerator;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetUserRolesParams(userId: 'x'));
    registerFallbackValue(ReportStatus.pending);
    registerFallbackValue(ReportedContentKind.post);
    registerFallbackValue(ContentStatus.hidden);
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    getUserRoles = MockGetUserRoles();
    repository = MockRepository();
    resolveModerator = ResolveModerator(
      getCurrentUser: getCurrentUser,
      getUserRoles: getUserRoles,
    );
    when(() => getCurrentUser(any())).thenAnswer(
      (_) async => const Right(AuthUser(id: 'mod', email: 'm@doulapp.co')),
    );
  });

  void rolesAre(List<AppRole> roles) =>
      when(() => getUserRoles(any())).thenAnswer((_) async => Right(roles));

  group('ResolveModerator', () {
    test('acepta a una moderadora', () async {
      rolesAre([AppRole.moderator]);
      final result = await resolveModerator(const NoParams());
      expect(result.map((m) => m.userId), const Right<Failure, String>('mod'));
    });

    test('acepta a una administradora', () async {
      rolesAre([AppRole.admin]);
      expect((await resolveModerator(const NoParams())).isRight(), isTrue);
    });

    test('rechaza a una usuaria', () async {
      rolesAre([AppRole.user]);
      expect(
        (await resolveModerator(
          const NoParams(),
        )).swap().getOrElse(() => const UnexpectedFailure()),
        const ForbiddenFailure(),
      );
    });

    test('sin sesión no hay acceso', () async {
      when(
        () => getCurrentUser(any()),
      ).thenAnswer((_) async => const Right(null));
      final result = await resolveModerator(const NoParams());
      expect(result, const Left<Failure, dynamic>(UnauthenticatedFailure()));
      verifyNever(() => getUserRoles(any()));
    });

    test('reenvía el fallo al leer los roles', () async {
      when(
        () => getUserRoles(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      expect(
        await resolveModerator(const NoParams()),
        const Left<Failure, dynamic>(NetworkFailure()),
      );
    });
  });

  group('GetReports', () {
    late GetReports getReports;
    setUp(
      () => getReports = GetReports(
        resolveModerator: resolveModerator,
        repository: repository,
      ),
    );

    test('pide los reportes pendientes por defecto', () async {
      rolesAre([AppRole.moderator]);
      when(
        () => repository.getReports(ReportStatus.pending),
      ).thenAnswer((_) async => Right([postReport]));

      final result = await getReports(const GetReportsParams());

      expect(result.getOrElse(() => []), [postReport]);
    });

    test('una usuaria no llega al repositorio', () async {
      rolesAre([AppRole.user]);

      final result = await getReports(const GetReportsParams());

      expect(result, const Left<Failure, dynamic>(ForbiddenFailure()));
      verifyZeroInteractions(repository);
    });
  });

  group('UpdateReportStatus', () {
    late UpdateReportStatus update;
    setUp(
      () => update = UpdateReportStatus(
        resolveModerator: resolveModerator,
        repository: repository,
      ),
    );

    test('guarda el estado con quién lo revisó', () async {
      rolesAre([AppRole.moderator]);
      when(
        () => repository.updateReportStatus(
          reportId: 'rep-1',
          status: ReportStatus.reviewing,
          reviewerId: 'mod',
        ),
      ).thenAnswer((_) async => const Right(unit));

      final result = await update(
        const UpdateReportStatusParams(
          reportId: 'rep-1',
          status: ReportStatus.reviewing,
        ),
      );

      expect(result, const Right<Failure, Unit>(unit));
    });

    test('una usuaria no puede cambiar reportes', () async {
      rolesAre([AppRole.user]);
      final result = await update(
        const UpdateReportStatusParams(
          reportId: 'rep-1',
          status: ReportStatus.dismissed,
        ),
      );
      expect(result, const Left<Failure, dynamic>(ForbiddenFailure()));
      verifyZeroInteractions(repository);
    });
  });

  group('ModerateContent', () {
    late ModerateContent moderate;
    const params = ModerateContentParams(
      reportId: 'rep-1',
      kind: ReportedContentKind.post,
      contentId: 'post-1',
      action: ModerationAction.hide,
    );

    setUp(
      () => moderate = ModerateContent(
        resolveModerator: resolveModerator,
        repository: repository,
      ),
    );

    void contentChangeSucceeds() => when(
      () => repository.setContentStatus(
        kind: ReportedContentKind.post,
        contentId: 'post-1',
        status: ContentStatus.hidden,
      ),
    ).thenAnswer((_) async => const Right(unit));

    test('oculta el contenido y deja el reporte resuelto', () async {
      rolesAre([AppRole.moderator]);
      contentChangeSucceeds();
      when(
        () => repository.updateReportStatus(
          reportId: 'rep-1',
          status: ReportStatus.resolved,
          reviewerId: 'mod',
        ),
      ).thenAnswer((_) async => const Right(unit));

      expect(await moderate(params), const Right<Failure, Unit>(unit));
      verify(
        () => repository.updateReportStatus(
          reportId: 'rep-1',
          status: ReportStatus.resolved,
          reviewerId: 'mod',
        ),
      ).called(1);
    });

    test('eliminar usa el estado removed', () async {
      rolesAre([AppRole.admin]);
      when(
        () => repository.setContentStatus(
          kind: ReportedContentKind.comment,
          contentId: 'c-1',
          status: ContentStatus.removed,
        ),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => repository.updateReportStatus(
          reportId: 'rep-2',
          status: ReportStatus.resolved,
          reviewerId: 'mod',
        ),
      ).thenAnswer((_) async => const Right(unit));

      final result = await moderate(
        const ModerateContentParams(
          reportId: 'rep-2',
          kind: ReportedContentKind.comment,
          contentId: 'c-1',
          action: ModerationAction.remove,
        ),
      );

      expect(result.isRight(), isTrue);
    });

    test('si el contenido no cambia, el reporte queda como estaba', () async {
      rolesAre([AppRole.moderator]);
      when(
        () => repository.setContentStatus(
          kind: any(named: 'kind'),
          contentId: any(named: 'contentId'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final result = await moderate(params);

      expect(result, const Left<Failure, dynamic>(ServerFailure()));
      verifyNever(
        () => repository.updateReportStatus(
          reportId: any(named: 'reportId'),
          status: any(named: 'status'),
          reviewerId: any(named: 'reviewerId'),
        ),
      );
    });

    test('una usuaria no puede moderar', () async {
      rolesAre([AppRole.user]);
      expect(
        await moderate(params),
        const Left<Failure, dynamic>(ForbiddenFailure()),
      );
      verifyZeroInteractions(repository);
    });
  });
}
