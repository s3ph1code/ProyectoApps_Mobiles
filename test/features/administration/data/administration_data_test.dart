import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/exceptions.dart' as app;
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/administration/data/datasources/role_admin_remote_datasource.dart';
import 'package:doulapp/features/administration/data/models/managed_user_model.dart';
import 'package:doulapp/features/administration/data/repositories/role_admin_repository_impl.dart';
import 'package:doulapp/features/profile/domain/entities/app_role.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../fixtures.dart';

class MockDataSource extends Mock implements RoleAdminRemoteDataSource {}

void main() {
  setUpAll(() => registerFallbackValue(AppRole.moderator));

  group('ManagedUserModel', () {
    test('lee los roles embebidos de un perfil', () {
      final model = ManagedUserModel.fromProfileJson(profileRowLucia);

      expect(model.displayName, 'Lucía');
      expect(model.roles, [AppRole.user, AppRole.moderator]);
      expect(model.isModerator, isTrue);
      expect(model.primaryRole, AppRole.moderator);
    });

    test('un perfil sin roles es solo usuaria', () {
      final model = ManagedUserModel.fromProfileJson(const {
        'id': 'x',
        'display_name': null,
        'user_roles': <dynamic>[],
      });

      expect(model.roles, isEmpty);
      expect(model.primaryRole, AppRole.user);
      expect(model.displayName, isNull);
    });

    test('ignora roles desconocidos', () {
      final model = ManagedUserModel.fromProfileJson(const {
        'id': 'x',
        'display_name': 'X',
        'user_roles': [
          {
            'roles': {'code': 'rey'},
          },
        ],
      });
      expect(model.roles, isEmpty);
    });

    test('agrupa las filas del equipo por usuaria', () {
      final team = ManagedUserModel.groupTeamRows(teamRows);

      expect(team.map((u) => u.id), ['lucia-id', 'root-id']);
      expect(team.first.roles, [AppRole.moderator, AppRole.admin]);
      expect(team.first.displayName, 'Lucía');
    });
  });

  group('ManagedUser', () {
    test('withRole y withoutRole cambian solo ese rol', () {
      expect(ana.withRole(AppRole.moderator).isModerator, isTrue);
      expect(lucia.withoutRole(AppRole.moderator).isModerator, isFalse);
      expect(lucia.withoutRole(AppRole.moderator).roles, [AppRole.user]);
      expect(lucia.withRole(AppRole.moderator), lucia);
    });
  });

  group('RoleAdminRemoteDataSourceImpl', () {
    late List<http.Request> requests;
    late RoleAdminRemoteDataSourceImpl dataSource;

    void useResponses(List<Object> bodies, {int status = 200}) {
      var index = 0;
      final client = supabase.SupabaseClient(
        'http://localhost:54321',
        'public-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          final body =
              bodies[index < bodies.length ? index : bodies.length - 1];
          index++;
          return http.Response(
            jsonEncode(body),
            status,
            request: request,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      dataSource = RoleAdminRemoteDataSourceImpl(client: client);
    }

    setUp(() => requests = []);

    test('getTeam pide solo moderadoras y administradoras', () async {
      useResponses([teamRows]);

      final team = await dataSource.getTeam();

      final request = requests.single;
      expect(request.url.path, '/rest/v1/user_roles');
      expect(
        request.url.queryParameters['roles.code'],
        'in.("moderator","admin")',
      );
      expect(team.map((u) => u.id), ['lucia-id', 'root-id']);
    });

    test('searchUsers filtra por nombre, con límite y orden', () async {
      useResponses([
        [profileRowAna],
      ]);

      final users = await dataSource.searchUsers('An');

      final request = requests.single;
      expect(request.url.path, '/rest/v1/profiles');
      expect(request.url.queryParameters['display_name'], 'ilike.%An%');
      expect(request.url.queryParameters['limit'], '20');
      expect(
        request.url.queryParameters['order'],
        startsWith('display_name.asc'),
      );
      expect(users.single.props, anaModel.props);
    });

    test('searchUsers busca los comodines como texto', () async {
      useResponses([<dynamic>[]]);

      await dataSource.searchUsers('50%_x');

      expect(
        requests.single.url.queryParameters['display_name'],
        r'ilike.%50\%\_x%',
      );
    });

    test(
      'assignRole busca el id del rol y lo inserta ignorando duplicados',
      () async {
        useResponses([
          {'id': 2},
          <dynamic>[],
        ]);

        await dataSource.assignRole(userId: 'ana-id', role: AppRole.moderator);

        expect(requests.first.url.path, '/rest/v1/roles');
        expect(requests.first.url.queryParameters['code'], 'eq.moderator');
        final insert = requests.last;
        expect(insert.method, 'POST');
        expect(insert.url.path, '/rest/v1/user_roles');
        expect(insert.headers['Prefer'], contains('ignore-duplicates'));
        expect(jsonDecode(insert.body), {'user_id': 'ana-id', 'role_id': 2});
      },
    );

    test('removeRole borra solo esa pareja usuaria-rol', () async {
      useResponses([
        {'id': 2},
        <dynamic>[],
      ]);

      await dataSource.removeRole(userId: 'lucia-id', role: AppRole.moderator);

      final delete = requests.last;
      expect(delete.method, 'DELETE');
      expect(delete.url.path, '/rest/v1/user_roles');
      expect(delete.url.queryParameters['user_id'], 'eq.lucia-id');
      expect(delete.url.queryParameters['role_id'], 'eq.2');
    });

    test('un error de la base se vuelve ServerException', () async {
      useResponses([
        {'code': '42501', 'message': 'denied'},
      ], status: 403);

      expect(() => dataSource.getTeam(), throwsA(isA<app.ServerException>()));
    });
  });

  group('RoleAdminRepositoryImpl', () {
    late MockDataSource dataSource;
    late RoleAdminRepositoryImpl repository;

    setUp(() {
      dataSource = MockDataSource();
      repository = RoleAdminRepositoryImpl(remoteDataSource: dataSource);
    });

    test('sin texto pide el equipo; con texto, la búsqueda', () async {
      when(() => dataSource.getTeam()).thenAnswer((_) async => [anaModel]);
      when(
        () => dataSource.searchUsers('Ana'),
      ).thenAnswer((_) async => [anaModel]);

      await repository.searchUsers('');
      await repository.searchUsers('Ana');

      verify(() => dataSource.getTeam()).called(1);
      verify(() => dataSource.searchUsers('Ana')).called(1);
    });

    test('assignRole y removeRole devuelven unit', () async {
      when(
        () => dataSource.assignRole(userId: 'a', role: AppRole.moderator),
      ).thenAnswer((_) async {});
      when(
        () => dataSource.removeRole(userId: 'a', role: AppRole.moderator),
      ).thenAnswer((_) async {});

      expect(
        await repository.assignRole(userId: 'a', role: AppRole.moderator),
        const Right<Failure, Unit>(unit),
      );
      expect(
        await repository.removeRole(userId: 'a', role: AppRole.moderator),
        const Right<Failure, Unit>(unit),
      );
    });

    group('mapea las excepciones a fallos', () {
      Future<Either<Failure, dynamic>> failingWith(Object error) {
        when(() => dataSource.getTeam()).thenThrow(error);
        return repository.searchUsers('');
      }

      test('red', () async {
        expect(
          await failingWith(const app.NetworkException('x')),
          const Left<Failure, dynamic>(NetworkFailure()),
        );
      });
      test('servidor', () async {
        expect(
          await failingWith(const app.ServerException('x')),
          const Left<Failure, dynamic>(ServerFailure()),
        );
      });
      test('sesión', () async {
        expect(
          await failingWith(const app.UnauthenticatedException()),
          const Left<Failure, dynamic>(UnauthenticatedFailure()),
        );
      });
      test('inesperado', () async {
        expect(
          await failingWith(StateError('x')),
          const Left<Failure, dynamic>(UnexpectedFailure()),
        );
      });
    });
  });
}
