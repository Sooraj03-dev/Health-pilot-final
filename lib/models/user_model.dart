/// Dart model for the `profiles` Supabase table.
class UserProfile {
  final String id;
  final String? fullName;
  final String role;        // 'patient' | 'doctor' | 'caregiver'
  final bool isVerified;
  final String? avatarUrl;
  final DateTime? createdAt;
  final bool profileSetupDone;

  // ── Patient fields ──────────────────────────────
  final DateTime? dob;
  final String? gender;
  final String? phone;
  final String? bloodGroup;
  final List<String> allergies;
  final String? pastIllnesses;       // free-text fallback
  final String? medications;         // free-text fallback
  final double? heightCm;
  final double? weightKg;
  final String? emergencyContact;

  // ── Doctor fields ───────────────────────────────
  final String? highestQualification;
  final String? specialization;
  final String? clinicDetails;
  final String? experience;
  final String? registrationCouncil;
  final String? clinicName;
  final String? clinicTimings;        // JSON string for days+times
  final List<String> licenseUrls;

  const UserProfile({
    required this.id,
    this.fullName,
    required this.role,
    this.isVerified = false,
    this.avatarUrl,
    this.createdAt,
    this.profileSetupDone = false,
    this.dob,
    this.gender,
    this.phone,
    this.bloodGroup,
    this.allergies = const [],
    this.pastIllnesses,
    this.medications,
    this.heightCm,
    this.weightKg,
    this.emergencyContact,
    this.highestQualification,
    this.specialization,
    this.clinicDetails,
    this.experience,
    this.registrationCouncil,
    this.clinicName,
    this.clinicTimings,
    this.licenseUrls = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<String> splitField(String? raw) =>
        (raw == null || raw.trim().isEmpty) ? [] : raw.split(',').map((e) => e.trim()).toList();

    return UserProfile(
      id: (json['user_id'] ?? json['id'] ?? '') as String,
      fullName: json['full_name'] as String?,
      role: (json['role'] as String?) ?? 'patient',
      isVerified: (json['is_verified'] as bool?) ?? false,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      profileSetupDone: (json['profile_setup_done'] as bool?) ?? false,
      dob: json['dob'] != null ? DateTime.tryParse(json['dob'] as String) : null,
      gender: json['gender'] as String?,
      phone: json['phone'] as String?,
      bloodGroup: json['blood_group'] as String?,
      allergies: splitField(json['allergies'] as String?),
      pastIllnesses: json['past_illnesses'] as String?,
      medications: json['medications'] as String?,
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      emergencyContact: json['emergency_contact'] as String?,
      highestQualification: json['highest_qualification'] as String?,
      specialization: json['specialization'] as String?,
      clinicDetails: json['clinic_details'] as String?,
      experience: json['experience'] as String?,
      registrationCouncil: json['registration_council'] as String?,
      clinicName: json['clinic_name'] as String?,
      clinicTimings: json['clinic_timings'] as String?,
      licenseUrls: splitField(json['license_urls'] as String?),
    );
  }

  double get completeness {
    if (role == 'patient') {
      const total = 10;
      int filled = 0;
      if (fullName?.isNotEmpty == true) filled++;
      if (dob != null) filled++;
      if (gender?.isNotEmpty == true) filled++;
      if (bloodGroup?.isNotEmpty == true) filled++;
      if (phone?.isNotEmpty == true) filled++;
      if (allergies.isNotEmpty) filled++;
      if (medications?.isNotEmpty == true) filled++;
      if (heightCm != null) filled++;
      if (weightKg != null) filled++;
      if (avatarUrl?.isNotEmpty == true) filled++;
      return filled / total;
    } else if (role == 'doctor') {
      const total = 9;
      int filled = 0;
      if (fullName?.isNotEmpty == true) filled++;
      if (highestQualification?.isNotEmpty == true) filled++;
      if (specialization?.isNotEmpty == true) filled++;
      if (experience?.isNotEmpty == true) filled++;
      if (phone?.isNotEmpty == true) filled++;
      if (clinicName?.isNotEmpty == true) filled++;
      if (clinicTimings?.isNotEmpty == true) filled++;
      if (registrationCouncil?.isNotEmpty == true) filled++;
      if (avatarUrl?.isNotEmpty == true) filled++;
      return filled / total;
    }
    return 1.0;
  }

  /// True once the user has completed the setup screen once.
  bool get hasMinimalProfile => profileSetupDone;

  @override
  String toString() =>
      'UserProfile(id: $id, name: $fullName, role: $role, completeness: ${(completeness * 100).toStringAsFixed(0)}%)';
}
