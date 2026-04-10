class SosAlert {
  final String? id;
  final String patientId;
  final double lat;
  final double lng;
  final String riskLevel;
  final String? aiVerdict;
  final DateTime createdAt;

  SosAlert({
    this.id,
    required this.patientId,
    required this.lat,
    required this.lng,
    required this.riskLevel,
    this.aiVerdict,
    required this.createdAt,
  });

  factory SosAlert.fromJson(Map<String, dynamic> json) {
    return SosAlert(
      id: json['id'] as String?,
      patientId: json['patient_id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      riskLevel: json['risk_level'] as String,
      aiVerdict: json['ai_verdict'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      'lat': lat,
      'lng': lng,
      'risk_level': riskLevel,
      if (aiVerdict != null) 'ai_verdict': aiVerdict,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
