import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/update_profile.dart';
import '../bloc/edit_profile_bloc.dart';
import '../bloc/edit_profile_event.dart';
import '../bloc/edit_profile_state.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

/// Editar nombre y biografía. Toma el perfil ya cargado por el [ProfileBloc]
/// del shell; al guardar con éxito lo recarga y vuelve al resumen.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileBloc>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: profileState is ProfileLoaded
            ? _EditProfileForm(profile: profileState.profile)
            : const Center(
                child: CircularProgressIndicator(color: AppColors.sage),
              ),
      ),
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  final Profile profile;

  const _EditProfileForm({required this.profile});

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<EditProfileBloc>().add(
      EditProfileSubmitted(
        profile: widget.profile,
        displayName: _nameController.text,
        bio: _bioController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<EditProfileBloc, EditProfileState>(
      listener: (context, state) {
        if (state is EditProfileSuccess) {
          context.read<ProfileBloc>().add(const ProfileLoadRequested());
          context.pop();
        }
      },
      builder: (context, state) {
        final isSaving = state is EditProfileSaving;
        final errorMessage = state is EditProfileFailure ? state.message : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cuéntanos cómo te gustaría que te veamos. Puedes cambiarlo '
                'cuando quieras.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (errorMessage != null) ...[
                Container(
                  key: const Key('edit_profile_error'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    errorMessage,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text('Nombre', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                key: const Key('edit_profile_name_field'),
                controller: _nameController,
                enabled: !isSaving,
                maxLength: UpdateProfile.maxNameLength,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Tu nombre o un apodo',
                ),
              ),
              const SizedBox(height: 16),
              Text('Sobre ti', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                key: const Key('edit_profile_bio_field'),
                controller: _bioController,
                enabled: !isSaving,
                maxLength: UpdateProfile.maxBioLength,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Algo que quieras compartir (opcional)',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('edit_profile_save_button'),
                onPressed: isSaving ? null : _submit,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar cambios'),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('edit_profile_cancel_button'),
                onPressed: isSaving ? null : () => context.pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      },
    );
  }
}
