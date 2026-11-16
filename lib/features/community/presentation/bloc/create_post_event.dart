import 'package:equatable/equatable.dart';

import '../../domain/entities/post_type.dart';
import '../../domain/entities/post_visibility.dart';

sealed class CreatePostEvent extends Equatable {
  const CreatePostEvent();

  @override
  List<Object?> get props => [];
}

/// Abre el formulario (o reintenta): trae las categorías.
class CreatePostStarted extends CreatePostEvent {
  const CreatePostStarted();
}

class CreatePostTypeChanged extends CreatePostEvent {
  final PostType type;

  const CreatePostTypeChanged(this.type);

  @override
  List<Object?> get props => [type];
}

class CreatePostCategoryToggled extends CreatePostEvent {
  final String categoryId;

  const CreatePostCategoryToggled(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class CreatePostVisibilityChanged extends CreatePostEvent {
  final PostVisibility visibility;

  const CreatePostVisibilityChanged(this.visibility);

  @override
  List<Object?> get props => [visibility];
}

class CreatePostBodyChanged extends CreatePostEvent {
  final String body;

  const CreatePostBodyChanged(this.body);

  @override
  List<Object?> get props => [body];
}

class CreatePostSubmitted extends CreatePostEvent {
  const CreatePostSubmitted();
}
