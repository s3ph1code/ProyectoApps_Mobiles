import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../domain/usecases/save_mood_checkin.dart';
import '../bloc/mood_checkin_bloc.dart';
import '../bloc/mood_checkin_event.dart';
import '../bloc/mood_checkin_state.dart';

/// Opciones de ánimo, de 1 a 5. Etiquetas neutras, sin juicio.
const moodOptions = [
  (score: 1, label: 'Muy mal', icon: Icons.sentiment_very_dissatisfied_rounded),
  (score: 2, label: 'Mal', icon: Icons.sentiment_dissatisfied_rounded),
  (score: 3, label: 'Regular', icon: Icons.sentiment_neutral_rounded),
  (score: 4, label: 'Bien', icon: Icons.sentiment_satisfied_rounded),
  (score: 5, label: 'Muy bien', icon: Icons.sentiment_very_satisfied_rounded),
];

/// Check-in de ánimo. Siempre se puede omitir. Lo escrito se conserva si el
/// guardado falla, porque vive en esta pantalla y no en el BLoC.
class MoodCheckinPage extends StatefulWidget {
  const MoodCheckinPage({super.key});

  @override
  State<MoodCheckinPage> createState() => _MoodCheckinPageState();
}

class _MoodCheckinPageState extends State<MoodCheckinPage> {
  final _noteController = TextEditingController();
  int? _selectedScore;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<MoodCheckinBloc>().add(
      MoodCheckinSubmitted(
        moodScore: _selectedScore,
        note: _noteController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('¿Cómo te sientes hoy?'),
        actions: [
          TextButton(
            key: const Key('mood_skip_button'),
            onPressed: _leave,
            child: const Text('Omitir'),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<MoodCheckinBloc, MoodCheckinState>(
          builder: (context, state) {
            if (state is MoodCheckinSuccess) {
              return _SuccessView(
                score: state.checkin.moodScore,
                onDone: _leave,
              );
            }
            return _buildForm(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, MoodCheckinState state) {
    final textTheme = Theme.of(context).textTheme;
    final isSaving = state is MoodCheckinSaving;
    final errorMessage = state is MoodCheckinFailure ? state.message : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tómate un momento. No hay respuestas correctas: solo lo que '
            'sientes ahora.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (errorMessage != null) ...[
            Container(
              key: const Key('mood_error'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.error),
              ),
              child: Text(
                errorMessage,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              for (final option in moodOptions)
                Expanded(
                  child: _MoodOption(
                    key: Key('mood_option_${option.score}'),
                    label: option.label,
                    icon: option.icon,
                    selected: _selectedScore == option.score,
                    onTap: isSaving
                        ? null
                        : () => setState(() => _selectedScore = option.score),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Una nota, si quieres', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            key: const Key('mood_note_field'),
            controller: _noteController,
            enabled: !isSaving,
            maxLines: 4,
            maxLength: SaveMoodCheckin.maxNoteLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Lo que quieras recordar de hoy (opcional)',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('mood_save_button'),
            onPressed: isSaving ? null : _submit,
            child: isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _MoodOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _MoodOption({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12),
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
          child: Column(
            children: [
              Icon(
                icon,
                size: 30,
                color: selected ? AppColors.sage : AppColors.inkMuted,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: selected ? AppColors.sageDark : AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final int score;
  final VoidCallback onDone;

  const _SuccessView({required this.score, required this.onDone});

  String get _message => score <= 2
      ? 'Gracias por contarlo. Lo que sientes importa, y no tienes que '
            'resolverlo hoy.'
      : 'Gracias por tomarte este momento para ti. Estamos contigo.';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Icon(
            Icons.favorite_border_rounded,
            size: 48,
            color: AppColors.sage,
          ),
          const SizedBox(height: 20),
          Text(
            'Registro guardado',
            key: const Key('mood_success_title'),
            textAlign: TextAlign.center,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            _message,
            key: const Key('mood_success_message'),
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
          const Spacer(),
          ElevatedButton(
            key: const Key('mood_done_button'),
            onPressed: onDone,
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }
}
