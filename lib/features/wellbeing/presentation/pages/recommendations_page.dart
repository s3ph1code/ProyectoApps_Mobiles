import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/recommendation_destination.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../domain/entities/recommendation.dart';
import '../bloc/needs_bloc.dart';
import '../bloc/needs_state.dart';
import '../widgets/needs_error_view.dart';

/// Sugerencias para lo que la usuaria eligió, de mayor a menor relevancia.
class RecommendationsPage extends StatelessWidget {
  const RecommendationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Esto puede ayudarte')),
      body: SafeArea(
        child: BlocBuilder<NeedsBloc, NeedsState>(
          builder: (context, state) => switch (state) {
            NeedsFailure(:final message) => NeedsErrorView(
              message: message,
              retryKey: const Key('recommendations_retry_button'),
            ),
            NeedsRecommendationsReady(:final recommendations)
                when recommendations.isEmpty =>
              const _FallbackView(),
            NeedsRecommendationsReady(:final recommendations) =>
              _RecommendationsList(recommendations: recommendations),
            _ => const Center(
              key: Key('recommendations_loading'),
              child: CircularProgressIndicator(),
            ),
          },
        ),
      ),
    );
  }
}

class _RecommendationsList extends StatelessWidget {
  final List<Recommendation> recommendations;

  const _RecommendationsList({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Text(
          'Esto es lo que se nos ocurre para acompañarte ahora. Tómalo solo '
          'si te sirve.',
          key: const Key('recommendations_intro'),
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        for (final recommendation in recommendations) ...[
          _RecommendationCard(
            key: Key('recommendation_${recommendation.id}'),
            recommendation: recommendation,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Tarjeta de una sugerencia. A dónde lleva lo decide la capa de navegación
/// con [recommendationRoute]; si no lleva a ninguna parte, solo se lee.
class _RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;

  const _RecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final route = recommendationRoute(recommendation);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.md),
      onTap: route == null ? null : () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.lineSoft),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.auto_awesome_outlined,
              size: 22,
              color: AppColors.sage,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                recommendation.message,
                style: textTheme.bodyLarge,
              ),
            ),
            if (route != null) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.inkMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FallbackView extends StatelessWidget {
  const _FallbackView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      key: const Key('recommendations_fallback'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.favorite_border_rounded,
            size: 44,
            color: AppColors.sage,
          ),
          const SizedBox(height: 18),
          Text(
            'Gracias por contarnos',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Todavía no tenemos una sugerencia para esta combinación. '
            'Mientras tanto puedes mirar los microdescansos o registrar '
            'cómo te sientes.',
            key: const Key('recommendations_fallback_message'),
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
