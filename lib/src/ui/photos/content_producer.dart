import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:photos/src/model/photo.dart';
import 'package:photos/src/model/photo_producer.dart';

/// Widget that exposes a [ContentProducerController] to descendant widgets
/// via [ContentProducer.of].
class ContentProducer extends StatefulWidget {
  const ContentProducer({
    super.key,
    required this.producer,
    required this.child,
  });

  /// The photo producer that will drive the behavior of
  /// [ContentProducerController.producePhoto].
  final PhotoProducer producer;

  /// The child widget.
  final Widget child;

  @override
  State<ContentProducer> createState() => _ContentProducerState();

  static ContentProducerController of(BuildContext context) {
    _ContentProducerScope scope = context.dependOnInheritedWidgetOfExactType<_ContentProducerScope>()!;
    return scope.state;
  }
}

/// Instances of this class can be obtained by calling [ContentProducer.of].
abstract class ContentProducerController {
  /// Produces a new photo, sized to fit within the specified constraints.
  ///
  /// The returned photo will maintain its original aspect ratio, while fitting
  /// within `sizeConstraints`.
  ///
  /// See also:
  ///
  ///  * [PhotoProducer], which does the actual work of producing the photo.
  Future<Photo> producePhoto({
    required Size sizeConstraints,
    required double scaleMultiplier,
    BuildContext? context,
  });
}

class _ContentProducerState extends State<ContentProducer> implements ContentProducerController {
  @override
  Widget build(BuildContext context) {
    return _ContentProducerScope(
      state: this,
      producer: widget.producer,
      child: widget.child,
    );
  }

  @override
  Future<Photo> producePhoto({
    required Size sizeConstraints,
    required double scaleMultiplier,
    BuildContext? context,
  }) {
    context ??= this.context;
    return widget.producer.produce(
      context: context,
      sizeConstraints: sizeConstraints,
      scaleMultiplier: scaleMultiplier,
    );
  }
}

class _ContentProducerScope extends InheritedWidget {
  const _ContentProducerScope({
    required this.state,
    required this.producer,
    required super.child,
  });

  final _ContentProducerState state;
  final PhotoProducer producer;

  @override
  bool updateShouldNotify(_ContentProducerScope old) {
    return producer != old.producer;
  }
}
