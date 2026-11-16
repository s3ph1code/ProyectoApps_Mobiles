import 'package:equatable/equatable.dart';

import '../../domain/entities/community_category.dart';
import '../../domain/entities/post.dart';

sealed class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => [];
}

class FeedInitial extends FeedState {
  const FeedInitial();
}

class FeedLoading extends FeedState {
  const FeedLoading();
}

/// Feed cargado. [selectedCategoryId] en `null` es «Todas».
///
/// [isReloading] marca un cambio de filtro o una actualización, para no
/// esconder los chips mientras llega la primera página. [loadMoreError]
/// guarda el error de la página siguiente sin perder lo que ya se ve.
class FeedLoaded extends FeedState {
  final List<CommunityCategory> categories;
  final List<Post> posts;
  final String? selectedCategoryId;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isReloading;
  final String? loadMoreError;

  const FeedLoaded({
    required this.categories,
    required this.posts,
    this.selectedCategoryId,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isReloading = false,
    this.loadMoreError,
  });

  bool get isEmpty => posts.isEmpty;

  FeedLoaded copyWith({
    List<Post>? posts,
    String? selectedCategoryId,
    bool clearCategory = false,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isReloading,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return FeedLoaded(
      categories: categories,
      posts: posts ?? this.posts,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isReloading: isReloading ?? this.isReloading,
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
    );
  }

  @override
  List<Object?> get props => [
    categories,
    posts,
    selectedCategoryId,
    hasMore,
    isLoadingMore,
    isReloading,
    loadMoreError,
  ];
}

class FeedFailure extends FeedState {
  final String message;

  const FeedFailure(this.message);

  @override
  List<Object?> get props => [message];
}
