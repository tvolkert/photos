import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/src/ui/common/debug.dart';
import 'package:vector_math/vector_math_64.dart';

typedef MontageCardReloadHandler = void Function(MontageCardConstraints constraints);

/// A preconfigured distance away from the viewer's perspective in which
/// [MontageCard] instances will exist.
class MontageLayer {
  const MontageLayer.manual(this.z, this.speed) :
      slop = 0.3,
      debugColor = const Color(0xffcc0000);

  const MontageLayer._(this.z, this.speed, this.slop, this.debugColor) :
      assert(slop >= 0);

  /// The z-index at which cards in this layer will live.
  final double z;

  /// The speed at which cards in this layer will move.
  ///
  /// This number is a multiplier applied to the default speed at which all
  /// cards normally would move. So a value of `0.9` would cause cards in this
  /// layer to move at 90% of the standard speed.
  final double speed;

  /// The percentage of the screen height that cards will overflow on the top
  /// and the bottom before wrapping around and reloading.
  ///
  /// A value of zero would make cards wrap and reload as soon as they move off
  /// the top of the screen.
  ///
  /// This value must be greater than or equal to zero.
  final double slop;

  /// A color that allows the viewer to visually distinguish items in one layer
  /// from items in another.
  ///
  /// See also:
  ///
  ///  * [PhotosAppController.isShowDebugInfo], which, when true, will cause
  ///    various debug information to be shown, including items in this layer
  ///    to have a colored box with this color shown in front of them.
  final Color debugColor;

  static const double _diff = 3700;

  /// The layer that is closest to the viewer's perspective.
  static const MontageLayer front = MontageLayer._(_diff, 1, 2.2, Color(0x330000ff));

  /// The layer that is in between the other two layers.
  static const MontageLayer middle = MontageLayer._(0, 0.95, 0.65, Color(0x3300ff00));

  /// The layer that is furthest away from the viewer's perspective.
  static const MontageLayer back = MontageLayer._(-_diff, 0.8, 0.25, Color(0x33ff0000));

  @override
  bool operator==(Object other) {
    return other is MontageLayer
        && other.z == z
        && other.speed == speed;
  }

  @override
  int get hashCode => Object.hash(z, speed);
}

class Montage extends RenderObjectWidget {
  const Montage({
    super.key,
    this.isPerspective = false,
    this.fovYRadians = math.pi * 4 / 10000,
    this.zNear = 1,
    this.zFar = 10,
    this.rotation = 0,
    this.distance = -1900,
    this.pullback = -5100,
    this.extraPullback = -7000,
    this.frame = 0,
    required this.children,
  });

  final bool isPerspective;
  final double fovYRadians;
  final double zNear;
  final double zFar;
  final double rotation;
  final double distance;
  final double pullback;
  final double extraPullback;
  final int frame;

  /// Each widget in this list must either be an instance of [MontageCard] or a
  /// [StatelessWidget] or [StatefulWidget] that eventually produces a
  /// [MontageCard]. Put another way, each widget in this list must produce a
  /// render object that is of type [RenderMontageCard].
  final List<Widget> children;

  @override
  RenderObjectElement createElement() {
    return MontageElement(this);
  }

  @override
  RenderMontage createRenderObject(BuildContext context) {
    return RenderMontage(
      childCount: children.length,
      isPerspective: isPerspective,
      fovYRadians: fovYRadians,
      zNear: zNear,
      zFar: zFar,
      rotation: rotation,
      distance: distance,
      pullback: pullback,
      extraPullback: extraPullback,
      frame: frame,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderMontage renderObject) {
    renderObject
        ..isPerspective = isPerspective
        ..fovYRadians = fovYRadians
        ..zNear = zNear
        ..zFar = zFar
        ..rotation = rotation
        ..distance = distance
        ..pullback = pullback
        ..extraPullback = extraPullback
        ..frame = frame;
  }
}

class IndexSlot {
  IndexSlot(this.index);

  final int index;

  @override
  int get hashCode => index.hashCode;
  
  @override
  bool operator ==(Object other) => other is IndexSlot && other.index == index;

  @override
  String toString() => 'IndexSlot($index)';
}

class MontageElement extends RenderObjectElement {
  MontageElement(Montage widget) : super(widget);

  late List<Element> _children;

  @override
  Montage get widget => super.widget as Montage;

  @override
  RenderMontage get renderObject => super.renderObject as RenderMontage;

  @override
  void visitChildren(ElementVisitor visitor) {
    for (Element element in _children) {
      visitor(element);
    }
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _children = List<Element>.generate(widget.children.length, (int index) {
      return inflateWidget(widget.children[index], IndexSlot(index));
    });
  }

  @override
  void insertRenderObjectChild(RenderMontageCard child, IndexSlot slot) {
    renderObject[slot.index] = child;
  }

  @override
  void moveRenderObjectChild(RenderMontageCard child, IndexSlot oldSlot, IndexSlot newSlot) {
    throw UnsupportedError('moveRenderObjectChild');
  }

  @override
  void removeRenderObjectChild(RenderMontageCard child, IndexSlot slot) {
    assert(renderObject[slot.index] == child);
    renderObject[slot.index] = null;
  }

  @override
  void update(Montage newWidget) {
    assert(widget.children.length == newWidget.children.length);
    super.update(newWidget);
    for (int i = 0; i < widget.children.length; i++) {
      _children[i] = updateChild(_children[i], widget.children[i], IndexSlot(i))!;
    }
  }

  @override
  void forgetChild(Element child) {
    super.forgetChild(child);
    throw UnsupportedError('forgetChild');
  }
}

/// The order in which children can be visited in [RenderMontage.visitChildrenUntil].
enum VisitOrder {forward, backward }

/// Signature of the `visitor` in [RenderMontage.visitChildrenUntil].
///
/// A return value of `true` will cause the method to stop visiting the children,
/// whereas a return value of 'false' will cause the method to visit the next
/// child in the list.
typedef ConditionalRenderObjectVisitor = bool Function(RenderMontageCard child);

/// Constraints that are applied to [RenderMontageCard] instances.
///
/// Montage cards are always tightly constrained (see [BoxConstraints.tightFor])
/// and square in size (the width constraint will be equal to the height
/// constraint). This single width / height value is known as the [extent].
///
/// The [MontageLayer] in which each card lives causes each card to appear
/// closer to the viewer (larger) or further away from the viewer (smaller).
/// This means that when cards are drawn to the screen, the size that they
/// appear to be on screen may be different than the [extent] value. This size
/// that they appear to be is known as the [transformedExtent].
///
/// This means that each card has the constraints that it was given when
/// it was laid out, and then what those constraints look like from the
/// perspective of the viewer.
class MontageCardConstraints extends BoxConstraints {
  const MontageCardConstraints({
    required this.extent,
    required this.transformedExtent,
  }) : super.tightFor(width: extent, height: extent);

  /// The size that cards laid out with these constraints were given during
  /// layout. This is the same as [minWidth], [maxWidth], [minHeight], and
  /// [maxHeight].
  final double extent;

  /// The size that cards laid out with these constraints will _appear_ to be
  /// on screen.
  final double transformedExtent;

  /// The _apparent_ width on screen of cards laid out with these constraints.
  ///
  /// This property is an alias for [transformedExtent] and exists just for
  /// readability.
  double get transformedWidth => transformedExtent;

  /// The _apparent_ height on screen of cards laid out with these constraints.
  ///
  /// This property is an alias for [transformedExtent] and exists just for
  /// readability.
  double get transformedHeight => transformedExtent;

  /// The ratio of the [extent] to the [transformedExtent].
  double get scale => extent / transformedExtent;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MontageCardConstraints
        && super == other
        && other.extent == extent
        && other.transformedExtent == transformedExtent;
  }

  @override
  int get hashCode {
    assert(debugAssertIsValid());
    return Object.hash(super.hashCode, transformedExtent);
  }

  @override
  String toString() {
    return 'MontageCardConstraints($extent -> $transformedExtent)';
  }
}

/// The render object built by the [Montage] widget.
class RenderMontage extends RenderBox {
  /// Creates a new [RenderMontage] object.
  RenderMontage({
    int childCount = 0,
    bool isPerspective = false,
    double fovYRadians = math.pi / 4,
    double zNear = 0,
    double zFar = 0,
    double rotation = 0,
    double distance = 0,
    double pullback = 0,
    double extraPullback = 0,
    int frame = 0,
  }) : _children = List<RenderMontageCard?>.filled(childCount, null),
       _isPerspective = isPerspective,
       _fovYRadians = fovYRadians,
       _zNear = zNear,
       _zFar = zFar,
       _rotation = rotation,
       _distance = distance,
       _pullback = pullback,
       _extraPullback = extraPullback,
       _frame = frame;

  final List<RenderMontageCard?> _children;
  RenderMontageCard? operator [](int index) => _children[index];
  void operator []=(int index, RenderMontageCard? child) {
    assert(index >= 0 && index < _children.length);
    if (_children[index] != null) dropChild(_children[index]!);
    _children[index] = child;
    if (child != null) adoptChild(child);
  }

  bool _isPerspective;
  bool get isPerspective => _isPerspective;
  set isPerspective(bool value) {
    if (value != _isPerspective) {
      _isPerspective = value;
      markNeedsBaseTransform();
    }
  }

  double _fovYRadians;
  double get fovYRadians => _fovYRadians;
  set fovYRadians(double value) {
    if (value != _fovYRadians) {
      _fovYRadians = value;
      if (isPerspective) {
        markNeedsBaseTransform();
        markNeedsLayout();
      }
    }
  }

  double _zNear;
  double get zNear => _zNear;
  set zNear(double value) {
    if (value != _zNear) {
      _zNear = value;
      if (isPerspective) {
        markNeedsBaseTransform();
      }
    }
  }

  double _zFar;
  double get zFar => _zFar;
  set zFar(double value) {
    if (value != _zFar) {
      _zFar = value;
      if (isPerspective) {
        markNeedsBaseTransform();
      }
    }
  }

  double _rotation = 0;
  double get rotation => _rotation;
  set rotation(double value) {
    if (_rotation != value) {
      assert(rotation <= math.pi * 2 && rotation >= -math.pi * 2);
      _rotation = value;
      markNeedsFullTransform();
    }
  }

  double _distance = 0;
  double get distance => _distance;
  set distance(double value) {
    if (_distance != value) {
      _distance = value;
      markNeedsCardScaleTransform();
      markNeedsFullTransform();
      markNeedsFullTransformSansRotation();
      markNeedsLayout();
    }
  }

  double _pullback = 0;
  double get pullback => _pullback;
  set pullback(double value) {
    if (_pullback != value) {
      _pullback = value;
      markNeedsCardScaleTransform();
      markNeedsFullTransform();
      markNeedsFullTransformSansRotation();
      markNeedsLayout();
    }
  }

  double _extraPullback = 0;
  double get extraPullback => _extraPullback;
  set extraPullback(double value) {
    if (_extraPullback != value) {
      _extraPullback = value;
      markNeedsFullTransform();
    }
  }

  int _frame;
  int get frame => _frame;
  set frame(int value) {
    if (value != _frame) {
      _frame = value;
      markNeedsPaint();
    }
  }

  bool _needsBaseTransform = true;
  void markNeedsBaseTransform() {
    _needsBaseTransform = true;
    markNeedsCardScaleTransform();
    markNeedsFullTransform();
    markNeedsFullTransformSansRotation();
    markNeedsPaint();
  }

  final Matrix4 _baseTransform = Matrix4.zero();
  Matrix4 get baseTransform {
    if (_needsBaseTransform) {
      _needsBaseTransform = false;
      if (isPerspective) {
        setPerspectiveMatrix(_baseTransform, fovYRadians, 1.0, zNear, zFar);
      } else {
        _baseTransform.setIdentity();
      }
    }
    return _baseTransform;
  }

  bool _needsFullTransform = true;
  void markNeedsFullTransform() {
    _needsFullTransform = true;
    markNeedsPaint();
  }

  final Matrix4 _fullTransform = Matrix4.zero();
  Matrix4 get fullTransform {
    if (_needsFullTransform) {
      _needsFullTransform = false;
      final Size center = size / 2;
      final Vector4 centerPoint = Vector4(center.width, center.height, 0, 1);
      cardScaleTransform.transform(centerPoint);
      final double xScaleFactor = center.width * centerPoint.w / centerPoint.x;
      final double yScaleFactor = center.height * centerPoint.w / centerPoint.y;
      _fullTransform
          ..setIdentity()
          ..translate(center.width, center.height)
          ..multiply(baseTransform)
          ..translate(0.0, 0.0, distance + pullback + extraPullback)
          ..rotateY(rotation)
          ..translate(-center.width * xScaleFactor, -center.height * yScaleFactor)
          ;
    }
    return _fullTransform;
  }

  bool _needsFullTransformSansRotation = true;
  void markNeedsFullTransformSansRotation() {
    _needsFullTransformSansRotation = true;
    markNeedsPaint();
  }

  final Matrix4 _fullTransformSansRotation = Matrix4.zero();
  Matrix4 get fullTransformSansRotation {
    if (_needsFullTransformSansRotation) {
      _needsFullTransformSansRotation = false;
      final Size center = size / 2;
      final Vector4 centerPoint = Vector4(center.width, center.height, 0, 1);
      cardScaleTransform.transform(centerPoint);
      final double xScaleFactor = center.width * centerPoint.w / centerPoint.x;
      final double yScaleFactor = center.height * centerPoint.w / centerPoint.y;
      _fullTransformSansRotation
          ..setIdentity()
          ..translate(center.width, center.height)
          ..multiply(baseTransform)
          ..translate(0.0, 0.0, distance + pullback)
          ..translate(-center.width * xScaleFactor, -center.height * yScaleFactor)
          ;
    }
    return _fullTransformSansRotation;
  }

  @override
  set size(Size value) {
    if (!hasSize || value != size) {
      markNeedsFullTransform();
      markNeedsFullTransformSansRotation();
    }
    super.size = value;
  }

  bool _needsCardScaleTransform = true;
  void markNeedsCardScaleTransform() {
    _needsCardScaleTransform = true;
    markNeedsLayout();
  }

  final Matrix4 _cardScaleTransform = Matrix4.zero();
  Matrix4 get cardScaleTransform {
    if (_needsCardScaleTransform) {
      _needsCardScaleTransform = false;
      _cardScaleTransform
          ..setIdentity()
          ..multiply(baseTransform)
          ..translate(0.0, 0.0, distance + pullback)
          ;
    }
    return _cardScaleTransform;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (RenderMontageCard? child in _children) {
      child?.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    for (RenderMontageCard? child in _children) {
      child?.detach();
    }
  }

  bool visitChildrenUntil(ConditionalRenderObjectVisitor visitor, [VisitOrder order = VisitOrder.forward]) {
    Iterable<RenderMontageCard?> ordered;
    switch (order) {
      case VisitOrder.forward:
        ordered = _children;
        break;
      case VisitOrder.backward:
        ordered = _children.reversed;
        break;
    }
    for (RenderMontageCard? child in ordered) {
      if (child != null) {
        if (visitor(child)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    visitChildrenUntil((RenderMontageCard child) {
      visitor(child);
      return false;
    });
  }

  bool get isReversed => rotation.abs() >= math.pi / 2.85 && rotation.abs() < math.pi * 1.48;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return visitChildrenUntil((RenderMontageCard child) {
      return result.addWithPaintTransform(
        transform: fullTransform,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child.hitTest(result, position: transformed);
        },
      );
    }, isReversed ? VisitOrder.forward : VisitOrder.backward);
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  /// This method is an optimization of the following code made possible by
  /// knowing the overall structure of `cardScaleTransform`:
  ///
  /// ```dart
  ///   final Vector4 point = Vector4(extent, extent, 0, 1);
  ///   (cardScaleTransform.clone()..translate(0.0, 0.0, child.montageLayer.z)).transform(point);
  ///   final double transformedExtent = point.x / point.w;
  /// ```
  double _getTransformedExtent(RenderMontageCard child, double extent) {
    final Float64List matrix = cardScaleTransform.storage;
    final double z = child.montageLayer.z;
    final double tx = matrix[0] * extent;
    final double ty = matrix[5] * extent;
    final double tw = matrix[11] * z + matrix[15];
    assert(tx == ty);
    return tx / tw;
  }

  @override
  void performLayout() {
    final double childExtent = size.width / 1;
    visitChildrenUntil((RenderMontageCard child) {
      final double transformedExtent = _getTransformedExtent(child, childExtent);
      child.layout(MontageCardConstraints(extent: childExtent, transformedExtent: transformedExtent));
      return false;
    });
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    layer = context.pushTransform(
      needsCompositing,
      offset,
      fullTransform,
      (PaintingContext context, Offset offset) {
        visitChildrenUntil((RenderMontageCard child) {
          context.paintChild(child, offset);
          return false;
        }, isReversed ? VisitOrder.backward : VisitOrder.forward);
      },
      oldLayer: layer as TransformLayer?,
    );
    assert(() {
      if (forceShowDebugInfo) {
        final Paint paint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0
            ..color = const Color(0xffffffff)
            ;
        for (int i = 50; i < size.width; i += 50) {
          context.canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble(), size.height), paint);
        }
        for (int i = 50; i < size.height; i += 50) {
          context.canvas.drawLine(Offset(0, i.toDouble()), Offset(size.width, i.toDouble()), paint);
        }
      }
      return true;
    }());
  }
}

class MontageCard extends ConstrainedLayoutBuilder<MontageCardConstraints> {
  const MontageCard({
    super.key,
    required this.xPercentage,
    required this.baseY,
    required this.layer,
    required this.onReload,
    required this.updateCount,
    required super.builder,
  });

  final double xPercentage;
  final double baseY;
  final MontageLayer layer;
  final MontageCardReloadHandler onReload;
  final int updateCount;

  @override
  RenderMontageCard createRenderObject(BuildContext context) {
    return RenderMontageCard(
      xPercentage: xPercentage,
      baseY: baseY,
      layer: layer,
      onReload: onReload,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderMontageCard renderObject) {
    renderObject
        ..xPercentage = xPercentage
        ..baseY = baseY
        ..montageLayer = layer
        ..onReload = onReload;
  }

  @override
  @protected
  bool updateShouldRebuild(covariant MontageCard oldWidget) {
    return updateCount != oldWidget.updateCount;
  }
}

class RenderMontageCard extends RenderProxyBox with RenderConstrainedLayoutBuilder<MontageCardConstraints, RenderBox> {
  RenderMontageCard({
    double xPercentage = 0,
    double baseY = 0,
    MontageLayer layer = MontageLayer.middle,
    required MontageCardReloadHandler onReload,
  }) : _xPercentage = xPercentage,
       _baseY = baseY,
       _montageLayer = layer,
       _onReload = onReload;

  static const double _reloadTolerance = 50;

  double _xPercentage;
  double get xPercentage => _xPercentage;
  set xPercentage(double value) {
    _xPercentage = value;
    markNeedsX();
    markNeedsPaint();
  }

  bool _needsX = true;
  void markNeedsX() {
    _needsX = true;
  }

  double _x = 0;
  double get x {
    if (_needsX) {
      _needsX = false;
      final double right = parent!.size.width - constraints.transformedWidth;
      final double outputX = xPercentage * right;
      _x = solveX(outputX);
    }
    return _x;
  }

  double _baseY = 0;
  double get baseY => _baseY;
  set baseY(double value) {
    if (value != _baseY) {
      _baseY = value;
      markNeedsPaint();
    }
  }

  double _y = 0;
  double get y {
    final double parentHeight = parent!.size.height;
    final double localSpaceTop = solveY(-constraints.transformedHeight - montageLayer.slop * parentHeight);
    final double localSpaceBottom = solveY(parentHeight + montageLayer.slop * parentHeight);
    final double localSpaceSpan = localSpaceBottom - localSpaceTop;
    final double base = baseY * localSpaceSpan;
    final double y = localSpaceBottom - (base + parent!.frame * montageLayer.speed) % localSpaceSpan;
    if (y != _y) {
      if ((_y - localSpaceTop).abs() <= _reloadTolerance &&
          (y - localSpaceBottom).abs() <= _reloadTolerance) {
        SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
          // The reload handler is likely to want to trigger a rebuild, which
          // isn't allowed during layout, so we schedule it post-frame.
          onReload(constraints);
        });
      }
      _y = y;
    }
    return _y;
  }

  MontageLayer _montageLayer;
  MontageLayer get montageLayer => _montageLayer;
  set montageLayer(MontageLayer value) {
    if (value != _montageLayer) {
      _montageLayer = value;
      if (parent == null) {
        markNeedsLayout();
      } else {
        // RenderMontage uses the card's distance to construct its constraints
        markParentNeedsLayout();
      }
    }
  }

  MontageCardReloadHandler _onReload;
  MontageCardReloadHandler get onReload => _onReload;
  set onReload(MontageCardReloadHandler callback) {
    if (callback != _onReload) {
      _onReload = callback;
    }
  }

  @override
  RenderMontage? get parent => super.parent as RenderMontage?;

  @override
  MontageCardConstraints get constraints => super.constraints as MontageCardConstraints;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void performLayout() {
    markNeedsX();
    rebuildIfNecessary();
    child?.layout(constraints);
  }

  double solveX(double outputX) {
    final Matrix4 transform = parent!.fullTransformSansRotation;
    final double outputW = transform.storage[11] * montageLayer.z + transform.storage[15];
    return (outputX * outputW - transform.storage[8] * montageLayer.z) / transform.storage[0];
  }

  double solveY(double outputY) {
    final Matrix4 transform = parent!.fullTransformSansRotation;
    final double outputW = transform.storage[11] * montageLayer.z + transform.storage[15];
    return (outputY * outputW - transform.storage[9] * montageLayer.z) / transform.storage[5];
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    layer = context.pushTransform(
      needsCompositing,
      offset,
      Matrix4.translationValues(x, y, montageLayer.z),
      (PaintingContext context, Offset offset) {
        super.paint(context, offset);
      },
      oldLayer: layer as TransformLayer?,
    );
  }
}
