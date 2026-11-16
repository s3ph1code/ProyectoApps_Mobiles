import 'package:equatable/equatable.dart';

sealed class PostDetailEvent extends Equatable {
  const PostDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Carga (o reintenta) la publicación y sus comentarios.
class PostDetailRequested extends PostDetailEvent {
  final String postId;

  const PostDetailRequested(this.postId);

  @override
  List<Object?> get props => [postId];
}
