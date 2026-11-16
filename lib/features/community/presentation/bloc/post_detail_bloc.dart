import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_post_by_id.dart';
import '../../domain/usecases/get_post_comments.dart';
import 'post_detail_event.dart';
import 'post_detail_state.dart';

/// Detalle de una publicación con sus comentarios.
class PostDetailBloc extends Bloc<PostDetailEvent, PostDetailState> {
  final GetPostById getPostById;
  final GetPostComments getPostComments;

  PostDetailBloc({required this.getPostById, required this.getPostComments})
    : super(const PostDetailLoading()) {
    on<PostDetailRequested>(_onRequested);
  }

  Future<void> _onRequested(
    PostDetailRequested event,
    Emitter<PostDetailState> emit,
  ) async {
    emit(const PostDetailLoading());

    // Las dos consultas son independientes: se piden a la vez.
    final postFuture = getPostById(GetPostByIdParams(postId: event.postId));
    final commentsFuture = getPostComments(
      GetPostCommentsParams(postId: event.postId),
    );
    final postResult = await postFuture;
    final commentsResult = await commentsFuture;

    postResult.fold(
      (failure) => emit(PostDetailFailure(failure.message)),
      (post) => commentsResult.fold(
        (failure) => emit(PostDetailFailure(failure.message)),
        (comments) => emit(PostDetailLoaded(post: post, comments: comments)),
      ),
    );
  }
}
