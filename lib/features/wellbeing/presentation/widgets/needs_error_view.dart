import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../bloc/needs_bloc.dart';
import '../bloc/needs_event.dart';

/// Error de «No sé qué necesito», con la opción de volver a intentarlo.
/// Lo comparten la pantalla de selección y la de recomendaciones.
class NeedsErrorView extends StatelessWidget {
  final String message;
  final Key retryKey;

  const NeedsErrorView({
    super.key,
    required this.message,
    required this.retryKey,
  });

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
            key: retryKey,
            onPressed: () =>
                context.read<NeedsBloc>().add(const NeedOptionsRequested()),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
