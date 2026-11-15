import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../domain/entities/need_option.dart';
import '../bloc/needs_bloc.dart';
import '../bloc/needs_event.dart';
import '../bloc/needs_state.dart';
import '../widgets/needs_error_view.dart';

/// «No sé qué necesito»: se eligen una o varias opciones y se continúa a las
/// recomendaciones. La pantalla no decide nada: pregunta al BLoC si se puede
/// continuar y le reenvía los toques.
class NeedsSelectionPage extends StatelessWidget {
  const NeedsSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('No sé qué necesito')),
      body: SafeArea(
        child: BlocConsumer<NeedsBloc, NeedsState>(
          listenWhen: (previous, current) =>
              current is NeedsRecommendationsReady,
          listener: (context, state) =>
              context.push(AppRoutes.needsRecommendations),
          builder: (context, state) => switch (state) {
            NeedsInitial() || NeedsLoadingOptions() => const Center(
              key: Key('needs_loading'),
              child: CircularProgressIndicator(),
            ),
            NeedsFailure(:final message) => NeedsErrorView(
              message: message,
              retryKey: const Key('needs_retry_button'),
            ),
            // Mientras se navega a las recomendaciones la selección sigue
            // en pantalla un instante.
            NeedsRecommendationsReady() => const Center(
              key: Key('needs_loading'),
              child: CircularProgressIndicator(),
            ),
            NeedsOptionsReady() => _SelectionView(state: state),
          },
        ),
      ),
    );
  }
}

class _SelectionView extends StatelessWidget {
  final NeedsOptionsReady state;

  const _SelectionView({required this.state});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            children: [
              Text(
                'Marca lo que sientas ahora. Puedes elegir varias, y no hay '
                'respuestas correctas.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              for (final option in state.options) ...[
                _OptionTile(
                  key: Key('needs_option_${option.id}'),
                  option: option,
                  selected: state.isSelected(option.id),
                  enabled: !state.isSubmitting,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: ElevatedButton(
            key: const Key('needs_continue_button'),
            onPressed: state.canContinue
                ? () => context.read<NeedsBloc>().add(const NeedsSubmitted())
                : null,
            child: state.isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Ver sugerencias'),
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final NeedOption option;
  final bool selected;
  final bool enabled;

  const _OptionTile({
    super.key,
    required this.option,
    required this.selected,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: enabled
            ? () =>
                  context.read<NeedsBloc>().add(NeedOptionToggled(option.id))
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.sage.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: selected ? AppColors.sage : AppColors.lineSoft,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 22,
                color: selected ? AppColors.sage : AppColors.inkMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.label,
                  style: textTheme.bodyLarge?.copyWith(
                    color: selected ? AppColors.sageDark : AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
