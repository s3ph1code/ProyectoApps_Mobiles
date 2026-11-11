import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Imagen elegida para la foto de perfil, ya leída en memoria.
class AvatarImage extends Equatable {
  final Uint8List bytes;
  final String mimeType;

  const AvatarImage({required this.bytes, required this.mimeType});

  @override
  List<Object?> get props => [bytes, mimeType];
}
