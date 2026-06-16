import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Strongly-typed access to environment variables loaded from the bundled
/// `.env` asset. Only public client configuration lives here — the Google
/// Maps and Perplexity keys are kept server-side in the Supabase functions.
class Env {
  const Env._();

  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

  static String _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError('Missing required env var "$key". Check your .env file.');
    }
    return value;
  }
}
