import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pilot/services/watch_service.dart';
import 'package:health_pilot/services/sos_service.dart';
import 'package:health_pilot/screens/vitals/vitals_screen.dart';
import 'package:health_pilot/widgets/sos_button.dart';

class PatientDashboard extends ConsumerStatefulWidget {
  const PatientDashboard({super.key});

  @override
  ConsumerState<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends ConsumerState<PatientDashboard> {
  final WatchService _watchService = WatchService();
  final SosService _sosService = SosService();

  @override
  void initState() {
    super.initState();
    // Automatically start synchronization when dashboard loads
    _watchService.startSync();
  }

  @override
  void dispose() {
    _watchService.stopSync();
    super.dispose();
  }

  Future<bool> _handleSosTrigger() async {
    final result = await _sosService.triggerSOS();
    
    if (mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS Alert Sent Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send SOS. Check permissions.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern off-white
      appBar: AppBar(
        title: const Text(
          'HEALTH PILOT',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Welcome Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.person, color: Colors.blue, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning,',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                      const Text(
                        'Patient User',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Live Vitals Section
            const VitalsScreen(),
            
            const SizedBox(height: 48),

            // SOS Section
            const Text(
              'EMERGENCY HELP',
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Long press for 3 seconds to trigger',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 32),
            
            // Central SOS Button
            Center(
              child: SosButton(
                onTriggered: _handleSosTrigger,
              ),
            ),
            
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}
