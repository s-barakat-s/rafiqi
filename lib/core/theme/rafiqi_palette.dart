import 'package:flutter/material.dart';

enum RafiqiPalette {
  rafiqi,
  blush,
  amethyst,
  linen,
  ocean;

  static RafiqiPalette fromStorage(String? value) {
    if (value == 'safa') return RafiqiPalette.ocean;
    if (value == 'olive' || value == 'noor') return RafiqiPalette.rafiqi;
    return values.firstWhere(
      (palette) => palette.name == value,
      orElse: () => RafiqiPalette.rafiqi,
    );
  }

  String get arabicName => switch (this) {
    RafiqiPalette.rafiqi => 'maab',
    RafiqiPalette.blush => 'ورد',
    RafiqiPalette.amethyst => 'جمشت',
    RafiqiPalette.linen => 'كتان',
    RafiqiPalette.ocean => 'محيط',
  };

  List<Color> get canonicalSwatches => switch (this) {
    RafiqiPalette.rafiqi => const [
      Color(0xFF344E41),
      Color(0xFF3A5A40),
      Color(0xFF588157),
      Color(0xFFA3B18A),
      Color(0xFFDAD7CD),
    ],
    RafiqiPalette.blush => const [
      Color(0xFFFFE5EC),
      Color(0xFFFFC2D1),
      Color(0xFFFFB3C6),
      Color(0xFFFF8FAB),
      Color(0xFFFB6F92),
    ],
    RafiqiPalette.amethyst => const [
      Color(0xFF231942),
      Color(0xFF5E548E),
      Color(0xFF9F86C0),
      Color(0xFFBE95C4),
      Color(0xFFE0B1CB),
    ],
    RafiqiPalette.linen => const [
      Color(0xFFEDEDE9),
      Color(0xFFD6CCC2),
      Color(0xFFF5EBE0),
      Color(0xFFE3D5CA),
      Color(0xFFD5BDAF),
    ],
    RafiqiPalette.ocean => const [
      Color(0xFF03045E),
      Color(0xFF0077B6),
      Color(0xFF00B4D8),
      Color(0xFF90E0EF),
      Color(0xFFCAF0F8),
    ],
  };
}
