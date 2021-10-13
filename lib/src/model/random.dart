import 'dart:math';

Random? _random;
Random get random {
  if (_random == null) {
    try {
      _random = Random.secure();
    } on UnsupportedError {
      _random = Random(DateTime.now().millisecondsSinceEpoch);
    }
  }
  return _random!;
}
