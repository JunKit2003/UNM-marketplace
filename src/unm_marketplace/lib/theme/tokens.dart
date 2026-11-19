import 'package:flutter/material.dart';

/// Design tokens for the "Campus at night" look.
abstract final class AppTokens {
  static const ink = Color(0xFF0B1020);
  static const navy = Color(0xFF10263B);
  static const surface = Color(0xFF141B2E);
  static const surfaceHigh = Color(0xFF1B2440);
  static const violet = Color(0xFF7C5CFF);
  static const cyan = Color(0xFF22D3EE);
  static const pink = Color(0xFFF472B6);
  static const mint = Color(0xFF34D399);
  static const amber = Color(0xFFFBBF24);
  static const text = Color(0xFFE6E9F2);
  static const muted = Color(0xFF8A93A8);

  // Light mode counterparts.
  static const paper = Color(0xFFF6F7FB);
  static const paperHigh = Color(0xFFFFFFFF);
  static const inkText = Color(0xFF0E1326);
  static const inkMuted = Color(0xFF5B6478);

  static const accent = LinearGradient(colors: [violet, cyan], begin: Alignment.topLeft, end: Alignment.bottomRight);

  static const radius = 20.0;
  static const radiusSmall = 12.0;
  static const display = 'SpaceGrotesk';
  static const body = 'Inter';
}
