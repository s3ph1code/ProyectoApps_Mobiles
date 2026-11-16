import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/activity.dart';
import '../bloc/saved_activities_bloc.dart';
import '../bloc/saved_activities_event.dart';
import '../bloc/saved_activities_state.dart';

/// Control reutilizable para guardar o quitar de guardadas una actividad.
///
/// Muestra un estado visible claro (relleno cuando está guardada, silueta cuando no)
/// y permite alternarlo con retroalimentación optimista. Si el bloc no está en el
/// árbol (ej. en pruebas aisladas de otras páginas), se dibuja desactivado sin fallar.
class SaveActivityButton extends StatelessWidget {
  final Activity activity;
  final double iconSize;

  const SaveActivityButton({
    super.key,
    required this.activity,
    this.iconSize = 22,
  });

  SavedActivitiesBloc? _findBloc(BuildContext context) {
    try {
      return context.watch<SavedActivitiesBloc>();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _findBloc(context);
    final isSaved = bloc != null &&
        bloc.state is SavedActivitiesLoaded &&
        (bloc.state as SavedActivitiesLoaded).isSaved(activity.id);

    return IconButton(
      key: Key('activity_save_${activity.id}'),
      tooltip: isSaved ? 'Quitar de guardadas' : 'Guardar actividad',
      iconSize: iconSize,
      icon: Icon(
        isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        color: isSaved ? AppColors.sageDeep : AppColors.inkMuted,
      ),
      onPressed: bloc == null
          ? null
          : () => bloc.add(ActivitySaveToggled(activity)),
    );
  }
}
