import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_pilot/models/health_metric.dart';

/// Streams the single latest [HealthMetric] for the current user in real-time.
///
/// Uses Supabase's `.stream()` API so the dashboard updates automatically
/// whenever a new row is inserted into `health_metrics` — no polling needed.
final healthMetricsProvider = StreamProvider<HealthMetric?>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Stream.value(null);

  return Supabase.instance.client
      .from('health_metrics')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('recorded_at', ascending: false)
      .limit(1)
      .map((data) => data.isEmpty ? null : HealthMetric.fromJson(data.first));
});

/// Streams the real-time health metrics specifically for a caregiver tracking their assigned patient.
final caregiverHealthMetricsProvider = StreamProvider.family<HealthMetric?, String>((ref, patientId) {
  return Supabase.instance.client
      .from('health_metrics')
      .stream(primaryKey: ['id'])
      .eq('user_id', patientId)
      .order('recorded_at', ascending: false)
      .limit(1)
      .map((data) => data.isEmpty ? null : HealthMetric.fromJson(data.first));
});
