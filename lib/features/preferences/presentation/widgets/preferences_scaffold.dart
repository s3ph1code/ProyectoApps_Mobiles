import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/preferences_bloc.dart';
import '../bloc/preferences_event.dart';
import '../bloc/preferences_state.dart';

/// Marco común de las pantallas de preferencias: título, carga, error con
/// reintento y aviso cuando un cambio no se pudo guardar.
class PreferencesScaffold extends StatelessWidget {
  final String title;
  final Widget Function(BuildContext context, PreferencesLoaded state) builder;

  const PreferencesScaffold({
    super.key,
    required this.title,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: BlocConsumer<PreferencesBloc, PreferencesState>(
          listenWhen: (previous, current) =>
              current is PreferencesLoaded &&
              current.errorMessage != null &&
              previous != current,
          listener: (context, state) {
            final message = (state as PreferencesLoaded).errorMessage!;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          },
          builder: (context, state) {
            return switch (state) {
              PreferencesInitial() || PreferencesLoading() => const Center(
                child: CircularProgressIndicator(color: AppColors.sage),
              ),
              PreferencesFailure(:final message) => _ErrorView(
                message: message,
                onRetry: () => context.read<PreferencesBloc>().add(
                  const PreferencesLoadRequested(),
                ),
              ),
              PreferencesLoaded() => builder(context, state),
            };
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: textTheme.bodyLarge?.copyWith(color: AppColors.error),
          ),
          const Spacer(),
          ElevatedButton(
            key: const Key('preferences_retry_button'),
            onPressed: onRetry,
            child: const Text('Volver a intentar'),
          ),
        ],
      ),
    );
  }
}
