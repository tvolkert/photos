import 'dart:math' as math;

extension DoubleExtensions on double {
  double toPrecision(int precision) {
    final int powerOfTen = math.pow(10, precision) as int;
    int truncated = (this * powerOfTen).round();
    return truncated / powerOfTen;
  }

  double get decimalPart => this - truncate();
}
