import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Foto de perfil redonda. Sin foto, o si no carga, muestra las [initials].
class ProfileAvatar extends StatelessWidget {
  final String initials;
  final String? avatarUrl;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.initials,
    this.avatarUrl,
    this.size = 88,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final fallback = Center(
      child: Text(
        initials,
        style: textTheme.headlineMedium?.copyWith(color: AppColors.sageDark),
      ),
    );

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.beige,
        border: Border.all(
          color: AppColors.sage.withValues(alpha: 0.18),
          width: 2,
        ),
      ),
      child: avatarUrl == null
          ? fallback
          : Image.network(
              avatarUrl!,
              key: const Key('profile_avatar_image'),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : fallback,
            ),
    );
  }
}

/// Iniciales de las dos primeras palabras del nombre («Karla Mendoza» → «KM»).
String initialsOf(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final letters = words.take(2).map((w) => w.characters.first.toUpperCase());
  final initials = letters.join();
  return initials.isEmpty ? 'D' : initials;
}
