import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/models/health_metric.dart';

final healthMetricsProvider = FutureProvider.autoDispose<List<HealthMetric>>((ref) async {
  // Auto-refresh every 30 seconds
  final timer = Timer(const Duration(seconds: 30), () {
    ref.invalidateSelf();
  });
  
  ref.onDispose(() {
    timer.cancel();
  });

  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception('User is not logged in');
  }

  // Fetch the latest 10 rows
  final response = await supabase
      .from('health_metrics')
      .select()
      .eq('user_id', user.id)
      .order('recorded_at', ascending: false)
      .limit(10);

  final metrics = (response as List<dynamic>)
      .map((json) => HealthMetric.fromJson(json as Map<String, dynamic>))
      .toList();

  // Reverse list so oldest is first, newest is last (better for plotting graphs left-to-right)
  return metrics.reversed.toList();
});
