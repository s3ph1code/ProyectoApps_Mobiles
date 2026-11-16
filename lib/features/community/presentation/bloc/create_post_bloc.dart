import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/create_post.dart';
import '../../domain/usecases/get_community_categories.dart';
import 'create_post_event.dart';
import 'create_post_state.dart';

class CreatePostBloc extends Bloc<CreatePostEvent, CreatePostState> {
  final GetCommunityCategories getCommunityCategories;
  final CreatePost createPost;

  CreatePostBloc({
    required this.getCommunityCategories,
    required this.createPost,
  }) : super(const CreatePostState()) {
    on<CreatePostStarted>(_onStarted);
    on<CreatePostTypeChanged>(
      (event, emit) => emit(state.copyWith(type: event.type, clearError: true)),
    );
    on<CreatePostVisibilityChanged>(
      (event, emit) =>
          emit(state.copyWith(visibility: event.visibility, clearError: true)),
    );
    on<CreatePostBodyChanged>(
      (event, emit) => emit(state.copyWith(body: event.body, clearError: true)),
    );
    on<CreatePostCategoryToggled>(_onCategoryToggled);
    on<CreatePostSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(
    CreatePostStarted event,
    Emitter<CreatePostState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CreatePostStatus.loadingCategories,
        clearError: true,
      ),
    );

    final result = await getCommunityCategories(const NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CreatePostStatus.categoriesFailure,
          errorMessage: failure.message,
        ),
      ),
      (categories) => emit(
        state.copyWith(
          status: CreatePostStatus.editing,
          categories: categories,
          clearError: true,
        ),
      ),
    );
  }

  void _onCategoryToggled(
    CreatePostCategoryToggled event,
    Emitter<CreatePostState> emit,
  ) {
    final selected = {...state.selectedCategoryIds};
    if (!selected.remove(event.categoryId)) selected.add(event.categoryId);
    emit(state.copyWith(selectedCategoryIds: selected, clearError: true));
  }

  Future<void> _onSubmitted(
    CreatePostSubmitted event,
    Emitter<CreatePostState> emit,
  ) async {
    if (state.status != CreatePostStatus.editing) return;

    emit(state.copyWith(status: CreatePostStatus.submitting, clearError: true));

    final result = await createPost(
      CreatePostParams(
        type: state.type,
        body: state.body,
        visibility: state.visibility,
        categoryIds: state.selectedCategoryIds.toList(),
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CreatePostStatus.editing,
          errorMessage: failure.message,
        ),
      ),
      (post) => emit(
        state.copyWith(status: CreatePostStatus.success, createdPost: post),
      ),
    );
  }
}
