import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/core/usecase/usecase.dart';
import 'package:doulapp/features/community/domain/entities/post_type.dart';
import 'package:doulapp/features/community/domain/entities/post_visibility.dart';
import 'package:doulapp/features/community/domain/usecases/create_post.dart';
import 'package:doulapp/features/community/domain/usecases/get_community_categories.dart';
import 'package:doulapp/features/community/presentation/bloc/create_post_bloc.dart';
import 'package:doulapp/features/community/presentation/bloc/create_post_event.dart';
import 'package:doulapp/features/community/presentation/bloc/create_post_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures.dart';

class MockGetCommunityCategories extends Mock
    implements GetCommunityCategories {}

class MockCreatePost extends Mock implements CreatePost {}

void main() {
  late MockGetCommunityCategories getCategories;
  late MockCreatePost createPost;

  const editing = CreatePostState(
    status: CreatePostStatus.editing,
    categories: testCategories,
  );
  final filled = editing.copyWith(
    type: PostType.question,
    selectedCategoryIds: {'cat-1'},
    visibility: PostVisibility.public,
    body: '¿A alguien más le pasa?',
  );
  final created = makePost('nuevo');

  CreatePostBloc build() => CreatePostBloc(
    getCommunityCategories: getCategories,
    createPost: createPost,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const CreatePostParams(
        type: PostType.message,
        body: '',
        visibility: PostVisibility.community,
        categoryIds: [],
      ),
    );
  });

  setUp(() {
    getCategories = MockGetCommunityCategories();
    createPost = MockCreatePost();
    when(
      () => getCategories(any()),
    ).thenAnswer((_) async => const Right(testCategories));
    when(() => createPost(any())).thenAnswer((_) async => Right(created));
  });

  blocTest<CreatePostBloc, CreatePostState>(
    'al abrir trae las categorías y queda listo para escribir',
    build: build,
    act: (bloc) => bloc.add(const CreatePostStarted()),
    expect: () => [const CreatePostState(), editing],
  );

  blocTest<CreatePostBloc, CreatePostState>(
    'si no llegan las categorías permite reintentar',
    build: build,
    setUp: () => when(
      () => getCategories(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure())),
    act: (bloc) => bloc.add(const CreatePostStarted()),
    skip: 1,
    expect: () => [
      CreatePostState(
        status: CreatePostStatus.categoriesFailure,
        errorMessage: const NetworkFailure().message,
      ),
    ],
  );

  blocTest<CreatePostBloc, CreatePostState>(
    'elegir una categoría dos veces la quita',
    build: build,
    seed: () => editing,
    act: (bloc) => bloc
      ..add(const CreatePostCategoryToggled('cat-1'))
      ..add(const CreatePostCategoryToggled('cat-2'))
      ..add(const CreatePostCategoryToggled('cat-1')),
    expect: () => [
      editing.copyWith(selectedCategoryIds: {'cat-1'}),
      editing.copyWith(selectedCategoryIds: {'cat-1', 'cat-2'}),
      editing.copyWith(selectedCategoryIds: {'cat-2'}),
    ],
  );

  blocTest<CreatePostBloc, CreatePostState>(
    'publicar envía lo elegido y termina con la publicación creada',
    build: build,
    seed: () => filled,
    act: (bloc) => bloc.add(const CreatePostSubmitted()),
    expect: () => [
      filled.copyWith(status: CreatePostStatus.submitting),
      filled.copyWith(status: CreatePostStatus.success, createdPost: created),
    ],
    verify: (_) => verify(
      () => createPost(
        const CreatePostParams(
          type: PostType.question,
          body: '¿A alguien más le pasa?',
          visibility: PostVisibility.public,
          categoryIds: ['cat-1'],
        ),
      ),
    ).called(1),
  );

  blocTest<CreatePostBloc, CreatePostState>(
    'si falla el envío conserva todo lo escrito y muestra el error',
    build: build,
    seed: () => filled,
    setUp: () => when(
      () => createPost(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure())),
    act: (bloc) => bloc.add(const CreatePostSubmitted()),
    expect: () => [
      filled.copyWith(status: CreatePostStatus.submitting),
      filled.copyWith(errorMessage: const NetworkFailure().message),
    ],
  );

  blocTest<CreatePostBloc, CreatePostState>(
    'una validación fallida dice qué corregir y se borra al editar',
    build: build,
    seed: () => editing.copyWith(selectedCategoryIds: {'cat-1'}),
    setUp: () => when(
      () => createPost(any()),
    ).thenAnswer((_) async => const Left(EmptyPostBodyFailure())),
    act: (bloc) async {
      bloc.add(const CreatePostSubmitted());
      await bloc.stream.firstWhere((s) => s.errorMessage != null);
      bloc.add(const CreatePostBodyChanged('Hola'));
    },
    skip: 1,
    expect: () => [
      editing.copyWith(
        selectedCategoryIds: {'cat-1'},
        errorMessage: const EmptyPostBodyFailure().message,
      ),
      editing.copyWith(selectedCategoryIds: {'cat-1'}, body: 'Hola'),
    ],
  );

  blocTest<CreatePostBloc, CreatePostState>(
    'mientras se envía no se puede volver a publicar',
    build: build,
    seed: () => filled.copyWith(status: CreatePostStatus.submitting),
    act: (bloc) => bloc.add(const CreatePostSubmitted()),
    expect: () => <CreatePostState>[],
    verify: (_) => verifyNever(() => createPost(any())),
  );
}
