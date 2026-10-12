/// Supabase configuration.
///
/// Values come from the Supabase dashboard:
///   Project Settings → Data API   → Project URL
///   Project Settings → API Keys   → Publishable key (sb_publishable_...)
///
/// ⚠️  Only use the publishable key here.
///     Never put a secret key (sb_secret_...) or legacy service_role key
///     in a Flutter app — they bypass Row Level Security entirely.
class SupabaseConfig {
  SupabaseConfig._();

  /// Project URL, e.g. https://abcdefghij.supabase.co
  static const String url = 'https://uajtnxcljfcluugwwoxh.supabase.co';

  /// Publishable key (safe for client apps).
  static const String anonKey = 'sb_publishable_shr970G0Ty1tzwgbNRAT8A_-TJ2SlcH';
}