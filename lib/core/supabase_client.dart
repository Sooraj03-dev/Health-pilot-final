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
