import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double xlarge = 20;
  static const double pill = 999;

  static final BorderRadius smallRadius = BorderRadius.circular(small);
  static final BorderRadius mediumRadius = BorderRadius.circular(medium);
  static final BorderRadius largeRadius = BorderRadius.circular(large);
  static final BorderRadius xlargeRadius = BorderRadius.circular(xlarge);
  static final BorderRadius pillRadius = BorderRadius.circular(pill);
}
