import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:doulapp/core/error/failures.dart';
import 'package:doulapp/features/community/domain/usecases/get_post_by_id.dart';
import 'package:doulapp/features/community/domain/usecases/get_post_comments.dart';
import 'package:doulapp/features/community/presentation/bloc/post_detail_bloc.dart';
import 'package:doulapp/features/community/presentation/bloc/post_detail_event.dart';
import 'package:doulapp/features/community/presentation/bloc/post_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures.dart';

class MockGetPostById extends Mock implements GetPostById {}

class MockGetPostComments extends Mock implements GetPostComments {}

void main() {
  late MockGetPostById getPostById;
  late MockGetPostComments getPostComments;

  final post = makePost('p0');
  final comments = [makeComment('c1'), makeComment('r1', parent: 'c1')];

  PostDetailBloc build() => PostDetailBloc(
    getPostById: getPostById,
    getPostComments: getPostComments,
  );

  setUp(() {
    getPostById = MockGetPostById();
    getPostComments = MockGetPostComments();
    when(
      () => getPostById(const GetPostByIdParams(postId: 'p0')),
    ).thenAnswer((_) async => Right(post));
    when(
      () => getPostComments(const GetPostCommentsParams(postId: 'p0')),
    ).thenAnswer((_) async => Right(comments));
  });

  blocTest<PostDetailBloc, PostDetailState>(
    'carga la publicación con sus comentarios',
    build: build,
    act: (bloc) => bloc.add(const PostDetailRequested('p0')),
    expect: () => [
      const PostDetailLoading(),
      PostDetailLoaded(post: post, comments: comments),
    ],
  );

  blocTest<PostDetailBloc, PostDetailState>(
    'si la publicación ya no existe lo dice',
    build: build,
    setUp: () => when(
      () => getPostById(const GetPostByIdParams(postId: 'p0')),
    ).thenAnswer((_) async => const Left(PostNotFoundFailure())),
    act: (bloc) => bloc.add(const PostDetailRequested('p0')),
    expect: () => [
      const PostDetailLoading(),
      PostDetailFailure(const PostNotFoundFailure().message),
    ],
  );

  blocTest<PostDetailBloc, PostDetailState>(
    'si fallan los comentarios muestra el error para reintentar',
    build: build,
    setUp: () => when(
      () => getPostComments(const GetPostCommentsParams(postId: 'p0')),
    ).thenAnswer((_) async => const Left(NetworkFailure())),
    act: (bloc) => bloc.add(const PostDetailRequested('p0')),
    expect: () => [
      const PostDetailLoading(),
      PostDetailFailure(const NetworkFailure().message),
    ],
  );
}
