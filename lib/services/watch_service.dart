import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/models/health_metric.dart';

/// The two Health Connect data types this service reads.
const _kTypes = [
  HealthDataType.HEART_RATE,
  HealthDataType.BLOOD_OXYGEN,
];

/// Corresponding access levels (READ-only — we never write health data).
const _kPermissions = [
  HealthDataAccess.READ,
  HealthDataAccess.READ,
];

/// How often the background sync runs.
const _kSyncInterval = Duration(minutes: 5);

/// How far back each sync window looks for fresh readings.
const _kLookbackWindow = Duration(minutes: 5);

// ---------------------------------------------------------------------------
// WatchService
// ---------------------------------------------------------------------------

/// Bridges Health Connect (via the `health` package) with Supabase.
///
/// Lifecycle:
///   1. Call [requestPermissions] once when the UI is ready.
///   2. If it returns `true`, call [startSync].
///   3. Call [stopSync] when the user signs out or the widget tree is disposed.
///
/// Permission state is exposed via [hasPermissions] and [permissionDenied]
/// so the UI can decide whether to show a permission-rationale dialog.
class WatchService {
  WatchService() : _health = Health() {
    try {
      _health.configure();
    } catch (e) {
      debugPrint('[WatchService] configure error: $e');
    }
  }

  // Allow injection in tests.
  @visibleForTesting
  WatchService.withHealth(Health health) : _health = health;

  final Health _health;
  Timer? _syncTimer;

  // ── Permission state (exposed to UI layer) ─────────────────────────────────

  bool _hasPermissions = false;
  bool _permissionDenied = false;

  /// `true` after [requestPermissions] succeeds.
  bool get hasPermissions => _hasPermissions;

  /// `true` when the user explicitly denied Health Connect permissions.
  /// The UI layer should surface a rationale dialog in this state.
  bool get permissionDenied => _permissionDenied;

  // ── Sync state ─────────────────────────────────────────────────────────────

  bool _isSyncing = false;

  /// `true` while the periodic timer is active.
  bool get isSyncing => _isSyncing;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Requests READ permissions for [HealthDataType.HEART_RATE] and
  /// [HealthDataType.BLOOD_OXYGEN] from Health Connect.
  ///
  /// Returns `true` when the user grants both permissions.
  /// Sets [permissionDenied] = `true` when the user explicitly denies them,
  /// so the UI can show a rationale dialog.
  Future<bool> requestPermissions() async {
    try {
      final granted = await _health.requestAuthorization(
        _kTypes,
        permissions: _kPermissions,
      );
      _hasPermissions = granted;
      _permissionDenied = !granted;
      return granted;
    } catch (e) {
      debugPrint('[WatchService] requestPermissions error: $e');
      _hasPermissions = false;
      _permissionDenied = true;
      return false;
    }
  }

  /// Checks whether Health Connect permissions are currently granted
  /// **without** triggering the system dialog.
  ///
  /// Useful on cold start to decide whether to call [startSync] immediately.
  Future<bool> checkPermissions() async {
    try {
      final granted = await _health.hasPermissions(
        _kTypes,
        permissions: _kPermissions,
      );
      _hasPermissions = granted ?? false;
      return _hasPermissions;
    } catch (e) {
      debugPrint('[WatchService] checkPermissions error: $e');
      return false;
    }
  }

  /// Starts a background periodic sync that runs every [_kSyncInterval].
  ///
  /// Performs an immediate sync on call, then repeats on the timer.
  /// No-op if [startSync] has already been called (idempotent).
  void startSync() {
    if (_isSyncing) return;
    _isSyncing = true;

    // Immediate first fetch so the UI isn't blank for 5 minutes.
    _syncData();

    _syncTimer = Timer.periodic(_kSyncInterval, (_) => _syncData());
    debugPrint('[WatchService] Sync started (interval: $_kSyncInterval).');
  }

  /// Cancels the background timer.
  ///
  /// Safe to call even if [startSync] was never invoked.
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isSyncing = false;
    debugPrint('[WatchService] Sync stopped.');
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Fetches the most recent HR + SpO2 readings from Health Connect and
  /// inserts a single row into `health_metrics` in Supabase.
  Future<void> _syncData() async {
    // Guard: must be authenticated.
    final user = supabase.auth.currentUser;
    if (user == null) {
      debugPrint('[WatchService] No authenticated user — skipping sync.');
      return;
    }

    // Guard: permissions must be granted.
    if (!_hasPermissions) {
      debugPrint('[WatchService] Permissions not granted — skipping sync.');
      return;
    }

    try {
      final now = DateTime.now();
      final windowStart = now.subtract(_kLookbackWindow);

      // Fetch all data points in the look-back window.
      List<HealthDataPoint> dataPoints = await _health.getHealthDataFromTypes(
        types: _kTypes,
        startTime: windowStart,
        endTime: now,
      );

      if (dataPoints.isEmpty) {
        debugPrint('[WatchService] No health data in the last $_kLookbackWindow.');
        return;
      }

      // Remove duplicate entries that Health Connect occasionally returns.
      dataPoints = _health.removeDuplicates(dataPoints);

      // Pick the most recent reading for each type.
      final latestHr = _latestPoint(dataPoints, HealthDataType.HEART_RATE);
      final latestSpO2 = _latestPoint(dataPoints, HealthDataType.BLOOD_OXYGEN);

      if (latestHr == null && latestSpO2 == null) {
        debugPrint('[WatchService] No usable data points found.');
        return;
      }

      final heartRate = _numericValue(latestHr);
      final spo2 = _numericValue(latestSpO2);

      final metric = HealthMetric(
        userId: user.id,
        heartRate: heartRate,
        spo2: spo2,
        recordedAt: now.toUtc(),
      );

      await supabase.from('health_metrics').insert(metric.toJson());

      debugPrint(
        '[WatchService] Synced → HR: ${heartRate.toStringAsFixed(1)} bpm, '
        'SpO2: ${spo2.toStringAsFixed(1)} %',
      );
    } on Exception catch (e) {
      // Surface error in debug console but don't crash the app.
      debugPrint('[WatchService] Sync failed: $e');
    }
  }

  /// Returns the [HealthDataPoint] with the latest [HealthDataPoint.dateTo]
  /// for the given [type], or `null` if none exist.
  HealthDataPoint? _latestPoint(
    List<HealthDataPoint> points,
    HealthDataType type,
  ) {
    HealthDataPoint? latest;
    for (final p in points) {
      if (p.type != type) continue;
      if (latest == null || p.dateTo.isAfter(latest.dateTo)) {
        latest = p;
      }
    }
    return latest;
  }

  /// Extracts a [double] value from a [HealthDataPoint], returning `0.0` when
  /// the point is null or has a non-numeric value type.
  double _numericValue(HealthDataPoint? point) {
    if (point == null) return 0.0;
    final v = point.value;
    if (v is NumericHealthValue) return v.numericValue.toDouble();
    return 0.0;
  }
}
