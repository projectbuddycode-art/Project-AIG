import 'package:flutter_test/flutter_test.dart';

import 'package:aig/features/camera/models/capture_settings.dart';
import 'package:aig/features/capture/models/capture_mode.dart';
import 'package:aig/features/capture/models/capture_session.dart';

void main() {
  test('CaptureSession preserves preset metadata for workflow integration', () {
    final session = CaptureSession(
      id: 'session-1',
      mode: CaptureMode.singlePhoto,
      presetId: 'diamond-luxury-360',
      description: 'luxury capture',
    );

    expect(session.presetId, 'diamond-luxury-360');
    expect(session.description, 'luxury capture');
  });

  test('CaptureSettings copyWith updates image quality', () {
    const settings = CaptureSettings(jpegQuality: 80);
    final updated = settings.copyWith(jpegQuality: 95);

    expect(updated.jpegQuality, 95);
    expect(updated.enableRaw, false);
  });
}
