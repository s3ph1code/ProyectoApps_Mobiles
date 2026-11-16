import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/community/domain/entities/post_type.dart';
import 'package:doulapp/features/community/domain/entities/post_visibility.dart';
import 'package:doulapp/features/community/domain/repositories/community_repository.dart';
import 'package:doulapp/features/community/domain/usecases/create_post.dart';
import 'package:doulapp/features/community/domain/usecases/get_community_categories.dart';
import 'package:doulapp/features/community/domain/usecases/get_post_by_id.dart';
import 'package:doulapp/features/community/domain/usecases/get_post_comments.dart';
import 'package:doulapp/features/community/domain/usecases/get_posts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures.dart';

class MockCommunityRepository extends Mock implements CommunityRepository {}

void main() {
  late MockCommunityRepository repository;

  setUpAll(() {
    registerFallbackValue(PostType.message);
    registerFallbackValue(PostVisibility.community);
  });

  setUp(() => repository = MockCommunityRepository());

  group('GetCommunityCategories', () {
    test('devuelve las categorías del repositorio', () async {
      when(
        () => repository.getCategories(),
      ).thenAnswer((_) async => const Right(testCategories));

      final result = await GetCommunityCategories(repository)(const NoParams());

      expect(result, const Right(testCategories));
    });
  });

  group('GetPosts', () {
    setUp(() {
      when(
        () => repository.getPosts(
          categoryId: any(named: 'categoryId'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Right(makePosts(2)));
    });

    test('pide páginas de 20 desde el desplazamiento indicado', () async {
      await GetPosts(repository)(
        const GetPostsParams(categoryId: 'cat-1', offset: 40),
      );

      verify(
        () => repository.getPosts(categoryId: 'cat-1', offset: 40, limit: 20),
      ).called(1);
    });

    test('una categoría en blanco equivale a «Todas»', () async {
      await GetPosts(repository)(const GetPostsParams(categoryId: '  '));

      verify(
        () => repository.getPosts(categoryId: null, offset: 0, limit: 20),
      ).called(1);
    });

    test('un desplazamiento negativo empieza desde el principio', () async {
      await GetPosts(repository)(const GetPostsParams(offset: -5));

      verify(
        () => repository.getPosts(categoryId: null, offset: 0, limit: 20),
      ).called(1);
    });
  });

  group('GetPostById', () {
    test('un id vacío no consulta y responde que no existe', () async {
      final result = await GetPostById(repository)(
        const GetPostByIdParams(postId: ' '),
      );

      expect(result, const Left(PostNotFoundFailure()));
      verifyNever(() => repository.getPostById(any()));
    });

    test('consulta el id sin espacios', () async {
      final post = makePost('p1');
      when(
        () => repository.getPostById('p1'),
      ).thenAnswer((_) async => Right(post));

      final result = await GetPostById(repository)(
        const GetPostByIdParams(postId: ' p1 '),
      );

      expect(result, Right(post));
    });
  });

  group('GetPostComments', () {
    test('ordena cada comentario seguido de sus respuestas', () async {
      when(() => repository.getComments('p0')).thenAnswer(
        (_) async => Right([
          makeComment('c3', minute: 3),
          makeComment('r1', parent: 'c1', minute: 2),
          makeComment('c1', minute: 1),
          makeComment('r2', parent: 'r1', minute: 4),
        ]),
      );

      final result = await GetPostComments(repository)(
        const GetPostCommentsParams(postId: 'p0'),
      );

      final ids = result.getOrElse(() => []).map((c) => c.id).toList();
      expect(ids, ['c1', 'r1', 'r2', 'c3']);
    });

    test('una respuesta sin su comentario original no se pierde', () {
      final ordered = GetPostComments.threadComments([
        makeComment('r1', parent: 'oculto', minute: 2),
        makeComment('c1', minute: 1),
      ]);

      expect(ordered.map((c) => c.id), ['c1', 'r1']);
    });

    test('propaga el error del repositorio', () async {
      when(
        () => repository.getComments('p0'),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await GetPostComments(repository)(
        const GetPostCommentsParams(postId: 'p0'),
      );

      expect(result, const Left(NetworkFailure()));
    });
  });

  group('CreatePost', () {
    late CreatePost createPost;

    CreatePostParams params({
      String body = 'Hoy salí a caminar.',
      List<String> categoryIds = const ['cat-1'],
    }) {
      return CreatePostParams(
        type: PostType.experience,
        body: body,
        visibility: PostVisibility.public,
        categoryIds: categoryIds,
      );
    }

    setUp(() {
      createPost = CreatePost(repository);
      when(
        () => repository.createPost(
          type: any(named: 'type'),
          body: any(named: 'body'),
          visibility: any(named: 'visibility'),
          categoryIds: any(named: 'categoryIds'),
        ),
      ).thenAnswer((_) async => Right(makePost('nuevo')));
    });

    test('un texto vacío o en blanco no se publica', () async {
      final result = await createPost(params(body: '   \n '));

      expect(result, const Left(EmptyPostBodyFailure()));
      verifyNever(
        () => repository.createPost(
          type: any(named: 'type'),
          body: any(named: 'body'),
          visibility: any(named: 'visibility'),
          categoryIds: any(named: 'categoryIds'),
        ),
      );
    });

    test('más de 2000 caracteres no se publica', () async {
      final result = await createPost(params(body: 'a' * 2001));

      expect(result, const Left(PostBodyTooLongFailure()));
    });

    test('exactamente 2000 caracteres sí se publica', () async {
      final result = await createPost(params(body: 'a' * 2000));

      expect(result.isRight(), isTrue);
    });

    test('sin categoría no se publica', () async {
      final result = await createPost(params(categoryIds: const []));

      expect(result, const Left(PostCategoryRequiredFailure()));
    });

    test(
      'envía el texto sin espacios sobrantes y sin categorías repetidas',
      () async {
        await createPost(
          params(
            body: '  Hoy salí a caminar.  ',
            categoryIds: ['cat-1', 'cat-1', 'cat-2'],
          ),
        );

        verify(
          () => repository.createPost(
            type: PostType.experience,
            body: 'Hoy salí a caminar.',
            visibility: PostVisibility.public,
            categoryIds: ['cat-1', 'cat-2'],
          ),
        ).called(1);
      },
    );
  });
}
