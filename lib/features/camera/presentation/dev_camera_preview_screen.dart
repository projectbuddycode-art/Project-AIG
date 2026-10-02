import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/camera/providers/camera_providers.dart';
import 'package:aig/features/camera/models/capture_settings.dart';

class DevCameraPreviewScreen extends ConsumerStatefulWidget {
  const DevCameraPreviewScreen({super.key});

  @override
  ConsumerState<DevCameraPreviewScreen> createState() =>
      _DevCameraPreviewScreenState();
}

class _DevCameraPreviewScreenState
    extends ConsumerState<DevCameraPreviewScreen> {
  double _zoom = 1.0;

  @override
  Widget build(BuildContext context) {
    final camera = ref.read(cameraControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dev Camera Preview')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: camera.preview,
              builder: (context, snapshot) {
                // For now display a placeholder preview box
                return Container(
                  color: Colors.black,
                  child: const Center(
                    child: Text(
                      'Preview (temporary)',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => camera.switchCamera(),
                  icon: const Icon(Icons.switch_camera),
                ),
                IconButton(
                  onPressed: () => camera.flash.setFlashMode('auto'),
                  icon: const Icon(Icons.flash_auto),
                ),
                Expanded(
                  child: Slider(
                    min: 1.0,
                    max: 4.0,
                    value: _zoom,
                    onChanged: (v) => setState(() => _zoom = v),
                    onChangeEnd: (v) => camera.zoom.setZoom(v),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final res = await camera.capturePhoto(
                      const CaptureSettings(),
                    );
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Capture complete (stub) @ ${res.timestamp}',
                        ),
                      ),
                    );
                  },
                  child: const Text('Capture'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
