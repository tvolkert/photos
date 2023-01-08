import 'dart:async';

import 'package:flutter/widgets.dart';

import '../model/photo.dart';
import '../model/photo_producer.dart';

class ContentProducer extends StatefulWidget {
  const ContentProducer({
    super.key,
    required this.producer,
    required this.child,
  });

  final PhotoProducer producer;
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
  Future<Photo> producePhoto(Size sizeConstraints);
}

class _ContentProducerState extends State<ContentProducer> implements ContentProducerController {
  @override
  Widget build(BuildContext context) {
    return _ContentProducerScope(
      state: this,
      child: widget.child,
    );
  }

  @override
  Future<Photo> producePhoto(Size sizeConstraints) => widget.producer.produce(sizeConstraints);
}

class _ContentProducerScope extends InheritedWidget {
  const _ContentProducerScope({
    required this.state,
    required Widget child,
  }) : super(child: child);

  final _ContentProducerState state;

  @override
  bool updateShouldNotify(_ContentProducerScope old) {
    return state.widget.producer != old.state.widget.producer;
  }
}
