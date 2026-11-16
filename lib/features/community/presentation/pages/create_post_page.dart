import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../domain/entities/post_type.dart';
import '../../domain/entities/post_visibility.dart';
import '../../domain/usecases/create_post.dart';
import '../bloc/create_post_bloc.dart';
import '../bloc/create_post_event.dart';
import '../bloc/create_post_state.dart';
import '../widgets/community_message_view.dart';

/// «Escribir»: compartir una experiencia, una pregunta o un mensaje.
///
/// Al publicar se cierra devolviendo `true`, para que el feed se actualice.
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _body = TextEditingController(
      text: context.read<CreatePostBloc>().state.body,
    );
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreatePostBloc, CreatePostState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == CreatePostStatus.success,
      listener: (context, state) => context.pop(true),
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Escribir'),
            leading: IconButton(
              key: const Key('create_post_close'),
              tooltip: 'Cerrar sin publicar',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.pop(false),
            ),
          ),
          body: SafeArea(
            child: switch (state.status) {
              CreatePostStatus.loadingCategories => const Center(
                key: Key('create_post_loading'),
                child: CircularProgressIndicator(),
              ),
              CreatePostStatus.categoriesFailure => CommunityMessageView(
                icon: Icons.cloud_off_rounded,
                title: 'No pudimos preparar el formulario',
                message: state.errorMessage ?? '',
                actionLabel: 'Reintentar',
                actionKey: const Key('create_post_retry'),
                onAction: () => context.read<CreatePostBloc>().add(
                  const CreatePostStarted(),
                ),
              ),
              _ => _Form(state: state, controller: _body),
            },
          ),
        );
      },
    );
  }
}

class _Form extends StatelessWidget {
  final CreatePostState state;
  final TextEditingController controller;

  const _Form({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CreatePostBloc>();
    final textTheme = Theme.of(context).textTheme;
    final enabled = !state.isSubmitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              const _SectionTitle('¿Qué quieres compartir?'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in PostType.values)
                    ChoiceChip(
                      key: Key('create_post_type_${type.code}'),
                      label: Text(type.label),
                      selected: state.type == type,
                      showCheckmark: false,
                      selectedColor: AppColors.sage.withValues(alpha: 0.18),
                      onSelected: enabled
                          ? (_) => bloc.add(CreatePostTypeChanged(type))
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionTitle('Categorías'),
              Text(
                'Elige una o más para que otras madres te encuentren.',
                style: textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in state.categories)
                    FilterChip(
                      key: Key('create_post_category_${category.id}'),
                      label: Text(category.name),
                      selected: state.selectedCategoryIds.contains(category.id),
                      selectedColor: AppColors.sage.withValues(alpha: 0.18),
                      checkmarkColor: AppColors.sageDark,
                      onSelected: enabled
                          ? (_) =>
                                bloc.add(CreatePostCategoryToggled(category.id))
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionTitle('Tu mensaje'),
              TextField(
                key: const Key('create_post_body'),
                controller: controller,
                enabled: enabled,
                minLines: 5,
                maxLines: 10,
                maxLength: CreatePost.maxBodyLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Escribe con tus palabras. Aquí nadie te juzga.',
                ),
                onChanged: (value) => bloc.add(CreatePostBodyChanged(value)),
              ),
              const SizedBox(height: 12),
              const _SectionTitle('¿Quién puede verla?'),
              for (final visibility in PostVisibility.values)
                _VisibilityOption(
                  visibility: visibility,
                  selected: state.visibility == visibility,
                  enabled: enabled,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.errorMessage != null) ...[
                Text(
                  state.errorMessage!,
                  key: const Key('create_post_error'),
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 10),
              ],
              ElevatedButton(
                key: const Key('create_post_submit'),
                onPressed: enabled
                    ? () => bloc.add(const CreatePostSubmitted())
                    : null,
                child: state.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Publicar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final PostVisibility visibility;
  final bool selected;
  final bool enabled;

  const _VisibilityOption({
    required this.visibility,
    required this.selected,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('create_post_visibility_${visibility.code}'),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          onTap: enabled
              ? () => context.read<CreatePostBloc>().add(
                  CreatePostVisibilityChanged(visibility),
                )
              : null,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.sage.withValues(alpha: 0.10)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(
                color: selected ? AppColors.sage : AppColors.lineSoft,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected ? AppColors.sage : AppColors.inkMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(visibility.label, style: textTheme.titleSmall),
                      Text(
                        visibility.description,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
