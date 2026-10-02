import 'package:flutter_test/flutter_test.dart';

import 'package:aig/features/camera/models/jewelry_filter.dart';
import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';
import 'package:aig/features/camera/preset_studio/services/preset_manager.dart';
import 'package:aig/features/camera/preset_studio/services/preset_validation.dart';
import 'package:aig/features/esp32/protocol/diamondcam_protocol.dart';

void main() {
  test('light body uses firmware contract', () {
    final body = DiamondCamProtocol.lightBody(state: true, intensity: 80);
    expect(body, {'state': true, 'intensity': 80});
    final off = DiamondCamProtocol.lightBody(state: false, intensity: 0);
    expect(off['state'], isFalse);
    expect(off['intensity'], 0);
  });

  test('filter labels cover advertising names without raw enums', () {
    expect(
      jewelryProcessingLookLabel(JewelryProcessingLook.original),
      'Original / Natural',
    );
    expect(
      jewelryProcessingLookLabel(JewelryProcessingLook.gemstoneCloseup),
      'Diamond Clarity',
    );
    expect(
      jewelryProcessingLookLabel(JewelryProcessingLook.premiumShowcase),
      'Luxury Warm',
    );
    expect(
      jewelryProcessingLookLabel(JewelryProcessingLook.coolStudio),
      'Cool Studio',
    );
    expect(
      jewelryProcessingLookLabel(JewelryProcessingLook.highContrast),
      'High Contrast',
    );
    expect(
      jewelryProcessingLookLabel(JewelryProcessingLook.luxuryDark),
      'Dark Luxury',
    );
    expect(
      jewelryProcessingLookLabel(JewelryProcessingLook.ecommerceNeutral),
      'E-commerce Clean',
    );
    expect(
      jewelryProcessingLookLabel(JewelryProcessingLook.socialPortrait),
      'Social Media',
    );
    for (final look in studioFilterLooks) {
      expect(jewelryProcessingLookLabel(look).contains('.'), isFalse);
    }
  });

  test('filter matrices are identity at zero strength', () {
    final matrix = jewelryFilterColorMatrix(
      JewelryProcessingLook.highContrast,
      0,
    );
    expect(matrix[0], closeTo(1, 0.0001));
    expect(matrix[6], closeTo(1, 0.0001));
    expect(matrix[12], closeTo(1, 0.0001));
  });

  test('filter overlay is transparent for original', () {
    expect(jewelryFilterOverlay(JewelryProcessingLook.original, 100).a, 0);
  });

  test('preset validation rejects filter strength outside 0-100', () {
    const manager = PresetManager();
    const validation = PresetValidation();
    expect(
      validation.validate(
        manager.builtInPresets.first.copyWith(filterStrength: 140),
      ),
      contains('Filter strength'),
    );
  });

  test('session look override fields copy onto preset', () {
    const manager = PresetManager();
    final preset = manager
        .getPreset('full-360-showcase')
        .copyWith(
          processingLook: JewelryProcessingLook.coolStudio,
          filterStrength: 40,
          lightOn: false,
          lightIntensity: 12,
        );
    expect(preset.processingLook, JewelryProcessingLook.coolStudio);
    expect(preset.filterStrength, 40);
    expect(preset.lightOn, isFalse);
    expect(preset.lightIntensity, 12);
  });
}
