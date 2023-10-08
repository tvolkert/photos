import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/rendering.dart' hide debugPrint;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide debugPrint;
import 'package:photos/src/extensions/double.dart';
import 'package:photos/src/ui/common/animation.dart';
import 'package:photos/src/ui/common/debug.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  runApp(const MontageController());
}

enum UpDown {
  up,
  down,
}

typedef UpDownHandler = void Function(UpDown upDown);

typedef InfoProvider<T> = (String description, T value) Function();

typedef MontageCardReloadHandler = void Function(MontageCardConstraints constraints);

class MontageController extends StatefulWidget {
  const MontageController({super.key});

  @override
  State<MontageController> createState() => _MontageControllerState();
}

class _MontageControllerState extends State<MontageController> with SingleTickerProviderStateMixin {
  late AnimationController animation;
  late Animation<double> rotationAnimation;
  late Animation<double> extraPullbackAnimation;
  List<PhotoCard>? cards;

  // Integers are 64-bit, which means this can hold
  // ~4.8 million years worth of frames at 60fps
  int frame = 0;
  int? _scheduledFrameCallbackId;
  bool isPerspective = true;
  int fov = 4;
  int fovScale = 4;
  double zNear = 1;
  double zFar = 10;
  int zScale = 0;
  double distance = -19;
  int distanceScale = 2;
  int currentField = 3;
  double pullback = -51;
  double pullbackScale = 2;
  double extraPullback = -70;
  double extraPullbackScale = 2;
  double zDiff = 37;
  double zDiffScale = 2;
  double yX = 0.96;
  double rX = 0.02;
  double gX = 0.81;
  double bX = 0.40;
  bool useShadow = true;

  final List<Color> cardColors = <Color>[
    const Color(0xffcccc00),
    const Color(0xffcc0000),
    const Color(0xff00cc00),
    const Color(0xff0000cc),
  ];

  late final List<InfoProvider<dynamic>> _infoProviders = <InfoProvider<dynamic>>[
    _getIsPerspective,
    _getFovYRadians,
    _getFovScale,
    _getZNear,
    _getZFar,
    _getZScale,
    _getDistance,
    _getDistanceScale,
    _getPullback,
    _getPullbackScale,
    _getExtraPullback,
    _getExtraPullbackScale,
    _getZDiff,
    _getZDiffScale,
    _getAnimationValue,
    _getYX,
    _getRX,
    _getGX,
    _getBX,
    _getFrame,
    _getUseShadow,
  ];
  late final List<UpDownHandler> _upDownHandlers = <UpDownHandler>[
    _updateIsPerspective,
    _updateFovYRadians,
    _updateFovScale,
    _updateZNear,
    _updateZFar,
    _updateZScale,
    _updateDistance,
    _updateDistanceScale,
    _updatePullback,
    _updatePullbackScale,
    _updateExtraPullback,
    _updateExtraPullbackScale,
    _updateZDiff,
    _updateZDiffScale,
    _updateAnimationValue,
    _updateYX,
    _updateRX,
    _updateGX,
    _updateBX,
    _updateFrame,
    _updateUseShadow,
  ];

  void _scheduleFrame({bool rescheduling = false}) {
    _scheduledFrameCallbackId = SchedulerBinding.instance.scheduleFrameCallback(
      _onFrame,
      rescheduling: rescheduling,
    );
  }

  void _cancelFrame() {
    if (_scheduledFrameCallbackId != null) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(_scheduledFrameCallbackId!);
      _scheduledFrameCallbackId = null;
    }
  }

  void _onFrame(Duration timeStamp) async {
    setState(() => frame++);
    _scheduleFrame(rescheduling: true);
  }

  KeyEventResult _handleKeyEvent(FocusNode focusNode, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      UpDownHandler handler = _upDownHandlers[currentField];
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        handler(UpDown.up);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        handler(UpDown.down);
      } else if (event.logicalKey == LogicalKeyboardKey.digit1) {
        _setHandler(0);
      } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
        _setHandler(1);
      } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
        _setHandler(2);
      } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
        _setHandler(3);
      } else if (event.logicalKey == LogicalKeyboardKey.digit5) {
        _setHandler(4);
      } else if (event.logicalKey == LogicalKeyboardKey.digit6) {
        _setHandler(5);
      } else if (event.logicalKey == LogicalKeyboardKey.digit7) {
        _setHandler(6);
      } else if (event.logicalKey == LogicalKeyboardKey.digit8) {
        _setHandler(7);
      } else if (event.logicalKey == LogicalKeyboardKey.digit9) {
        _setHandler(8);
      } else if (event.logicalKey == LogicalKeyboardKey.keyA) {
        _setHandler(9);
      } else if (event.logicalKey == LogicalKeyboardKey.keyB) {
        _setHandler(10);
      } else if (event.logicalKey == LogicalKeyboardKey.keyC) {
        _setHandler(11);
      } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
        _setHandler(12);
      } else if (event.logicalKey == LogicalKeyboardKey.keyE) {
        _setHandler(13);
      } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
        _setHandler(14);
      } else if (event.logicalKey == LogicalKeyboardKey.keyG) {
        _setHandler(15);
      } else if (event.logicalKey == LogicalKeyboardKey.keyH) {
        _setHandler(16);
      } else if (event.logicalKey == LogicalKeyboardKey.keyI) {
        _setHandler(17);
      } else if (event.logicalKey == LogicalKeyboardKey.keyJ) {
        _setHandler(18);
      } else if (event.logicalKey == LogicalKeyboardKey.keyK) {
        _setHandler(19);
      } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
        _setHandler(20);
      }
    }
    return KeyEventResult.handled;
  }

  void _setHandler(int index) {
    setState(() {
      currentField = index;
    });
  }

  /// For every increment of [fov], we increment 11.25°
  double get fovYRadians => fov * math.pi / fovScaleMultiplier;

  double get zNearValue => zNear * zScaleMultiplier;
  double get zFarValue => zFar * zScaleMultiplier;
  double get fovScaleMultiplier => math.pow(10, fovScale).toDouble();
  double get zScaleMultiplier => math.pow(10, zScale).toDouble();
  double get distanceScaleMultiplier => math.pow(10, distanceScale).toDouble();
  double get distanceValue => distance * distanceScaleMultiplier;
  double get pullbackScaleMultiplier => math.pow(10, pullbackScale).toDouble();
  double get pullbackValue => pullback * pullbackScaleMultiplier;
  double get extraPullbackScaleMultiplier => math.pow(10, extraPullbackScale).toDouble();
  double get extraPullbackValue => extraPullback * extraPullbackScaleMultiplier;
  double get zDiffScaleMultiplier => math.pow(10, zDiffScale).toDouble();
  double get zDiffValue => zDiff * zDiffScaleMultiplier;

  (String, bool) _getIsPerspective() => ('isPerspective', isPerspective);
  (String, String) _getFovYRadians() => ('fovYRadians', '($fov / $fovScaleMultiplier)π');
  (String, double) _getFovScale() => ('fovScale', fovScaleMultiplier);
  (String, double) _getZNear() => ('zNear', zNearValue);
  (String, double) _getZFar() => ('zFar', zFarValue);
  (String, double) _getZScale() => ('zScale', zScaleMultiplier);
  (String, double) _getDistance() => ('distance', distanceValue.toPrecision(5));
  (String, double) _getDistanceScale() => ('distanceScale', distanceScaleMultiplier);
  (String, double) _getPullback() => ('pullback', pullbackValue.toPrecision(5));
  (String, double) _getPullbackScale() => ('pullbackScale', pullbackScaleMultiplier);
  (String, double) _getExtraPullback() => ('extraPullback', extraPullbackValue.toPrecision(5));
  (String, double) _getExtraPullbackScale() => ('extraPullbackScale', extraPullbackScaleMultiplier);
  (String, double) _getAnimationValue() => ('animationValue', animation.value);
  (String, double) _getZDiff() => ('zDiff', zDiffValue.toPrecision(5));
  (String, double) _getZDiffScale() => ('dZiffScale', zDiffScaleMultiplier);
  (String, double) _getYX() => ('yX', yX);
  (String, double) _getRX() => ('rX', rX);
  (String, double) _getGX() => ('gX', gX);
  (String, double) _getBX() => ('bX', bX);
  (String, int) _getFrame() => ('frame', frame);
  (String, bool) _getUseShadow() => ('useShadow', useShadow);

  int _getIntValue(UpDown upDown) {
    int value = 1;
    if (upDown == UpDown.down) {
      value *= -1;
    }
    return value;
  }

  double _getDoubleValue(UpDown upDown) => _getIntValue(upDown).toDouble();

  void _updateIsPerspective(UpDown upDown) {
    setState(() {
      isPerspective = !isPerspective;
    });
  }

  void _updateFovYRadians(UpDown upDown) {
    setState(() {
      fov += _getIntValue(upDown);
    });
  }

  void _updateFovScale(UpDown upDown) {
    setState(() {
      fovScale += _getIntValue(upDown);
    });
  }

  void _updateZNear(UpDown upDown) {
    setState(() {
      zNear += _getDoubleValue(upDown);
    });
  }

  void _updateZFar(UpDown upDown) {
    setState(() {
      zFar += _getDoubleValue(upDown);
    });
  }

  void _updateZScale(UpDown upDown) {
    setState(() {
      zScale += _getIntValue(upDown);
    });
  }

  void _updateDistance(UpDown upDown) {
    setState(() {
      distance += _getDoubleValue(upDown);
    });
  }

  void _updateDistanceScale(UpDown upDown) {
    setState(() {
      distanceScale += _getIntValue(upDown);
    });
  }

  void _updatePullback(UpDown upDown) {
    setState(() {
      pullback += _getDoubleValue(upDown);
    });
  }

  void _updatePullbackScale(UpDown upDown) {
    setState(() {
      pullbackScale += _getIntValue(upDown);
    });
  }

  void _updateExtraPullback(UpDown upDown) {
    setState(() {
      extraPullback += _getDoubleValue(upDown);
      _initExtraPullbackAnimation();
    });
  }

  void _updateExtraPullbackScale(UpDown upDown) {
    setState(() {
      extraPullbackScale += _getIntValue(upDown);
      _initExtraPullbackAnimation();
    });
  }

  void _updateZDiff(UpDown upDown) {
    setState(() {
      zDiff += _getDoubleValue(upDown);
      cards = null;
    });
  }

  void _updateZDiffScale(UpDown upDown) {
    setState(() {
      zDiffScale += _getIntValue(upDown);
      cards = null;
    });
  }

  void _updateAnimationValue(UpDown upDown) {
    setState(() {
      animation.value = ((animation.value + (_getDoubleValue(upDown) * 0.01)) % 1).toPrecision(3);
    });
  }

  void _updateYX(UpDown upDown) {
    setState(() {
      yX = (yX + (_getDoubleValue(upDown) * 0.01)).toPrecision(2);
      yX = math.max(yX, 0.0);
      yX = math.min(yX, 1.0);
      cards = null;
    });
  }

  void _updateRX(UpDown upDown) {
    setState(() {
      rX = (rX + (_getDoubleValue(upDown) * 0.01)).toPrecision(2);
      rX = math.max(rX, 0.0);
      rX = math.min(rX, 1.0);
      cards = null;
    });
  }

  void _updateGX(UpDown upDown) {
    setState(() {
      gX = (gX + (_getDoubleValue(upDown) * 0.01)).toPrecision(2);
      gX = math.max(gX, 0.0);
      gX = math.min(gX, 1.0);
      cards = null;
    });
  }

  void _updateBX(UpDown upDown) {
    setState(() {
      bX = (bX + (_getDoubleValue(upDown) * 0.01)).toPrecision(2);
      bX = math.max(bX, 0.0);
      bX = math.min(bX, 1.0);
      cards = null;
    });
  }

  void _updateFrame(UpDown upDown) {
    setState(() {
      frame += _getIntValue(upDown) * 10;
    });
  }

  void _updateUseShadow(UpDown upDown) {
    setState(() {
      useShadow = !useShadow;
      cards = null;
    });
  }

  void _initExtraPullbackAnimation() {
    extraPullbackAnimation = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0, end: extraPullbackValue).chain(CurveTween(curve: Curves.easeInOutSine)),
          weight: 48,
        ),
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(extraPullbackValue),
          weight: 4,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: extraPullbackValue, end: 0).chain(CurveTween(curve: Curves.easeInOutSine)),
          weight: 48,
        ),
      ],
    ).animate(animation);
  }

  List<PhotoCard> buildCards(BuildContext context) {
    return <PhotoCard>[
      PhotoCard(
        initialColor: const Color(0xffcccc00),
        xPercentage: yX,
        baseY: 1200,
        layer: MontageLayer._(-zDiffValue, 0.80),
        useShadow: useShadow,
      ),
      PhotoCard(
        initialColor: const Color(0xffcc0000),
        xPercentage: rX,
        baseY: 0,
        layer: const MontageLayer._(0, 0.95),
        useShadow: useShadow,
      ),
      PhotoCard(
        initialColor: const Color(0xff00cc00),
        xPercentage: gX,
        baseY: 1500,
        layer: const MontageLayer._(0, 0.95),
        useShadow: useShadow,
      ),
      PhotoCard(
        initialColor: const Color(0xff0000cc),
        xPercentage: bX,
        baseY: 1200,
        layer: MontageLayer._(zDiffValue, 1),
        useShadow: useShadow,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..addListener(() {
      setState(() {
        // Updated animation values will be reflected in `build()`
      });
    });
    rotationAnimation = ThetaTween().chain(CurveTween(curve: Curves.easeInOutCubic)).animate(animation);
    _initExtraPullbackAnimation();
    _scheduleFrame();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double slop = constraints.maxHeight * 0.5 * 0;
                return Montage(
                  isPerspective: isPerspective,
                  fovYRadians: fovYRadians,
                  zNear: zNearValue,
                  zFar: zFarValue,
                  rotation: rotationAnimation.value,
                  distance: distanceValue,
                  pullback: pullbackValue,
                  extraPullback: extraPullbackAnimation.value,
                  topSlop: slop,
                  bottomSlop: slop,
                  frame: frame,
                  children: cards ??= buildCards(context),
                );
              }
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: () {
                    List<Widget> children = <Widget>[];
                    for (int i = 0; i < _infoProviders.length; i++) {
                      var (description, value) = _infoProviders[i]();
                      children.add(DefaultTextStyle(
                        style: TextStyle(
                          color: const Color(0xffffffff),
                          fontWeight: i == currentField ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        child: Text('${(i + 1).toRadixString(36)}: $description: $value'),
                      ));
                    }
                    return children;
                  }(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoCard extends StatefulWidget {
  const PhotoCard({
    super.key,
    required this.initialColor,
    required this.xPercentage,
    required this.baseY,
    required this.layer,
    this.useShadow = true,
  });

  final Color initialColor;
  final double xPercentage;
  final double baseY;
  final MontageLayer layer;
  final bool useShadow;

  @override
  State<PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<PhotoCard> {
  int _updateCount = 0;
  late Color _color;

  static Color generateRandomColor() {
    final math.Random rand = math.Random();
    return Color.fromARGB(255, rand.nextInt(256), rand.nextInt(256), rand.nextInt(256));
  }

  void _handleReload(MontageCardConstraints constraints) {
    setState(() {
      _updateCount++;
      _color = generateRandomColor();
    });
  }

  Widget _buildChild(BuildContext context, MontageCardConstraints constraints) {
    Widget child = ColoredBox(
      color: _color,
      child: Text(
        '${constraints.extent.toPrecision(1)} -> ${constraints.transformedExtent.toPrecision(1)}',
        style: const TextStyle(fontSize: 120),
      ),
    );
    if (widget.useShadow) {
      child = DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: 50 * constraints.scale,
            ),
          ],
        ),
        child: child,
      );
    }
    return child;
  }

  @override
  void initState() {
    super.initState();
    _color = widget.initialColor;
  }

  @override
  void didUpdateWidget(covariant PhotoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.useShadow != oldWidget.useShadow) {
      _updateCount++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MontageCard(
      xPercentage: widget.xPercentage,
      baseY: widget.baseY,
      layer: widget.layer,
      updateCount: _updateCount,
      onReload: _handleReload,
      builder: _buildChild,
    );
  }
}

/// A preconfigured distance away from the viewer's perspective in which
/// [MontageCard] instances will exist.
class MontageLayer {
  const MontageLayer._(this.z, this.speed);

  /// The z-index at which cards in this layer will live.
  final double z;

  /// The speed at which cards in this layer will move.
  ///
  /// This number is a multiplier applied to the default speed at which all
  /// cards normally would move. So a value of `0.9` would cause cards in this
  /// layer to move at 90% of the standard speed.
  final double speed;

  static const double _diff = 3700;

  /// The layer that is closest to the viewer's perspective.
  static const MontageLayer front = MontageLayer._(_diff, 1);

  /// The layer that is in between the other two layers.
  static const MontageLayer middle = MontageLayer._(0, 0.95);

  /// The layer that is furthest away from the viewer's perspective.
  static const MontageLayer back = MontageLayer._(-_diff, 0.8);

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
    this.fovYRadians = math.pi / 4,
    this.zNear = 1,
    this.zFar = 10,
    this.rotation = 0,
    this.distance = 0,
    this.pullback = 0,
    this.extraPullback = 0,
    this.topSlop = 0,
    this.bottomSlop = 0,
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
  final double topSlop;
  final double bottomSlop;
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
      topSlop: topSlop,
      bottomSlop: bottomSlop,
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
        ..topSlop = topSlop
        ..bottomSlop = bottomSlop
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
    double topSlop = 0,
    double bottomSlop = 0,
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
       _topSlop = topSlop,
       _bottomSlop = bottomSlop,
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

  double _topSlop;
  double get topSlop => _topSlop;
  set topSlop(double value) {
    if (value != _topSlop) {
      _topSlop = value;
      markNeedsPaint();
    }
  }

  double _bottomSlop;
  double get bottomSlop => _bottomSlop;
  set bottomSlop(double value) {
    if (value != _bottomSlop) {
      _bottomSlop = value;
      markNeedsPaint();
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
    final double localSpaceTop = solveY(-constraints.transformedHeight - parent!.topSlop);
    final double localSpaceBottom = solveY(parent!.size.height + parent!.bottomSlop);
    final double localSpaceSpan = localSpaceBottom - localSpaceTop;
    final double y = localSpaceTop + localSpaceSpan - ((baseY + parent!.frame * montageLayer.speed) % localSpaceSpan);
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
