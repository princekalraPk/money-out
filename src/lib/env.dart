import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads configuration from --dart-define first, then from the bundled .env.
class Env {
  const Env._();

  static const _urlDefine = String.fromEnvironment('SUPABASE_URL');
  static const _keyDefine = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static String get url => _value(_urlDefine, 'SUPABASE_URL');

  static String get publishableKey =>
      _value(_keyDefine, 'SUPABASE_PUBLISHABLE_KEY');

  static String _value(String fromDefine, String key) {
    if (fromDefine.isNotEmpty) return fromDefine;
    try {
      return dotenv.env[key] ?? '';
    } catch (_) {
      return '';
    }
  }

  static List<String> missing() {
    return [
      if (url.isEmpty) 'SUPABASE_URL',
      if (publishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
    ];
  }
}
