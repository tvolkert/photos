import 'dart:math' show Random;

import 'random.dart' as random_binding;

class RandomPickingStrategy {
  RandomPickingStrategy({required this.max, Random? random})
      : random = random ?? random_binding.random;

  final int max;
  final Random random;

  /// Returns the next random value from the strategy.
  Iterable<int> pickN(int n) {
    if (n >= max) {
      return List<int>.generate(max, (int index) => index);
    } else if (n < max ~/ 2) {
      final Set<int> result = <int>{};
      while (result.length < n) {
        result.add(random.nextInt(max));
      }
      return result;
    } else {
      final Set<int> exclude = <int>{};
      while (exclude.length < max - n) {
        exclude.add(random.nextInt(max));
      }
      final List<int> result = <int>[];
      for (int i = 0; i < max; i++) {
        if (!exclude.contains(i)) {
          result.add(i);
        }
      }
      assert(result.length == n);
      return result;
    }
  }
}
