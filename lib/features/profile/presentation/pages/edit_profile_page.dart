import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../domain/entities/avatar_image.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/update_profile.dart';
import '../bloc/avatar_bloc.dart';
import '../bloc/avatar_event.dart';
import '../bloc/avatar_state.dart';
import '../bloc/edit_profile_bloc.dart';
import '../bloc/edit_profile_event.dart';
import '../bloc/edit_profile_state.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../services/avatar_picker.dart';
import '../widgets/profile_avatar.dart';

/// Editar nombre y biografía. Toma el perfil ya cargado por el [ProfileBloc]
/// del shell; al guardar con éxito lo recarga y vuelve al resumen.
class EditProfilePage extends StatelessWidget {
  /// Selector de imágenes; se puede reemplazar en las pruebas.
  final AvatarPicker? picker;

  const EditProfilePage({super.key, this.picker});

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileBloc>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: profileState is ProfileLoaded
            ? _EditProfileForm(
                profile: profileState.profile,
                picker: picker ?? ImagePickerAvatarPicker(),
              )
            : const Center(
                child: CircularProgressIndicator(color: AppColors.sage),
              ),
      ),
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  final Profile profile;
  final AvatarPicker picker;

  const _EditProfileForm({required this.profile, required this.picker});

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;

  /// Perfil vigente en esta pantalla: cambia cuando se sube o se quita la
  /// foto, para que guardar el nombre no pise la foto nueva con la vieja.
  late Profile _profile;
  bool _avatarChanged = false;
  ProfileBloc? _profileBloc;
  VoidCallback? _retryAvatar;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _nameController = TextEditingController(text: widget.profile.displayName);
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileBloc = context.read<ProfileBloc>();
  }

  @override
  void dispose() {
    // Si solo cambió la foto y se sale con «Cancelar», el resumen del perfil
    // igual debe mostrarla.
    final bloc = _profileBloc;
    if (_avatarChanged && bloc != null && !bloc.isClosed) {
      bloc.add(const ProfileLoadRequested());
    }
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<EditProfileBloc>().add(
      EditProfileSubmitted(
        profile: _profile,
        displayName: _nameController.text,
        bio: _bioController.text,
      ),
    );
  }

  bool get _cameraAvailable =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<AvatarSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('avatar_source_gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(sheetContext).pop(AvatarSource.gallery),
            ),
            if (_cameraAvailable)
              ListTile(
                key: const Key('avatar_source_camera'),
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar una foto'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(AvatarSource.camera),
              ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final image = await widget.picker.pick(source);
      if (image == null || !mounted) return;
      _upload(image);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos abrir tus fotos. Revisa los permisos de la app.',
            ),
          ),
        );
    }
  }

  void _upload(AvatarImage image) {
    _retryAvatar = () => _upload(image);
    context.read<AvatarBloc>().add(
      AvatarUploadRequested(profile: _profile, image: image),
    );
  }

  void _removePhoto() {
    _retryAvatar = _removePhoto;
    context.read<AvatarBloc>().add(AvatarRemoveRequested(_profile));
  }

  Widget _buildAvatarSection(
    BuildContext context,
    AvatarState avatarState,
    bool formBusy,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final working = avatarState is AvatarWorking;
    final busy = working || formBusy;
    final error = avatarState is AvatarFailure ? avatarState.message : null;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ProfileAvatar(
              key: const Key('edit_profile_avatar'),
              initials: initialsOf(_nameController.text),
              avatarUrl: _profile.avatarUrl,
              size: 96,
            ),
            if (working)
              const SizedBox(
                key: Key('edit_profile_avatar_loading'),
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.sage,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          children: [
            TextButton.icon(
              key: const Key('edit_profile_change_photo_button'),
              onPressed: busy ? null : _choosePhoto,
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: Text(
                _profile.avatarUrl == null ? 'Agregar foto' : 'Cambiar foto',
              ),
            ),
            if (_profile.avatarUrl != null)
              TextButton(
                key: const Key('edit_profile_remove_photo_button'),
                onPressed: busy ? null : _removePhoto,
                child: const Text('Quitar foto'),
              ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Container(
            key: const Key('edit_profile_avatar_error'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.error),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    error,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
                if (_retryAvatar != null)
                  TextButton(
                    key: const Key('edit_profile_avatar_retry_button'),
                    onPressed: busy ? null : _retryAvatar,
                    child: const Text('Reintentar'),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<AvatarBloc, AvatarState>(
      listener: (context, state) {
        if (state is AvatarSuccess) {
          setState(() {
            _profile = state.profile;
            _avatarChanged = true;
            _retryAvatar = null;
          });
        }
      },
      child: _buildForm(context, textTheme),
    );
  }

  Widget _buildForm(BuildContext context, TextTheme textTheme) {
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
              BlocBuilder<AvatarBloc, AvatarState>(
                builder: (context, avatarState) =>
                    _buildAvatarSection(context, avatarState, isSaving),
              ),
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
