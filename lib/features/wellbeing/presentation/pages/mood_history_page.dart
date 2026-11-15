import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../domain/entities/mood_checkin.dart';
import '../bloc/mood_history_bloc.dart';
import '../bloc/mood_history_event.dart';
import '../bloc/mood_history_state.dart';
import 'mood_checkin_page.dart' show moodOptions;

const _monthsShort = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Fecha y hora de un registro, en español y en formato de 12 horas.
///
/// Se muestra en la hora local de quien lee, porque el registro se guarda en
/// UTC. No hay `intl` en el proyecto, así que se arma a mano.
String moodCheckinDateLabel(DateTime when) {
  final d = when.toLocal();
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final period = d.hour < 12 ? 'a. m.' : 'p. m.';

  return '${d.day} ${_monthsShort[d.month - 1]} ${d.year}, '
      '$hour12:$minute $period';
}

/// Etiqueta e icono del ánimo, tomados de las mismas opciones del check-in
/// para que un registro se lea igual que cuando se creó.
({String label, IconData icon}) _mood(int score) {
  final option = moodOptions.firstWhere(
    (o) => o.score == score,
    orElse: () => moodOptions[2],
  );
  return (label: option.label, icon: option.icon);
}

/// «Mis registros»: los check-ins de la usuaria, del más reciente al más
/// antiguo. Solo lee; no se editan ni se borran.
class MoodHistoryPage extends StatelessWidget {
  const MoodHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis registros')),
      body: SafeArea(
        child: BlocBuilder<MoodHistoryBloc, MoodHistoryState>(
          builder: (context, state) => switch (state) {
            MoodHistoryInitial() || MoodHistoryLoading() => const Center(
              key: Key('mood_history_loading'),
              child: CircularProgressIndicator(),
            ),
            MoodHistoryFailure(:final message) => _ErrorView(message: message),
            MoodHistoryLoaded(:final history) when history.isEmpty =>
              const _EmptyView(),
            MoodHistoryLoaded(:final history) => _HistoryList(history: history),
          },
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<MoodCheckin> history;

  const _HistoryList({required this.history});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: history.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final checkin = history[index];
        return _CheckinCard(
          key: Key('mood_history_item_${checkin.id}'),
          checkin: checkin,
        );
      },
    );
  }
}

class _CheckinCard extends StatelessWidget {
  final MoodCheckin checkin;

  const _CheckinCard({super.key, required this.checkin});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mood = _mood(checkin.moodScore);
    final note = checkin.note;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(mood.icon, size: 28, color: AppColors.sage),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mood.label, style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  moodCheckinDateLabel(checkin.recordedAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.inkSoft,
                  ),
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(note, style: textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      key: const Key('mood_history_empty'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.favorite_border_rounded,
            size: 48,
            color: AppColors.sage,
          ),
          const SizedBox(height: 20),
          Text(
            'Todavía no hay registros',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Cuando hagas tu primer check-in, lo verás aquí. Puedes empezar '
            'cuando quieras, y solo si te sirve.',
            key: const Key('mood_history_empty_message'),
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const Key('mood_history_error'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.error),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('mood_history_retry_button'),
            onPressed: () => context.read<MoodHistoryBloc>().add(
              const MoodHistoryRequested(),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
