import 'package:equatable/equatable.dart';

import '../../domain/entities/community_category.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_type.dart';
import '../../domain/entities/post_visibility.dart';

enum CreatePostStatus {
  loadingCategories,
  categoriesFailure,
  editing,
  submitting,
  success,
}

/// Todo lo escrito vive aquí, así un envío fallido no borra nada y se
/// puede reintentar tal cual.
class CreatePostState extends Equatable {
  final CreatePostStatus status;
  final List<CommunityCategory> categories;
  final PostType type;
  final Set<String> selectedCategoryIds;
  final PostVisibility visibility;
  final String body;

  /// Error de validación o de envío, ya listo para mostrarse.
  final String? errorMessage;
  final Post? createdPost;

  const CreatePostState({
    this.status = CreatePostStatus.loadingCategories,
    this.categories = const [],
    this.type = PostType.experience,
    this.selectedCategoryIds = const {},
    this.visibility = PostVisibility.community,
    this.body = '',
    this.errorMessage,
    this.createdPost,
  });

  bool get isSubmitting => status == CreatePostStatus.submitting;

  CreatePostState copyWith({
    CreatePostStatus? status,
    List<CommunityCategory>? categories,
    PostType? type,
    Set<String>? selectedCategoryIds,
    PostVisibility? visibility,
    String? body,
    String? errorMessage,
    bool clearError = false,
    Post? createdPost,
  }) {
    return CreatePostState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      type: type ?? this.type,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      visibility: visibility ?? this.visibility,
      body: body ?? this.body,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdPost: createdPost ?? this.createdPost,
    );
  }

  @override
  List<Object?> get props => [
    status,
    categories,
    type,
    selectedCategoryIds,
    visibility,
    body,
    errorMessage,
    createdPost,
  ];
}
