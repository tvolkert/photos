import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:vector_math/vector_math_64.dart';

extension Matrix4Extensions on Matrix4 {
  ui.Size transformSize(ui.Size size) {
    final Float64List storage = this.storage;
    final double width = (storage[0] * size.width) +
        (storage[4] * size.height) +
        storage[12];
    final double height = (storage[1] * size.width) +
        (storage[5] * size.height) +
        storage[13];
    return ui.Size(width, height);
  }

  Vector3 transform2(Vector3 arg) {
    final Float64List m4Storage = storage;
    final Float64List argStorage = arg.storage;
    final x_ = (m4Storage[0] * argStorage[0]) +
        (m4Storage[4] * argStorage[1]) +
        (m4Storage[8] * argStorage[2]) +
        m4Storage[12];
    final y_ = (m4Storage[1] * argStorage[0]) +
        (m4Storage[5] * argStorage[1]) +
        (m4Storage[9] * argStorage[2]) +
        m4Storage[13];
    argStorage[0] = x_;
    argStorage[1] = y_;
    return arg;
  }
}
