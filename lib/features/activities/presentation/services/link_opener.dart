import 'package:url_launcher/url_launcher.dart';

/// Abre un enlace externo. Existe para que la pantalla no dependa del plugin
/// y se pueda probar con un doble.
abstract class LinkOpener {
  /// `false` si el enlace no es válido o el sistema no pudo abrirlo; la
  /// pantalla avisa en vez de fallar.
  Future<bool> open(String url);
}

class UrlLauncherLinkOpener implements LinkOpener {
  const UrlLauncherLinkOpener();

  @override
  Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}
