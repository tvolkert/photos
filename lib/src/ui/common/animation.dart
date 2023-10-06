import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';

class ThetaTween extends Tween<double> {
  ThetaTween() : super(begin: 0, end: _fullRotation);

  static const _fullRotation = -2 * math.pi;

  @override
  double lerp(double t) => ui.lerpDouble(0, _fullRotation, t)!;
}
