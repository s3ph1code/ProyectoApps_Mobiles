import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_community_categories.dart';
import '../../domain/usecases/get_posts.dart';
import 'feed_event.dart';
import 'feed_state.dart';

/// Feed de la comunidad: filtro por categoría y carga de 20 en 20.
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final GetCommunityCategories getCommunityCategories;
  final GetPosts getPosts;

  /// Cambia cada vez que la lista vuelve a empezar (filtro o actualización).
  /// Una página que llega tarde de una lista anterior se descarta, para no
  /// mezclar publicaciones de dos categorías.
  int _generation = 0;

  FeedBloc({required this.getCommunityCategories, required this.getPosts})
    : super(const FeedInitial()) {
    on<FeedRequested>(_onRequested);
    on<FeedCategorySelected>(_onCategorySelected);
    on<FeedRefreshed>(_onRefreshed);
    on<FeedNextPageRequested>(_onNextPage);
  }

  Future<void> _onRequested(
    FeedRequested event,
    Emitter<FeedState> emit,
  ) async {
    if (state is FeedLoading) return;
    final generation = ++_generation;
    emit(const FeedLoading());

    final categoriesResult = await getCommunityCategories(const NoParams());
    final categories = categoriesResult.fold((_) => null, (value) => value);
    if (categories == null) {
      emit(FeedFailure(categoriesResult.fold((f) => f.message, (_) => '')));
      return;
    }

    final postsResult = await getPosts(const GetPostsParams());
    if (generation != _generation) return;

    postsResult.fold(
      (failure) => emit(FeedFailure(failure.message)),
      (posts) => emit(
        FeedLoaded(
          categories: categories,
          posts: posts,
          hasMore: posts.length == GetPosts.pageSize,
        ),
      ),
    );
  }

  Future<void> _onCategorySelected(
    FeedCategorySelected event,
    Emitter<FeedState> emit,
  ) {
    return _reload(emit, categoryId: event.categoryId, changeCategory: true);
  }

  Future<void> _onRefreshed(FeedRefreshed event, Emitter<FeedState> emit) {
    final current = state;
    if (current is! FeedLoaded) {
      add(const FeedRequested());
      return Future.value();
    }
    return _reload(emit, categoryId: current.selectedCategoryId);
  }

  Future<void> _reload(
    Emitter<FeedState> emit, {
    required String? categoryId,
    bool changeCategory = false,
  }) async {
    final current = state;
    if (current is! FeedLoaded) return;
    final generation = ++_generation;

    final reloading = current.copyWith(
      selectedCategoryId: categoryId,
      clearCategory: categoryId == null,
      isReloading: true,
      isLoadingMore: false,
      clearLoadMoreError: true,
    );
    emit(reloading);

    final result = await getPosts(GetPostsParams(categoryId: categoryId));
    if (generation != _generation) return;

    result.fold(
      (failure) => emit(FeedFailure(failure.message)),
      (posts) => emit(
        reloading.copyWith(
          posts: posts,
          hasMore: posts.length == GetPosts.pageSize,
          isReloading: false,
        ),
      ),
    );
  }

  Future<void> _onNextPage(
    FeedNextPageRequested event,
    Emitter<FeedState> emit,
  ) async {
    final current = state;
    if (current is! FeedLoaded ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.isReloading) {
      return;
    }
    final generation = _generation;

    emit(current.copyWith(isLoadingMore: true, clearLoadMoreError: true));

    final result = await getPosts(
      GetPostsParams(
        categoryId: current.selectedCategoryId,
        offset: current.posts.length,
      ),
    );
    if (generation != _generation) return;

    final latest = state;
    if (latest is! FeedLoaded) return;

    result.fold(
      (failure) => emit(
        latest.copyWith(isLoadingMore: false, loadMoreError: failure.message),
      ),
      (page) {
        // Si alguien publicó mientras tanto, la página puede repetir una
        // publicación que ya está en la lista.
        final seen = latest.posts.map((p) => p.id).toSet();
        emit(
          latest.copyWith(
            posts: [
              ...latest.posts,
              ...page.where((p) => !seen.contains(p.id)),
            ],
            hasMore: page.length == GetPosts.pageSize,
            isLoadingMore: false,
          ),
        );
      },
    );
  }
}
