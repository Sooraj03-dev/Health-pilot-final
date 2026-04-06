import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_pilot/core/supabase_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Stream to emit SOS alert IDs when a notification is tapped
  final StreamController<String?> _onNotificationTap = StreamController<String?>.broadcast();
  Stream<String?> get onNotificationTap => _onNotificationTap.stream;

  RealtimeChannel? _sosChannel;

  /// Initialize local notifications and request permissions
  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onNotificationTap.add(response.payload);
      },
    );

    // Request Android 13+ permissions
    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Subscribe to Supabase Realtime for new SOS alerts
  void subscribeToSosAlerts(String doctorId) {
    if (_sosChannel != null) return; // Already subscribed

    _sosChannel = supabase.channel('public:sos_alerts');
    
    _sosChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'sos_alerts',
      callback: (PostgresChangePayload payload) {
        final alertData = payload.newRecord;
        final alertId = alertData['id']?.toString();
        
        _showSosNotification(alertId);
      },
    ).subscribe();
  }

  /// Clean up Realtime subscriptions on logout
  void unsubscribe() {
    _sosChannel?.unsubscribe();
    _sosChannel = null;
  }

  /// Fire the actual push notification
  Future<void> _showSosNotification(String? alertId) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sos_alerts_channel', // id
      'SOS Alerts', // title
      channelDescription: 'High priority alerts for patient emergencies',
      importance: Importance.high,
      priority: Priority.max,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond, // unique ID
      'SOS Alert',
      'Patient needs emergency help — tap to view',
      notificationDetails,
      payload: alertId,
    );
  }

  void dispose() {
    _onNotificationTap.close();
    unsubscribe();
  }
}
