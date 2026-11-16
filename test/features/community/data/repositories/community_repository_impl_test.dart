import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/exceptions.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/community/data/datasources/community_remote_datasource.dart';
import 'package:doulapp/features/community/data/models/post_model.dart';
import 'package:doulapp/features/community/data/repositories/community_repository_impl.dart';
import 'package:doulapp/features/community/domain/entities/post_type.dart';
import 'package:doulapp/features/community/domain/entities/post_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCommunityRemoteDataSource extends Mock
    implements CommunityRemoteDataSource {}

void main() {
  late MockCommunityRemoteDataSource dataSource;
  late CommunityRepositoryImpl repository;

  final model = PostModel(
    id: 'p1',
    authorId: 'author-1',
    type: PostType.message,
    body: 'Hola',
    visibility: PostVisibility.community,
    createdAt: DateTime.utc(2026, 11, 10),
  );

  setUp(() {
    dataSource = MockCommunityRemoteDataSource();
    repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
  });

  test('getPosts devuelve las publicaciones en Right', () async {
    when(
      () => dataSource.fetchPosts(categoryId: 'cat-1', offset: 0, limit: 20),
    ).thenAnswer((_) async => [model]);

    final result = await repository.getPosts(
      categoryId: 'cat-1',
      offset: 0,
      limit: 20,
    );

    expect(result.getOrElse(() => []), [model]);
  });

  group('convierte las excepciones en Failure', () {
    final cases = <Exception, Failure>{
      const NotFoundException(): const PostNotFoundFailure(),
      const NetworkException('x'): const NetworkFailure(),
      const ServerException('x'): const ServerFailure(),
      const AuthException('x'): const UnauthenticatedFailure(),
      const UnauthenticatedException(): const UnauthenticatedFailure(),
    };

    cases.forEach((exception, failure) {
      test('${exception.runtimeType} → ${failure.runtimeType}', () async {
        when(() => dataSource.fetchPostById('p1')).thenThrow(exception);

        final result = await repository.getPostById('p1');

        expect(result, Left(failure));
      });
    });

    test('un error inesperado → UnexpectedFailure', () async {
      when(() => dataSource.fetchComments('p1')).thenThrow(StateError('x'));

      final result = await repository.getComments('p1');

      expect(result, const Left(UnexpectedFailure()));
    });
  });

  test(
    'createPost publica con los códigos de la base y devuelve la publicación',
    () async {
      when(
        () => dataSource.createPost(
          postType: 'question',
          body: 'Hola',
          visibility: 'public',
          categoryIds: ['cat-1'],
        ),
      ).thenAnswer((_) async => 'p1');
      when(() => dataSource.fetchPostById('p1')).thenAnswer((_) async => model);

      final result = await repository.createPost(
        type: PostType.question,
        body: 'Hola',
        visibility: PostVisibility.public,
        categoryIds: ['cat-1'],
      );

      expect(result, Right(model));
    },
  );

  test('createPost con error de red → NetworkFailure', () async {
    when(
      () => dataSource.createPost(
        postType: any(named: 'postType'),
        body: any(named: 'body'),
        visibility: any(named: 'visibility'),
        categoryIds: any(named: 'categoryIds'),
      ),
    ).thenThrow(const NetworkException('sin red'));

    final result = await repository.createPost(
      type: PostType.message,
      body: 'Hola',
      visibility: PostVisibility.community,
      categoryIds: ['cat-1'],
    );

    expect(result, const Left(NetworkFailure()));
  });
}
