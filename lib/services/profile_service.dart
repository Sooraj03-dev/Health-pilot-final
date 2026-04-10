import 'package:flutter/foundation.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/models/user_model.dart';

/// Fetches and manages the current user's profile from the `profiles` table.
class ProfileService {
  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('[ProfileService] fetchProfile error: $e');
      return null;
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    bool? profileSetupDone,
    // Patient fields
    DateTime? dob,
    String? gender,
    String? phone,
    String? bloodGroup,
    List<String>? allergies,
    String? pastIllnesses,
    String? medications,
    double? heightCm,
    double? weightKg,
    String? emergencyContact,
    // Doctor fields
    String? highestQualification,
    String? specialization,
    String? clinicDetails,
    String? experience,
    String? registrationCouncil,
    String? clinicName,
    String? clinicTimings,
    List<String>? licenseUrls,
  }) async {
    final updates = <String, dynamic>{};

    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (profileSetupDone != null) updates['profile_setup_done'] = profileSetupDone;
    if (dob != null) updates['dob'] = dob.toIso8601String().split('T')[0];
    if (gender != null) updates['gender'] = gender;
    if (phone != null) updates['phone'] = phone;
    if (bloodGroup != null) updates['blood_group'] = bloodGroup;
    if (allergies != null) updates['allergies'] = allergies.join(',');
    if (pastIllnesses != null) updates['past_illnesses'] = pastIllnesses;
    if (medications != null) updates['medications'] = medications;
    if (heightCm != null) updates['height_cm'] = heightCm;
    if (weightKg != null) updates['weight_kg'] = weightKg;
    if (emergencyContact != null) updates['emergency_contact'] = emergencyContact;
    if (highestQualification != null) updates['highest_qualification'] = highestQualification;
    if (specialization != null) updates['specialization'] = specialization;
    if (clinicDetails != null) updates['clinic_details'] = clinicDetails;
    if (experience != null) updates['experience'] = experience;
    if (registrationCouncil != null) updates['registration_council'] = registrationCouncil;
    if (clinicName != null) updates['clinic_name'] = clinicName;
    if (clinicTimings != null) updates['clinic_timings'] = clinicTimings;
    if (licenseUrls != null) updates['license_urls'] = licenseUrls.join(',');

    if (updates.isEmpty) return;
    debugPrint('[ProfileService] Saving to Supabase for $userId: ${updates.keys.toList()}');
    await supabase.from('profiles').update(updates).eq('user_id', userId);
    debugPrint('[ProfileService] ✅ Save complete for $userId');
  }
}
