<<<<<<< HEAD
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initialise Supabase once at app start-up (call from main()).
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
}

/// Global convenience accessor — mirrors the pattern used throughout the
/// Supabase Flutter documentation.
SupabaseClient get supabase => Supabase.instance.client;
=======
import 'package:supabase_flutter/supabase_flutter.dart';

/// Global Supabase client singleton.
///
/// Access anywhere via:
/// ```dart
/// import 'package:health_pilot/core/supabase_client.dart';
/// final user = supabase.auth.currentUser;
/// ```
final supabase = Supabase.instance.client;
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
