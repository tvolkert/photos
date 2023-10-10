import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/src/extensions/double.dart';
import 'package:photos/src/ui/common/animation.dart';

import 'montage.dart';

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
  double cardScale = 1;
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
    _getCardScale,
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
    _updateCardScale,
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
      } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
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
  (String, double) _getCardScale() => ('cardScale', cardScale);
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

  void _updateCardScale(UpDown upDown) {
    setState(() {
      cardScale += _getDoubleValue(upDown);
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
        baseY: 0.2,
        layer: MontageLayer.manual(-zDiffValue, 0.80),
        useShadow: useShadow,
      ),
      PhotoCard(
        initialColor: const Color(0xffcc0000),
        xPercentage: rX,
        baseY: 0.4,
        layer: const MontageLayer.manual(0, 0.95),
        useShadow: useShadow,
      ),
      PhotoCard(
        initialColor: const Color(0xff00cc00),
        xPercentage: gX,
        baseY: 0.7,
        layer: const MontageLayer.manual(0, 0.95),
        useShadow: useShadow,
      ),
      PhotoCard(
        initialColor: const Color(0xff0000cc),
        xPercentage: bX,
        baseY: 0.5,
        layer: MontageLayer.manual(zDiffValue, 1),
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
            Montage(
              isPerspective: isPerspective,
              fovYRadians: fovYRadians,
              zNear: zNearValue,
              zFar: zFarValue,
              cardScale: cardScale,
              rotation: rotationAnimation.value,
              distance: distanceValue,
              pullback: pullbackValue,
              extraPullback: extraPullbackAnimation.value,
              frame: frame,
              children: cards ??= buildCards(context),
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
