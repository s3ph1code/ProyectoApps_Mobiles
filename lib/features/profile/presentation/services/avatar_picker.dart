import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../domain/entities/avatar_image.dart';

enum AvatarSource { gallery, camera }

/// Elige una imagen del dispositivo. Existe para que la pantalla no dependa
/// del plugin y se pueda probar con un doble.
abstract class AvatarPicker {
  /// Devuelve `null` si la usuaria cierra el selector sin elegir nada.
  Future<AvatarImage?> pick(AvatarSource source);
}

class ImagePickerAvatarPicker implements AvatarPicker {
  final ImagePicker _picker;

  ImagePickerAvatarPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  @override
  Future<AvatarImage?> pick(AvatarSource source) async {
    final file = await _picker.pickImage(
      source: source == AvatarSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      // Una foto de perfil no necesita más; así casi nunca pasa de 2 MB.
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return AvatarImage(
      bytes: bytes,
      mimeType: detectImageMimeType(bytes) ?? file.mimeType ?? 'unknown',
    );
  }
}

/// Reconoce JPG, PNG y WebP por los primeros bytes del archivo, sin confiar
/// en la extensión del nombre. Devuelve `null` si no es ninguno.
String? detectImageMimeType(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}
