import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/get_current_user.dart';
import '../../domain/usecases/get_need_options.dart';
import '../../domain/usecases/get_recommendations.dart';
import '../../domain/usecases/save_need_session.dart';
import 'needs_event.dart';
import 'needs_state.dart';

/// «No sé qué necesito»: elegir una o varias opciones y recibir sugerencias.
class NeedsBloc extends Bloc<NeedsEvent, NeedsState> {
  final GetCurrentUser getCurrentUser;
  final GetNeedOptions getNeedOptions;
  final GetRecommendations getRecommendations;
  final SaveNeedSession saveNeedSession;

  NeedsBloc({
    required this.getCurrentUser,
    required this.getNeedOptions,
    required this.getRecommendations,
    required this.saveNeedSession,
  }) : super(const NeedsInitial()) {
    on<NeedOptionsRequested>(_onOptionsRequested);
    on<NeedOptionToggled>(_onOptionToggled);
    on<NeedsSubmitted>(_onSubmitted);
  }

  Future<void> _onOptionsRequested(
    NeedOptionsRequested event,
    Emitter<NeedsState> emit,
  ) async {
    if (state is NeedsLoadingOptions) return;
    emit(const NeedsLoadingOptions());

    final result = await getNeedOptions(const NoParams());

    result.fold(
      (failure) => emit(NeedsFailure(failure.message)),
      (options) =>
          emit(NeedsOptionsReady(options: options, selectedIds: const {})),
    );
  }

  void _onOptionToggled(NeedOptionToggled event, Emitter<NeedsState> emit) {
    final current = state;
    if (current is! NeedsOptionsReady || current.isSubmitting) return;

    final selected = Set<String>.from(current.selectedIds);
    if (!selected.remove(event.optionId)) {
      selected.add(event.optionId);
    }

    emit(current.copyWith(selectedIds: selected));
  }

  /// Guarda la consulta antes de recomendar, porque el historial es parte de
  /// la historia. Si el guardado falla se muestra el error y se puede volver
  /// a intentar: cada intento es una consulta nueva.
  Future<void> _onSubmitted(
    NeedsSubmitted event,
    Emitter<NeedsState> emit,
  ) async {
    final current = state;
    if (current is! NeedsOptionsReady) return;
    if (current.selectedIds.isEmpty || current.isSubmitting) return;

    emit(current.copyWith(isSubmitting: true));

    final userResult = await getCurrentUser(const NoParams());
    final user = userResult.fold((_) => null, (user) => user);
    if (user == null) {
      emit(
        NeedsFailure(
          userResult.fold(
            (failure) => failure.message,
            (_) => const UnauthenticatedFailure().message,
          ),
        ),
      );
      return;
    }

    final optionIds = current.selectedIds.toList();

    final saved = await saveNeedSession(
      SaveNeedSessionParams(userId: user.id, optionIds: optionIds),
    );
    if (saved.isLeft()) {
      emit(
        NeedsFailure(
          saved.fold((failure) => failure.message, (_) => ''),
        ),
      );
      return;
    }

    final result = await getRecommendations(
      GetRecommendationsParams(optionIds: optionIds),
    );

    result.fold(
      (failure) => emit(NeedsFailure(failure.message)),
      (recommendations) => emit(NeedsRecommendationsReady(recommendations)),
    );
  }
}
