import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pilot/providers/health_provider.dart';
import 'package:health_pilot/services/watch_service.dart';
import 'package:health_pilot/widgets/vitals_card.dart';

class VitalsScreen extends ConsumerStatefulWidget {
  const VitalsScreen({super.key});

  @override
  ConsumerState<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends ConsumerState<VitalsScreen> {
  final WatchService _watchService = WatchService();
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _hasPermissions = _watchService.hasPermissions;
  }

  Future<void> _requestPermissions() async {
    final granted = await _watchService.requestPermissions();
    if (mounted) {
      setState(() {
        _hasPermissions = granted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(healthMetricsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_hasPermissions) ...[
          MaterialBanner(
            padding: const EdgeInsets.all(16),
            content: const Text('Health data access is required to display live vitals.'),
            leading: const Icon(Icons.warning, color: Colors.orange),
            backgroundColor: Colors.orange.shade50,
            actions: [
              TextButton(
                onPressed: _requestPermissions,
                child: const Text('GRANT ACCESS'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LIVE VITALS',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              metricsAsync.when(
                data: (metrics) {
                  if (metrics.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No health data available yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  final latest = metrics.last; // Last because list is reversed
                  final hrData = metrics.map((m) => m.heartRate).toList();
                  final spo2Data = metrics.map((m) => m.spo2).toList();
                  
                  // Simple logic to map the badges to 'Normal' per the design
                  String hrStatus = (latest.heartRate > 50 && latest.heartRate < 110) ? 'Normal' : 'Warning';
                  Color hrColor = hrStatus == 'Normal' ? Colors.teal : Colors.red;
                  
                  String spo2Status = (latest.spo2 >= 95) ? 'Normal' : 'Warning';
                  Color spo2Color = spo2Status == 'Normal' ? Colors.teal : Colors.red;

                  return Row(
                    children: [
                      Expanded(
                        child: VitalsCard(
                          label: 'HEART RATE BPM',
                          value: latest.heartRate.toInt().toString(),
                          unit: '',
                          statusText: hrStatus,
                          statusColor: hrColor,
                          borderColor: Colors.red.shade400,
                          iconData: Icons.favorite,
                          dataPoints: hrData,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: VitalsCard(
                          label: 'SPO2 LEVEL',
                          value: latest.spo2.toInt().toString(),
                          unit: '%',
                          statusText: spo2Status,
                          statusColor: spo2Color,
                          borderColor: Colors.blue.shade600,
                          iconData: Icons.water_drop,
                          dataPoints: spo2Data,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text('Error loading vitals: \$error'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
