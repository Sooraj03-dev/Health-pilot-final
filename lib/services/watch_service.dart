import 'dart:async';
import 'package:health/health.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/models/health_metric.dart';

class WatchService {
  final Health _health = Health();
  Timer? _syncTimer;
  bool _isSyncing = false;
  bool _hasPermissions = false;

  /// Expose permission status for UI
  bool get hasPermissions => _hasPermissions;

  /// Request permissions for reading Health data.
  Future<bool> requestPermissions() async {
    final types = [
      HealthDataType.HEART_RATE,
      HealthDataType.BLOOD_OXYGEN,
    ];

    final permissions = [
      HealthDataAccess.READ,
      HealthDataAccess.READ,
    ];

    try {
      bool requesting = await _health.requestAuthorization(types, permissions: permissions);
      _hasPermissions = requesting;
      return requesting;
    } catch (e) {
      print('Error requesting health permissions: \$e');
      _hasPermissions = false;
      return false;
    }
  }

  /// Start periodic sync every 5 minutes
  void startSync() {
    if (_isSyncing) return;
    
    _isSyncing = true;
    _syncData(); // Initial sync immediately
    
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _syncData();
    });
  }

  /// Stop background sync
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isSyncing = false;
  }

  /// Fetch latest health data and insert into Supabase
  Future<void> _syncData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print('No user logged in. Aborting health sync.');
      return;
    }

    try {
      final now = DateTime.now();
      // Fetch data for the last 5 minutes to ensure we get the latest reading
      final startTime = now.subtract(const Duration(minutes: 5));
      
      final types = [
        HealthDataType.HEART_RATE,
        HealthDataType.BLOOD_OXYGEN,
      ];

      // Request data
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: types,
        startTime: startTime,
        endTime: now,
      );

      if (healthData.isEmpty) {
        print('No recent health data found.');
        return; // Nothing to sync
      }

      healthData = _health.removeDuplicates(healthData);

      // Find the most recent heart rate and spO2
      HealthDataPoint? latestHr;
      HealthDataPoint? latestSpO2;

      for (var point in healthData) {
        if (point.type == HealthDataType.HEART_RATE) {
          if (latestHr == null || point.dateTo.isAfter(latestHr.dateTo)) {
            latestHr = point;
          }
        } else if (point.type == HealthDataType.BLOOD_OXYGEN) {
          if (latestSpO2 == null || point.dateTo.isAfter(latestSpO2.dateTo)) {
            latestSpO2 = point;
          }
        }
      }

      if (latestHr == null && latestSpO2 == null) {
        return; // No valid reading
      }

      // Convert health package value
      double heartRate = 0.0;
      double spo2 = 0.0;
      
      if (latestHr != null && latestHr.value is NumericHealthValue) {
        heartRate = (latestHr.value as NumericHealthValue).numericValue.toDouble();
      }
      
      if (latestSpO2 != null && latestSpO2.value is NumericHealthValue) {
        spo2 = (latestSpO2.value as NumericHealthValue).numericValue.toDouble();
      }

      // Create model
      final metric = HealthMetric(
        userId: user.id,
        heartRate: heartRate,
        spo2: spo2,
        recordedAt: now.toUtc(),
      );

      // Insert into Supabase
      await supabase.from('health_metrics').insert(metric.toJson());
      print('Successfully synchronized health data: HR: \$heartRate, SpO2: \$spo2');

    } catch (e) {
      print('Failed to sync health data: \$e');
    }
  }
}
