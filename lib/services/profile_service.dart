import 'package:flutter/foundation.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/models/user_model.dart';

/// Fetches and manages the current user's profile from the `profiles` table.
class ProfileService {
  /// Returns the [UserProfile] for the given [userId], or `null` if no row
  /// exists yet (e.g. during the brief window between signUp and the DB
  /// trigger creating the profile).
  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('[ProfileService] fetchProfile error: $e');
      return null;
    }
  }

  /// Updates editable profile fields.
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (updates.isEmpty) return;

    await supabase.from('profiles').update(updates).eq('id', userId);
  }
}
