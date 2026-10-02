import 'dart:ui';

import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';

class JewelryLookPreview {
  const JewelryLookPreview({required this.look, this.strength = 70});

  final JewelryProcessingLook look;
  final int strength;

  double get t => (strength.clamp(0, 100)) / 100.0;

  JewelryLookPreview copyWith({JewelryProcessingLook? look, int? strength}) {
    return JewelryLookPreview(
      look: look ?? this.look,
      strength: strength ?? this.strength,
    );
  }
}

String jewelryProcessingLookLabel(JewelryProcessingLook look) {
  switch (look) {
    case JewelryProcessingLook.original:
      return 'Original / Natural';
    case JewelryProcessingLook.gemstoneCloseup:
      return 'Diamond Clarity';
    case JewelryProcessingLook.premiumShowcase:
      return 'Luxury Warm';
    case JewelryProcessingLook.coolStudio:
      return 'Cool Studio';
    case JewelryProcessingLook.highContrast:
      return 'High Contrast';
    case JewelryProcessingLook.luxuryDark:
      return 'Dark Luxury';
    case JewelryProcessingLook.ecommerceNeutral:
      return 'E-commerce Clean';
    case JewelryProcessingLook.socialPortrait:
      return 'Social Media';
    case JewelryProcessingLook.slowElegant:
      return 'Luxury Slow';
  }
}

const List<JewelryProcessingLook> studioFilterLooks = <JewelryProcessingLook>[
  JewelryProcessingLook.original,
  JewelryProcessingLook.gemstoneCloseup,
  JewelryProcessingLook.premiumShowcase,
  JewelryProcessingLook.coolStudio,
  JewelryProcessingLook.highContrast,
  JewelryProcessingLook.luxuryDark,
  JewelryProcessingLook.ecommerceNeutral,
  JewelryProcessingLook.socialPortrait,
];

List<double> jewelryFilterColorMatrix(
  JewelryProcessingLook look,
  int strength,
) {
  final t = (strength.clamp(0, 100)) / 100.0;
  return _lerpMatrix(_identity, _matrixFor(look), t);
}

Color jewelryFilterOverlay(JewelryProcessingLook look, int strength) {
  final t = (strength.clamp(0, 100)) / 100.0;
  if (look == JewelryProcessingLook.original || t <= 0) {
    return const Color(0x00000000);
  }
  switch (look) {
    case JewelryProcessingLook.gemstoneCloseup:
      return Color.fromRGBO(180, 210, 255, 0.10 * t);
    case JewelryProcessingLook.premiumShowcase:
      return Color.fromRGBO(255, 196, 120, 0.12 * t);
    case JewelryProcessingLook.coolStudio:
      return Color.fromRGBO(140, 190, 255, 0.12 * t);
    case JewelryProcessingLook.highContrast:
      return Color.fromRGBO(0, 0, 0, 0.08 * t);
    case JewelryProcessingLook.luxuryDark:
      return Color.fromRGBO(0, 0, 0, 0.22 * t);
    case JewelryProcessingLook.ecommerceNeutral:
      return Color.fromRGBO(255, 255, 255, 0.06 * t);
    case JewelryProcessingLook.socialPortrait:
      return Color.fromRGBO(255, 180, 110, 0.10 * t);
    case JewelryProcessingLook.slowElegant:
      return Color.fromRGBO(40, 20, 10, 0.14 * t);
    case JewelryProcessingLook.original:
      return const Color(0x00000000);
  }
}

const List<double> _identity = <double>[
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

List<double> _matrixFor(JewelryProcessingLook look) {
  switch (look) {
    case JewelryProcessingLook.original:
      return _identity;
    case JewelryProcessingLook.gemstoneCloseup:
      return _contrastMatrix(1.12, 0.98, 1.00, 1.06, -0.02);
    case JewelryProcessingLook.premiumShowcase:
      return _contrastMatrix(1.08, 1.08, 1.01, 0.92, -0.02);
    case JewelryProcessingLook.coolStudio:
      return _contrastMatrix(1.06, 0.92, 1.00, 1.10, 0.00);
    case JewelryProcessingLook.highContrast:
      return _contrastMatrix(1.22, 1.00, 1.00, 1.00, -0.04);
    case JewelryProcessingLook.luxuryDark:
      return _contrastMatrix(1.14, 1.04, 1.00, 0.90, -0.08);
    case JewelryProcessingLook.ecommerceNeutral:
      return _contrastMatrix(1.04, 1.00, 1.00, 1.00, 0.02);
    case JewelryProcessingLook.socialPortrait:
      return _contrastMatrix(1.10, 1.05, 1.00, 0.94, -0.03);
    case JewelryProcessingLook.slowElegant:
      return _contrastMatrix(1.12, 1.03, 1.00, 0.93, -0.06);
  }
}

List<double> _contrastMatrix(
  double contrast,
  double r,
  double g,
  double b,
  double brightness,
) {
  final t = 0.5 * (1 - contrast);
  return <double>[
    contrast * r,
    0,
    0,
    0,
    t + brightness,
    0,
    contrast * g,
    0,
    0,
    t + brightness,
    0,
    0,
    contrast * b,
    0,
    t + brightness,
    0,
    0,
    0,
    1,
    0,
  ];
}

List<double> _lerpMatrix(List<double> a, List<double> b, double t) {
  return List<double>.generate(20, (i) => a[i] + (b[i] - a[i]) * t);
}
