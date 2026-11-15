import 'package:equatable/equatable.dart';

import '../../domain/entities/need_option.dart';
import '../../domain/entities/recommendation.dart';

sealed class NeedsState extends Equatable {
  const NeedsState();

  @override
  List<Object?> get props => [];
}

class NeedsInitial extends NeedsState {
  const NeedsInitial();
}

class NeedsLoadingOptions extends NeedsState {
  const NeedsLoadingOptions();
}

/// Pantalla de selección. [canContinue] es lo único que la pantalla necesita
/// consultar para habilitar el botón.
class NeedsOptionsReady extends NeedsState {
  final List<NeedOption> options;
  final Set<String> selectedIds;
  final bool isSubmitting;

  const NeedsOptionsReady({
    required this.options,
    required this.selectedIds,
    this.isSubmitting = false,
  });

  bool get canContinue => selectedIds.isNotEmpty && !isSubmitting;

  bool isSelected(String optionId) => selectedIds.contains(optionId);

  NeedsOptionsReady copyWith({
    Set<String>? selectedIds,
    bool? isSubmitting,
  }) {
    return NeedsOptionsReady(
      options: options,
      selectedIds: selectedIds ?? this.selectedIds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [options, selectedIds, isSubmitting];
}

/// Recomendaciones listas. Una lista vacía es válida: la pantalla muestra un
/// mensaje de respaldo.
class NeedsRecommendationsReady extends NeedsState {
  final List<Recommendation> recommendations;

  const NeedsRecommendationsReady(this.recommendations);

  bool get isEmpty => recommendations.isEmpty;

  @override
  List<Object?> get props => [recommendations];
}

class NeedsFailure extends NeedsState {
  final String message;

  const NeedsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
