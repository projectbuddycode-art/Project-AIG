import 'package:aig/core/constants/app_constants.dart';
import 'package:aig/features/esp32/models/device_connection_state.dart';
import 'package:aig/features/esp32/providers/device_connection_manager_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceConnectionScreen extends ConsumerWidget {
  const DeviceConnectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(discoveredDevicesProvider);
    final connectionAsync = ref.watch(connectionStateProvider);
    final manager = ref.read(deviceConnectionManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Connection'),
        backgroundColor: AppConstants.background,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            connectionAsync.when(
              data: (state) => Text(connectionStatusLabel(state.status)),
              loading: () => const Text('State: loading'),
              error: (error, _) => Text('State error: $error'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: devicesAsync.when(
                data: (devices) => ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      title: Text(device.name),
                      subtitle: Text('RSSI: ${device.rssi}'),
                      trailing: Text(device.id),
                      onTap: () => manager.connect(device),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Scan error: $error')),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: manager.startScan,
                    child: const Text('Start Scan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: manager.stopScan,
                    child: const Text('Stop Scan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: manager.disconnect,
                    child: const Text('Disconnect'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: manager.reconnect,
                    child: const Text('Reconnect'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
