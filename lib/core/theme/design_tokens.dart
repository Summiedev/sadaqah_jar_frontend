import 'package:flutter/material.dart';

/// Shared layout tokens for Mizan surfaces and feature screens.
class MizanSpacing {
  MizanSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const EdgeInsets screen = EdgeInsets.fromLTRB(xl, md, xl, xxl);
  static const EdgeInsets card = EdgeInsets.all(lg);
  static const EdgeInsets compactCard = EdgeInsets.all(md);
}

class MizanRadii {
  MizanRadii._();

  static const double control = 14;
  static const double card = 16;
  static const double sheet = 24;
}
