import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/community/domain/entities/post.dart';
import 'package:doulapp/features/community/domain/usecases/get_community_categories.dart';
import 'package:doulapp/features/community/domain/usecases/get_posts.dart';
import 'package:doulapp/features/community/presentation/bloc/feed_bloc.dart';
import 'package:doulapp/features/community/presentation/bloc/feed_event.dart';
import 'package:doulapp/features/community/presentation/bloc/feed_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures.dart';

class MockGetCommunityCategories extends Mock
    implements GetCommunityCategories {}

class MockGetPosts extends Mock implements GetPosts {}

void main() {
  late MockGetCommunityCategories getCategories;
  late MockGetPosts getPosts;

  final firstPage = makePosts(20);
  final secondPage = makePosts(5, start: 20);

  FeedBloc build() =>
      FeedBloc(getCommunityCategories: getCategories, getPosts: getPosts);

  FeedLoaded loaded(
    List<Post> posts, {
    String? category,
    bool hasMore = false,
  }) => FeedLoaded(
    categories: testCategories,
    posts: posts,
    selectedCategoryId: category,
    hasMore: hasMore,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetPostsParams());
  });

  setUp(() {
    getCategories = MockGetCommunityCategories();
    getPosts = MockGetPosts();
    when(
      () => getCategories(any()),
    ).thenAnswer((_) async => const Right(testCategories));
    when(
      () => getPosts(const GetPostsParams()),
    ).thenAnswer((_) async => Right(firstPage));
  });

  blocTest<FeedBloc, FeedState>(
    'al abrir carga las categorías y la primera página',
    build: build,
    act: (bloc) => bloc.add(const FeedRequested()),
    expect: () => [const FeedLoading(), loaded(firstPage, hasMore: true)],
  );

  blocTest<FeedBloc, FeedState>(
    'una página incompleta indica que no hay más',
    build: build,
    setUp: () => when(
      () => getPosts(const GetPostsParams()),
    ).thenAnswer((_) async => Right(secondPage)),
    act: (bloc) => bloc.add(const FeedRequested()),
    expect: () => [const FeedLoading(), loaded(secondPage)],
  );

  blocTest<FeedBloc, FeedState>(
    'si fallan las categorías muestra el error',
    build: build,
    setUp: () => when(
      () => getCategories(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure())),
    act: (bloc) => bloc.add(const FeedRequested()),
    expect: () => [
      const FeedLoading(),
      FeedFailure(const NetworkFailure().message),
    ],
  );

  blocTest<FeedBloc, FeedState>(
    'al llegar al final agrega la página siguiente',
    build: build,
    seed: () => loaded(firstPage, hasMore: true),
    setUp: () => when(
      () => getPosts(const GetPostsParams(offset: 20)),
    ).thenAnswer((_) async => Right(secondPage)),
    act: (bloc) => bloc.add(const FeedNextPageRequested()),
    expect: () => [
      loaded(firstPage, hasMore: true).copyWith(isLoadingMore: true),
      loaded([...firstPage, ...secondPage]),
    ],
  );

  blocTest<FeedBloc, FeedState>(
    'no pide más páginas cuando ya no hay',
    build: build,
    seed: () => loaded(secondPage),
    act: (bloc) => bloc.add(const FeedNextPageRequested()),
    expect: () => <FeedState>[],
    verify: (_) => verifyNever(() => getPosts(any())),
  );

  blocTest<FeedBloc, FeedState>(
    'dos avisos seguidos de fin de lista piden la página una sola vez',
    build: build,
    seed: () => loaded(firstPage, hasMore: true),
    setUp: () => when(
      () => getPosts(const GetPostsParams(offset: 20)),
    ).thenAnswer((_) async => Right(secondPage)),
    act: (bloc) => bloc
      ..add(const FeedNextPageRequested())
      ..add(const FeedNextPageRequested()),
    verify: (_) =>
        verify(() => getPosts(const GetPostsParams(offset: 20))).called(1),
  );

  blocTest<FeedBloc, FeedState>(
    'si falla la página siguiente conserva lo cargado y permite reintentar',
    build: build,
    seed: () => loaded(firstPage, hasMore: true),
    setUp: () => when(
      () => getPosts(const GetPostsParams(offset: 20)),
    ).thenAnswer((_) async => const Left(NetworkFailure())),
    act: (bloc) => bloc.add(const FeedNextPageRequested()),
    expect: () => [
      loaded(firstPage, hasMore: true).copyWith(isLoadingMore: true),
      loaded(
        firstPage,
        hasMore: true,
      ).copyWith(loadMoreError: const NetworkFailure().message),
    ],
  );

  blocTest<FeedBloc, FeedState>(
    'no repite una publicación que ya estaba en la lista',
    build: build,
    seed: () => loaded(firstPage, hasMore: true),
    setUp: () => when(
      () => getPosts(const GetPostsParams(offset: 20)),
    ).thenAnswer((_) async => Right([firstPage.last, ...secondPage])),
    act: (bloc) => bloc.add(const FeedNextPageRequested()),
    skip: 1,
    expect: () => [
      loaded([...firstPage, ...secondPage]),
    ],
  );

  blocTest<FeedBloc, FeedState>(
    'filtrar por categoría vuelve a la primera página de esa categoría',
    build: build,
    seed: () => loaded(firstPage, hasMore: true),
    setUp: () => when(
      () => getPosts(const GetPostsParams(categoryId: 'cat-2')),
    ).thenAnswer((_) async => Right(secondPage)),
    act: (bloc) => bloc.add(const FeedCategorySelected('cat-2')),
    expect: () => [
      loaded(
        firstPage,
        category: 'cat-2',
        hasMore: true,
      ).copyWith(isReloading: true),
      loaded(secondPage, category: 'cat-2'),
    ],
  );

  blocTest<FeedBloc, FeedState>(
    '«Todas» quita el filtro',
    build: build,
    seed: () => loaded(secondPage, category: 'cat-2'),
    act: (bloc) => bloc.add(const FeedCategorySelected(null)),
    expect: () => [
      loaded(secondPage).copyWith(isReloading: true),
      loaded(firstPage, hasMore: true),
    ],
  );

  blocTest<FeedBloc, FeedState>(
    'actualizar mantiene la categoría elegida',
    build: build,
    seed: () => loaded(secondPage, category: 'cat-2'),
    setUp: () => when(
      () => getPosts(const GetPostsParams(categoryId: 'cat-2')),
    ).thenAnswer((_) async => Right(secondPage)),
    act: (bloc) => bloc.add(const FeedRefreshed()),
    expect: () => [
      loaded(secondPage, category: 'cat-2').copyWith(isReloading: true),
      loaded(secondPage, category: 'cat-2'),
    ],
  );

  blocTest<FeedBloc, FeedState>(
    'una página que llega después de cambiar de categoría se descarta',
    build: build,
    seed: () => loaded(firstPage, hasMore: true),
    setUp: () {
      final slowPage = Completer<Either<Failure, List<Post>>>();
      when(
        () => getPosts(const GetPostsParams(offset: 20)),
      ).thenAnswer((_) => slowPage.future);
      when(
        () => getPosts(const GetPostsParams(categoryId: 'cat-2')),
      ).thenAnswer((_) async {
        slowPage.complete(Right(makePosts(20, start: 100)));
        return Right(secondPage);
      });
    },
    act: (bloc) async {
      bloc.add(const FeedNextPageRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const FeedCategorySelected('cat-2'));
    },
    wait: const Duration(milliseconds: 50),
    verify: (bloc) => expect(bloc.state, loaded(secondPage, category: 'cat-2')),
  );
}
