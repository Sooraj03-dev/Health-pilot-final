/// Dart model for the `profiles` Supabase table.
class UserProfile {
  final String id;
  final String? fullName;
  final String role;        // 'patient' | 'doctor' | 'caregiver'
  final bool isVerified;
  final String? avatarUrl;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    this.fullName,
    required this.role,
    this.isVerified = false,
    this.avatarUrl,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['user_id'] ?? json['id'] ?? '') as String,
      fullName: json['full_name'] as String?,
      role: (json['role'] as String?) ?? 'patient',
      isVerified: (json['is_verified'] as bool?) ?? false,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (fullName != null) 'full_name': fullName,
        'role': role,
        'is_verified': isVerified,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

  @override
  String toString() =>
      'UserProfile(id: $id, name: $fullName, role: $role, verified: $isVerified)';
}
