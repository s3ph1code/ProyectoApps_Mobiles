import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Punto único de arranque de Supabase. Lee `.env`, valida que las claves
/// existan e inicializa el cliente antes de que se construya la app.
class SupabaseConfig {
  SupabaseConfig._();

  static const _envFile = '.env';
  static const _urlKey = 'SUPABASE_URL';
  static const _anonKeyKey = 'SUPABASE_ANON_KEY';

  static Future<void> initialize() async {
    await dotenv.load(fileName: _envFile);

    final url = _require(_urlKey);
    final anonKey = _require(_anonKeyKey);

    // Supabase renombró la anon key a «publishable key»; es la misma clave
    // pública que aparece en los ajustes de API del proyecto.
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static String _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError(
        'Falta $key en $_envFile. Copia .env.example a .env y complétalo con '
        'los datos del proyecto de Supabase.',
      );
    }
    return value;
  }
}
