import 'dart:math' as math;

import 'package:flutter/foundation.dart' as foundation show debugPrint;
import 'package:flutter/rendering.dart' hide debugPrint;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide debugPrint;
import 'package:photos/src/extensions/double.dart';
import 'package:photos/src/ui/common/animation.dart';
import 'package:vector_math/vector_math_64.dart';

void debugPrint(String? message, { int? wrapWidth }) {
  //foundation.debugPrint(message, wrapWidth: wrapWidth);
}

void main() {
  runApp(const MontageController());
}

enum UpDown {
  up,
  down,
}

typedef UpDownHandler = void Function(UpDown upDown);

typedef InfoProvider<T> = (String description, T value) Function();

class MontageController extends StatefulWidget {
  const MontageController({super.key});

  @override
  State<MontageController> createState() => _MontageControllerState();
}

class _MontageControllerState extends State<MontageController> with SingleTickerProviderStateMixin {
  late AnimationController animation;
  late Animation<double> rotationAnimation;
  late Animation<double> extraPullbackAnimation;

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
    });
  }

  void _updateZDiffScale(UpDown upDown) {
    setState(() {
      zDiffScale += _getIntValue(upDown);
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
    });
  }

  void _updateRX(UpDown upDown) {
    setState(() {
      rX = (rX + (_getDoubleValue(upDown) * 0.01)).toPrecision(2);
      rX = math.max(rX, 0.0);
      rX = math.min(rX, 1.0);
    });
  }

  void _updateGX(UpDown upDown) {
    setState(() {
      gX = (gX + (_getDoubleValue(upDown) * 0.01)).toPrecision(2);
      gX = math.max(gX, 0.0);
      gX = math.min(gX, 1.0);
    });
  }

  void _updateBX(UpDown upDown) {
    setState(() {
      bX = (bX + (_getDoubleValue(upDown) * 0.01)).toPrecision(2);
      bX = math.max(bX, 0.0);
      bX = math.min(bX, 1.0);
    });
  }

  void _updateFrame(UpDown upDown) {
    setState(() {
      frame += _getIntValue(upDown) * 10;
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
                  children: <PhotoCard>[
                    PhotoCard(
                      initialColor: const Color(0xffcccc00),
                      xPercentage: yX,
                      baseY: 1200,
                      z: -zDiffValue,
                    ),
                    PhotoCard(
                      initialColor: const Color(0xffcc0000),
                      xPercentage: rX,
                      baseY: 0,
                      z: 0,
                    ),
                    PhotoCard(
                      initialColor: const Color(0xff00cc00),
                      xPercentage: gX,
                      baseY: 1500,
                      z: 0,
                    ),
                    PhotoCard(
                      initialColor: const Color(0xff0000cc),
                      xPercentage: bX,
                      baseY: 1200,
                      z: zDiffValue,
                    ),
                  ],
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
    required this.z,
  });

  final Color initialColor;
  final double xPercentage;
  final double baseY;
  final double z;

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

  @override
  void initState() {
    super.initState();
    _color = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return MontageCard(
      xPercentage: widget.xPercentage,
      baseY: widget.baseY,
      z: widget.z,
      updateCount: _updateCount,
      onReload: () {
        setState(() {
          _updateCount++;
          _color = generateRandomColor();
        });
      },
      builder: (BuildContext context, MontageCardConstraints constraints) {
        debugPrint('building blue! :: $constraints');
        return ColoredBox(
          color: _color,
          child: Text(
            '${constraints.extent.toPrecision(1)} -> ${constraints.transformedExtent.toPrecision(1)}',
            style: const TextStyle(fontSize: 120),
          ),
        );
      },
    );
  }
}

class Distance {
  const Distance._(this.z);

  final double z;

  static const Distance front = Distance._(-5);
  static const Distance middle = Distance._(-11);
  static const Distance back = Distance._(-17);
}

class MontageCardFoo {
  const MontageCardFoo({
    required this.relativeX,
    required this.baseAbsoluteY,
    required this.distance,
  });

  /// This value ranges from 0.0 to 1.0, where 0.0 represents the left edge of
  /// the card aligned to the left edge of the screen, and 1.0 represents the
  /// right edge of the card aligned to the right edge of the screen.
  final double relativeX;

  /// The value of y on frame 0.
  final double baseAbsoluteY;

  /// The distance from the viewer's perspective at which this card exists.
  final Distance distance;
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
    required this.frame,
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
  final List<PhotoCard> children;

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
    debugPrint('insertRenderObjectChild(${child.runtimeType}, $slot)');
    renderObject[slot.index] = child;
  }

  @override
  void moveRenderObjectChild(RenderMontageCard child, IndexSlot oldSlot, IndexSlot newSlot) {
    throw UnsupportedError('moveRenderObjectChild');
  }

  @override
  void removeRenderObjectChild(RenderMontageCard child, IndexSlot slot) {
    debugPrint('removeRenderObjectChild(${child.runtimeType}, $slot)');
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

enum VisitOrder {forward, backward }
typedef ConditionalRenderObjectVisitor = bool Function(RenderMontageCard child);

class MontageCardConstraints extends BoxConstraints {
  const MontageCardConstraints({
    required this.extent,
    required this.transformedExtent,
  }) : super.tightFor(width: extent, height: extent);

  final double extent;
  final double transformedExtent;

  double get transformedWidth => transformedExtent;
  double get transformedHeight => transformedExtent;

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

class RenderMontage extends RenderBox {
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
      markNeedsFullTransform();
      markNeedsLayout();
    }
  }

  double _pullback = 0;
  double get pullback => _pullback;
  set pullback(double value) {
    if (_pullback != value) {
      _pullback = value;
      markNeedsFullTransform();
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
    markNeedsFullTransform();
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
      debugPrint('transformed center point is $centerPoint');
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

  Matrix4 get fooTransform {
    Matrix4 result = Matrix4.zero();
    final Size center = size / 2;
    final Vector4 centerPoint = Vector4(center.width, center.height, 0, 1);
    cardScaleTransform.transform(centerPoint);
    final double xScaleFactor = center.width * centerPoint.w / centerPoint.x;
    final double yScaleFactor = center.height * centerPoint.w / centerPoint.y;
    debugPrint('transformed center point is $centerPoint');
    result
        ..setIdentity()
        ..translate(center.width, center.height)
        ..multiply(baseTransform)
        ..translate(0.0, 0.0, distance + pullback)
        ..translate(-center.width * xScaleFactor, -center.height * yScaleFactor)
        ;
    return result;
  }

  @override
  set size(Size value) {
    if (!hasSize || value != size) {
      markNeedsFullTransform();
    }
    super.size = value;
  }

  final Matrix4 _cardScaleTransform = Matrix4.zero();
  Matrix4 get cardScaleTransform {
    // TODO cache
    return _cardScaleTransform
        ..setIdentity()
        ..multiply(baseTransform)
        ..translate(0.0, 0.0, distance + pullback);
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
    switch (order) {
      case VisitOrder.forward:
        for (RenderMontageCard? child in _children) {
          if (child != null) {
            if (visitor(child)) {
              return true;
            }
          }
        }
        break;
      case VisitOrder.backward:
        for (int i = _children.length - 1; i >= 0; i--) {
          RenderMontageCard? child = _children[i];
          if (child != null) {
            if (visitor(child)) {
              return true;
            }
          }
        }
        break;
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

  // Do we need the whole Rect, or just the topLeft Offset?
  // Rect getChildBounds(RenderMontageCard child) {
  //   Vector4 childPoint = Vector4(child.x, child.y, child.z, 1);
  //   transform.transform(childPoint);
  //   final double left = childPoint.x;
  //   final double top = childPoint.y;
  //   childPoint.setValues(child.x + child.size.width, child.y + child.size.height, child.z, 1);
  //   transform.transform(childPoint);
  //   return Rect.fromLTRB(left, top, childPoint.x, childPoint.y);
  // }

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
  bool get isRepaintBoundary => false; // TODO true?

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void performLayout() {
    final double childWidth = size.width / 1;
    visitChildrenUntil((RenderMontageCard child) {
      final Vector4 point = Vector4(childWidth, childWidth, 0, 1);
      StringBuffer buf = StringBuffer('child constraints :: $point -> ');
      (cardScaleTransform..translate(0.0, 0.0, child.z)).transform(point);
      buf.write('$point');
      debugPrint(buf.toString());
      assert(point.x == point.y);
      child.layout(MontageCardConstraints(extent: childWidth, transformedExtent: point.x / point.w));
      return false;
    });
  }

  @override
  @protected
  set layer(ContainerLayer? newLayer) {
    debugPrint('setting new layer for $this :: $newLayer');
    super.layer = newLayer;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    Matrix4 transform = baseTransform;
    VisitOrder visitOrder = VisitOrder.forward;
    if (true || rotation % math.pi != 0 || distance != 0) {
      transform = fullTransform;
      if (rotation.abs() >= math.pi / 2.85 && rotation.abs() < math.pi * 1.48) {
        visitOrder = VisitOrder.backward;
      }
    }
        debugPrint('painting before transform... full transform is ${context.canvas.getTransform()}');
    layer = context.pushTransform(
      needsCompositing,
      offset,
      transform,
      (PaintingContext context, Offset offset) {
        debugPrint('painting after transform... full transform is ${context.canvas.getTransform()}');
        visitChildrenUntil((RenderMontageCard child) {
          final BoxParentData childParentData = child.parentData! as BoxParentData;
          debugPrint('painting child :: $child (${child.runtimeType}) at offset ${childParentData.offset + offset}');
          context.paintChild(child, childParentData.offset + offset);
          debugPrint('painted child :: $child (${child.runtimeType})');
          return false;
        }, visitOrder);
      },
      oldLayer: layer as TransformLayer?,
    );
    Paint paint = Paint()
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
}

class MontageCard extends ConstrainedLayoutBuilder<MontageCardConstraints> {
  const MontageCard({
    super.key,
    required this.xPercentage,
    required this.baseY,
    required this.z,
    required this.onReload,
    required this.updateCount,
    required super.builder,
  });

  final double xPercentage;
  final double baseY;
  final double z;
  final VoidCallback onReload;
  final int updateCount;

  @override
  RenderMontageCard createRenderObject(BuildContext context) {
    return RenderMontageCard(
      xPercentage: xPercentage,
      baseY: baseY,
      z: z,
      onReload: onReload,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderMontageCard renderObject) {
    renderObject
        ..xPercentage = xPercentage
        ..baseY = baseY
        ..z = z
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
    double z = 0,
    VoidCallback onReload = _defaultOnReload,
  }) : _xPercentage = xPercentage,
       _baseY = baseY,
       _z = z,
       _onReload = onReload;

  double _xPercentage;
  double get xPercentage => _xPercentage;
  set xPercentage(double value) {
    _xPercentage = value;
    markNeedsPaint();
  }

  double _baseY = 0;
  double get baseY => _baseY;
  set baseY(double value) {
    if (value != _baseY) {
      _baseY = value;
      markNeedsPaint();
    }
  }

  double _z = 0;
  double get z => _z;
  set z(double value) {
    if (value != _z) {
      _z = value;
      if (parent == null) {
        markNeedsLayout();
      } else {
        // RenderMontage uses the card's z-index to construct its constraints
        markParentNeedsLayout();
      }
    }
  }

  VoidCallback _onReload;
  VoidCallback get onReload => _onReload;
  set onReload(VoidCallback callback) {
    if (callback != _onReload) {
      _onReload = callback;
    }
  }

  static void _defaultOnReload() {}

  @override
  RenderMontage? get parent => super.parent as RenderMontage?;

  @override
  MontageCardConstraints get constraints => super.constraints as MontageCardConstraints;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    debugPrint('dry layout size of $this is ${constraints.biggest}');
    return constraints.biggest;
  }

  @override
  void performLayout() {
    debugPrint('before building, child is $child');
    rebuildIfNecessary();
    debugPrint('after building, child is $child');
    child?.layout(constraints);
    debugPrint('foo :: $size :: $constraints');
  }

  double solveX(double outputX) {
    final Matrix4 transform = parent!.fooTransform;
    final double outputW = transform.storage[11] * z + transform.storage[15];
    return (outputX * outputW - transform.storage[8] * z) / transform.storage[0];
  }

  double solveY(double outputY) {
    final Matrix4 transform = parent!.fooTransform;
    final double outputW = transform.storage[11] * z + transform.storage[15];
    return (outputY * outputW - transform.storage[9] * z) / transform.storage[5];
  }

  double _frameY = 0;
  void updateFrameYIfNecessary() {
    final double localSpaceTop = solveY(-constraints.transformedHeight - parent!.topSlop);
    final double localSpaceBottom = solveY(parent!.size.height + parent!.bottomSlop);
    final double localSpaceSpan = localSpaceBottom - localSpaceTop;
    double frameY = localSpaceTop + localSpaceSpan - ((baseY + parent!.frame) % localSpaceSpan);
    if (frameY != _frameY) {
      if ((_frameY - localSpaceTop).abs() <= _reloadTolerance && (frameY - localSpaceBottom).abs() <= _reloadTolerance) {
        SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
          onReload();
        });
      }
      _frameY = frameY;
    }
  }

  static const double _reloadTolerance = 50;

  @override
  void paint(PaintingContext context, Offset offset) {
    final double right = parent!.size.width - constraints.transformedWidth;
    final double outputX = xPercentage * right;
    double inputX = solveX(outputX);
    updateFrameYIfNecessary();
    layer = context.pushTransform(
      needsCompositing,
      offset,
      Matrix4.translation(Vector3(inputX, _frameY, z)),
      (PaintingContext context, Offset offset) {
        super.paint(context, offset);
      },
      oldLayer: layer as TransformLayer?,
    );
  }
}
