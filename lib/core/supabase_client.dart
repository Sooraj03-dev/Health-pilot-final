import 'package:supabase_flutter/supabase_flutter.dart';

/// Global Supabase client singleton.
///
/// Access anywhere via:
/// ```dart
/// import 'package:health_pilot/core/supabase_client.dart';
/// final user = supabase.auth.currentUser;
/// ```
final supabase = Supabase.instance.client;
