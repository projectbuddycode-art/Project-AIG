import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/esp32/providers/machine_controllers_providers.dart';
import 'package:aig/features/esp32/models/rotation_config.dart';

class DevMachineControlScreen extends ConsumerStatefulWidget {
  const DevMachineControlScreen({super.key});

  @override
  ConsumerState<DevMachineControlScreen> createState() => _DevMachineControlScreenState();
}

class _DevMachineControlScreenState extends ConsumerState<DevMachineControlScreen> {
  double _speed = 0.5;
  bool _clockwise = true;
  bool _continuous = false;
  double _step = 1.0;
  double _brightness = 1.0;

  @override
  Widget build(BuildContext context) {
    final machine = ref.read(machineControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dev Machine Control')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rotation', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(children: [
              ElevatedButton(
                  onPressed: () => machine.rotation.start(RotationConfig(speed: _speed, clockwise: _clockwise, continuous: _continuous)),
                  child: const Text('Start')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () => machine.rotation.pause(), child: const Text('Pause')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () => machine.rotation.resume(), child: const Text('Resume')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () => machine.rotation.stop(), child: const Text('Stop')),
            ]),
            Row(children: [
              const Text('Speed'),
              Expanded(
                child: Slider(value: _speed, min: 0, max: 5, onChanged: (v) => setState(() => _speed = v)),
              ),
            ]),
            Row(children: [
              const Text('Direction'),
              Switch(value: _clockwise, onChanged: (v) => setState(() => _clockwise = v)),
              const Text('Clockwise'),
            ]),
            Row(children: [
              const Text('Continuous'),
              Switch(value: _continuous, onChanged: (v) => setState(() => _continuous = v)),
            ]),
            Row(children: [
              const Text('Step (deg)'),
              SizedBox(
                width: 80,
                child: TextFormField(initialValue: _step.toString(), onChanged: (v) => setState(() => _step = double.tryParse(v) ?? 1.0)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () => machine.rotation.step(_step, RotationConfig(speed: _speed, clockwise: _clockwise, continuous: false)), child: const Text('Step')),
            ]),

            const Divider(),

            const Text('Lighting', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(children: [
              const Text('Master'),
              Expanded(child: Slider(value: _brightness, min: 0, max: 1, onChanged: (v) => setState(() => _brightness = v))),
              ElevatedButton(onPressed: () => machine.lighting.setMasterBrightness(_brightness), child: const Text('Set')),
            ]),

            const Divider(),

            const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(children: [
              ElevatedButton(onPressed: () => machine.status.requestStatus(), child: const Text('Request Status')),
            ]),

            const Divider(),

            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => machine.safety.emergencyStop(),
                child: const Text('EMERGENCY STOP')),
          ],
        ),
      ),
    );
  }
}
