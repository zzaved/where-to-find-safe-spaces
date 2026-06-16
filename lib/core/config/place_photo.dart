import 'env.dart';

/// Builds URLs (and auth headers) for the `place-photo` edge function, which
/// proxies Google Places photos so the Google API key stays server-side.
class PlacePhoto {
  const PlacePhoto._();

  static String url(String photoName, {int width = 800}) {
    final encoded = Uri.encodeComponent(photoName);
    return '${Env.supabaseUrl}/functions/v1/place-photo?name=$encoded&w=$width';
  }

  /// The edge function uses `verify_jwt`, so the anon JWT must be attached.
  static Map<String, String> get headers => {
        'Authorization': 'Bearer ${Env.supabaseAnonKey}',
        'apikey': Env.supabaseAnonKey,
      };
}
