import 'package:equatable/equatable.dart';

import '../../domain/entities/post.dart';
import '../../domain/entities/post_comment.dart';

sealed class PostDetailState extends Equatable {
  const PostDetailState();

  @override
  List<Object?> get props => [];
}

class PostDetailLoading extends PostDetailState {
  const PostDetailLoading();
}

class PostDetailLoaded extends PostDetailState {
  final Post post;

  /// Ya ordenados como conversación.
  final List<PostComment> comments;

  const PostDetailLoaded({required this.post, required this.comments});

  @override
  List<Object?> get props => [post, comments];
}

class PostDetailFailure extends PostDetailState {
  final String message;

  const PostDetailFailure(this.message);

  @override
  List<Object?> get props => [message];
}
