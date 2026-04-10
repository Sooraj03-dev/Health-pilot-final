/// Dart model for the `health_metrics` Supabase table.
///
/// Table schema:
///   id          uuid        PK  (server-generated)
///   user_id     uuid        FK → auth.users.id
///   heart_rate  float8
///   spo2        float8
///   recorded_at timestamptz
///   created_at  timestamptz (server-generated default)
class HealthMetric {
  final String? id;
  final String userId;
  final double heartRate;
  final double spo2;
  final int? sleepDurationMinutes;
  final String? sleepQuality;
  final DateTime recordedAt;
  final DateTime? createdAt;

  const HealthMetric({
    this.id,
    required this.userId,
    required this.heartRate,
    required this.spo2,
    this.sleepDurationMinutes,
    this.sleepQuality,
    required this.recordedAt,
    this.createdAt,
  });

  /// Returns formatted sleep duration, e.g. "7h 45m" or "--" if null.
  String get formattedSleep {
    if (sleepDurationMinutes == null) return '--';
    final hours = sleepDurationMinutes! ~/ 60;
    final minutes = sleepDurationMinutes! % 60;
    return '${hours}h ${minutes}m';
  }

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  factory HealthMetric.fromJson(Map<String, dynamic> json) {
    return HealthMetric(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      heartRate: (json['heart_rate'] as num).toDouble(),
      spo2: (json['spo2'] as num).toDouble(),
      sleepDurationMinutes: json['sleep_duration_minutes'] as int?,
      sleepQuality: json['sleep_quality'] as String?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Returns the JSON map used when **inserting** a new row.
  /// `id` and `created_at` are intentionally omitted — Postgres generates them.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'heart_rate': heartRate,
      'spo2': spo2,
      if (sleepDurationMinutes != null)
        'sleep_duration_minutes': sleepDurationMinutes,
      if (sleepQuality != null) 'sleep_quality': sleepQuality,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  HealthMetric copyWith({
    String? id,
    String? userId,
    double? heartRate,
    double? spo2,
    int? sleepDurationMinutes,
    String? sleepQuality,
    DateTime? recordedAt,
    DateTime? createdAt,
  }) {
    return HealthMetric(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      sleepDurationMinutes: sleepDurationMinutes ?? this.sleepDurationMinutes,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthMetric &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          heartRate == other.heartRate &&
          spo2 == other.spo2 &&
          recordedAt == other.recordedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      heartRate.hashCode ^
      spo2.hashCode ^
      recordedAt.hashCode;

  @override
  String toString() =>
      'HealthMetric(id: $id, userId: $userId, heartRate: $heartRate, '
      'spo2: $spo2, recordedAt: $recordedAt)';
}
