import 'package:geolocator/geolocator.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/models/sos_alert.dart';

class SosService {
  /// Triggers an SOS alert.
  /// Returns true if successful, false if permission denied or error.
  Future<bool> triggerSOS() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print('User must be logged in to trigger SOS');
      return false;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          // Strictly prevent firing if denied, as requested
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return false;
      }

      // Permissions are granted, fetch location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final alert = SosAlert(
        patientId: user.id,
        lat: position.latitude,
        lng: position.longitude,
        riskLevel: 'unknown',
        aiVerdict: null,
        createdAt: DateTime.now().toUtc(),
      );

      await supabase.from('sos_alerts').insert(alert.toJson());
      
      print('SOS Alert successfully sent to database.');
      return true;

    } catch (e) {
      print('Error triggering SOS: \$e');
      return false;
    }
  }
}
