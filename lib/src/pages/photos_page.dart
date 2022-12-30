import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file/file.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../model/dream.dart';
import '../model/files.dart';
import '../model/photo.dart';
import '../model/photo_producer.dart';
import '../model/photos_library_api_model.dart';

const _debugExtraInfo = false;
const _rotationInterval = Duration(seconds: 60);

const double perspectiveAngleRadians = 0.4315;

class MontageLayer {
  const MontageLayer({
    required this.spread,
    required this.scale,
    required this.zIndex,
    required this.speed,
    required this.color,
  });

  final double spread;
  final double scale;
  final double zIndex;
  final double speed;
  final Color color;

  static const back = MontageLayer(
    spread: 1.3,
    scale: 0.7,
    zIndex: 500,
    speed: 0.4,
    color: Color(0x33ff0000),
  );
  static const middle = MontageLayer(
    spread: 0.75,
    scale: 1,
    zIndex: 0,
    speed: 0.5,
    color: Color(0x3300ff00),
  );
  static const front = MontageLayer(
    spread: 0.25,
    scale: 1,
    zIndex: -500,
    speed: 0.45,
    color: Color(0x330000ff),
  );
}

class ContentProducer extends StatefulWidget {
  const ContentProducer({
    super.key,
    required this.producer,
    required this.child,
    required this.interactive,
  });

  final PhotoProducer producer;
  final Widget child;
  final bool interactive;

  @override
  State<ContentProducer> createState() => ContentProducerState();

  static ContentProducerState of(BuildContext context) {
    _ContentProducerScope scope =
        context.dependOnInheritedWidgetOfExactType<_ContentProducerScope>()!;
    return scope.state;
  }
}

class ContentProducerState extends State<ContentProducer> {
  @override
  Widget build(BuildContext context) {
    return _ContentProducerScope(
      state: this,
      child: widget.child,
    );
  }

  /// Tells whether this content producer is running in interactive mode.
  ///
  /// When interactive mode is false, the app was started automatically (it is
  /// running as a screensaver), and it is expected that the user is able to
  /// stop the app with simple keypad interaction.
  bool get isInteractive => widget.interactive;

  Widget produce(Size sizeConstraints) {
    return FutureBuilder<Photo>(
      future: widget.producer.produce(sizeConstraints),
      builder: (BuildContext context, AsyncSnapshot<Photo> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          // Fallthrough
          case ConnectionState.waiting:
            // TODO: Return something with UI
            return Container();
          case ConnectionState.done:
            if (snapshot.hasError) {
              // TODO: Return something with UI
              return Container();
            } else {
              assert(snapshot.hasData);
              final Photo photo = snapshot.data!;
              return Image(image: photo.image);
            }
          case ConnectionState.active:
            // This state is unused in `FutureBuilder`.
            assert(false);
            break;
        }
        return Container();
      },
    );
  }
}

class _ContentProducerScope extends InheritedWidget {
  const _ContentProducerScope({
    required this.state,
    required Widget child,
  }) : super(child: child);

  final ContentProducerState state;

  @override
  bool updateShouldNotify(_ContentProducerScope old) {
    return state.widget.producer != old.state.widget.producer;
  }
}

class GooglePhotosMontageContainer extends StatelessWidget {
  const GooglePhotosMontageContainer({super.key, required this.interactive});

  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final PhotosLibraryApiModel model = ScopedModel.of<PhotosLibraryApiModel>(context);
    final PhotoProducer producer = PhotoProducer(model);
    return ContentProducer(
      producer: producer,
      interactive: interactive,
      child: const MontageContainer(),
    );
  }
}

class AssetPhotosMontageContainer extends StatelessWidget {
  const AssetPhotosMontageContainer({super.key, required this.interactive});

  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final PhotoProducer producer = PhotoProducer.asset();
    return ContentProducer(
      producer: producer,
      interactive: interactive,
      child: const MontageContainer(),
    );
  }
}

class MontageContainer extends StatelessWidget {
  const MontageContainer({super.key});

  static int _nextKeyIndex = 1;
  static CardKey _newKey() => CardKey(_nextKeyIndex++);

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      child: MontageController(
        builders: <MontageCardBuilder>[
          MontageCardBuilder(x: 0.00, y: 0.55, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 1.00, y: 0.55, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 1.00, y: 0.00, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.20, y: 0.05, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.60, y: 0.09, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.05, y: 0.15, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.80, y: 0.20, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.35, y: 0.25, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.64, y: 0.30, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.25, y: 0.35, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.85, y: 0.40, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.10, y: 0.45, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.85, y: 0.49, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.40, y: 0.50, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.60, y: 0.55, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.15, y: 0.60, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 1.00, y: 0.65, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.65, y: 0.66, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.20, y: 0.70, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.45, y: 0.75, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.75, y: 0.80, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.09, y: 0.85, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.88, y: 0.89, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.50, y: 0.90, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.25, y: 0.95, layer: MontageLayer.back, key: _newKey()),
          MontageCardBuilder(x: 0.04, y: 0.05, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.40, y: 0.10, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.96, y: 0.15, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.24, y: 0.20, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.80, y: 0.25, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.10, y: 0.30, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.70, y: 0.35, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 1.00, y: 0.40, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.10, y: 0.42, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.67, y: 0.48, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.22, y: 0.55, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.84, y: 0.60, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.15, y: 0.65, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.74, y: 0.70, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.10, y: 0.75, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.88, y: 0.80, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.35, y: 0.85, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.03, y: 0.92, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.85, y: 0.95, layer: MontageLayer.middle, key: _newKey()),
          MontageCardBuilder(x: 0.00, y: 0.25, layer: MontageLayer.front, key: _newKey()),
          MontageCardBuilder(x: 1.00, y: 0.35, layer: MontageLayer.front, key: _newKey()),
          MontageCardBuilder(x: 0.50, y: 0.45, layer: MontageLayer.front, key: _newKey()),
          MontageCardBuilder(x: 1.00, y: 0.55, layer: MontageLayer.front, key: _newKey()),
          MontageCardBuilder(x: 0.00, y: 0.65, layer: MontageLayer.front, key: _newKey()),
          MontageCardBuilder(x: 0.50, y: 0.80, layer: MontageLayer.front, key: _newKey()),
          MontageCardBuilder(x: 0.00, y: 1.00, layer: MontageLayer.front, key: _newKey()),
        ],
      ),
    );
  }
}

class CardKey extends ValueKey<int> {
  const CardKey(super.value);
}

class AppContainer extends StatefulWidget {
  const AppContainer({super.key, required this.child});

  final Widget child;

  @override
  State<AppContainer> createState() => AppContainerState();

  static AppContainerState of(BuildContext context) {
    _AppContainerScope scope = context.dependOnInheritedWidgetOfExactType<_AppContainerScope>()!;
    return scope.state;
  }
}

class AppContainerState extends State<AppContainer> {
  bool _forcePerformanceOverlay = false;

  void togglePerformanceOverlay() {
    setState(() {
      _forcePerformanceOverlay = !_forcePerformanceOverlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;
    if (!ContentProducer.of(context).isInteractive) {
      child = WakeUpOnKeyPress(
        child: child,
      );
    }
    bool showPerformanceOverlay = _forcePerformanceOverlay;
    assert(() {
      showPerformanceOverlay |= _debugExtraInfo;
      return true;
    }());
    return _AppContainerScope(
      state: this,
      child: MediaQuery.fromWindow(
        child: ClipRect(
          child: Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              child,
              if (showPerformanceOverlay)
                Positioned(top: 0, left: 0, right: 0, child: PerformanceOverlay.allEnabled()),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppContainerScope extends InheritedWidget {
  const _AppContainerScope({
    required this.state,
    required Widget child,
  }) : super(child: child);

  final AppContainerState state;

  @override
  bool updateShouldNotify(_AppContainerScope old) => false;
}

class WakeUpOnKeyPress extends StatefulWidget {
  const WakeUpOnKeyPress({super.key, required this.child});

  final Widget child;

  @override
  State<WakeUpOnKeyPress> createState() => _WakeUpOnKeyPressState();
}

class _WakeUpOnKeyPressState extends State<WakeUpOnKeyPress> {
  late FocusNode focusNode;

  void _handleKeyEvent(KeyEvent event) async {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.digit0) {
        AppContainer.of(context).togglePerformanceOverlay();
      } else if (event.logicalKey == LogicalKeyboardKey.digit9) {
        List<File> copies = await FilesBinding.instance.saveFilesToDownloads();
        debugPrint('Copied database files to ${copies.map<String>((File f) => f.path)}');
      } else {
        DreamBinding.instance.wakeUp();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
      focusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(() {
      if (ContentProducer.of(context).isInteractive) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('WakeUpOnKeyPress widget was used in interactive mode.'),
          ErrorDescription('The purpose of WakeUpOnKeyPress is to call '
              'wakeUp(), a method that only makes sense when in '
              'non-interactive (screensaver) mode.'),
        ]);
      }
      return true;
    }());
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}

class MontageController extends StatefulWidget {
  const MontageController({super.key, required this.builders});

  final List<MontageCardBuilder> builders;

  @override
  State<MontageController> createState() => _MontageControllerState();
}

class _MontageControllerState extends State<MontageController> {
  final Map<CardKey, Offset> _locations = <CardKey, Offset>{};
  final Map<CardKey, Widget> _content = <CardKey, Widget>{};
  late int _scheduledFrameCallbackId;
  int _currentFrame = 0;

  void _scheduleFrame({bool rescheduling = false}) {
    _scheduledFrameCallbackId = SchedulerBinding.instance.scheduleFrameCallback(
      _onFrame,
      rescheduling: rescheduling,
    );
  }

  void _onFrame(Duration timeStamp) async {
    setState(() => _currentFrame++);
    _scheduleFrame(rescheduling: true);
  }

  @override
  void initState() {
    super.initState();
    _scheduleFrame();
  }

  @override
  void dispose() {
    SchedulerBinding.instance.cancelFrameCallbackWithId(_scheduledFrameCallbackId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: buildWithConstraints);
  }

  Widget buildWithConstraints(BuildContext context, BoxConstraints constraints) {
    final List<MontageCard> children = <MontageCard>[];
    // TODO: some of the work being done here should be done in `onFrame()`
    for (MontageCardBuilder builder in widget.builders) {
      Offset location = builder.calculateLocation(_currentFrame, constraints.biggest);
      Offset? lastLocation = _locations[builder.key];
      Widget? content = _content[builder.key];
      assert(content == null || lastLocation != null);
      if (lastLocation == null || lastLocation.dy < location.dy) {
        _content[builder.key] = content = ContentProducer.of(context).produce(const Size(500, 500));
      }
      _locations[builder.key] = location;

      Widget child = content!;
      assert(() {
        if (_debugExtraInfo) {
          child = Stack(
            fit: StackFit.passthrough,
            textDirection: TextDirection.ltr,
            children: [
              child,
              ColoredBox(color: builder.layer.color),
              Text(
                builder.key.toString(),
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffcc0000),
                ),
              ),
            ],
          );
        }
        return true;
      }());

      MontageCard card = MontageCard(
        key: builder.key,
        x: location.dx,
        y: location.dy,
        z: builder.layer.zIndex,
        scale: builder.layer.scale,
        child: child,
      );
      children.add(card);
    }
    return MontageSpinner(
      key: widget.key,
      children: children,
    );
  }
}

class MontageCardBuilder {
  const MontageCardBuilder({
    required this.key,
    required this.x,
    required this.y,
    required this.layer,
  });

  final CardKey key;
  final double x;
  final double y;
  final MontageLayer layer;

  static const _canvasScreenRatio = 7;

  double _calculateDx(Size screenSize) {
    return screenSize.width * x * layer.spread;
  }

  double _calculateDy(Size screenSize, int currentFrame) {
    double canvasHeight = screenSize.height * _canvasScreenRatio;
    double yOffset = canvasHeight * y;
    double frameOffset = canvasHeight - ((currentFrame * layer.speed) % canvasHeight);
    double yPos = (frameOffset + yOffset) % canvasHeight;
    double viewportOffset = (canvasHeight - screenSize.height) / -2;
    return yPos + viewportOffset;
  }

  Offset calculateLocation(int currentFrame, Size screenSize) {
    return Offset(
      _calculateDx(screenSize),
      _calculateDy(screenSize, currentFrame),
    );
  }
}

class MontageSpinner extends StatefulWidget {
  const MontageSpinner({
    super.key,
    this.children = const <MontageCard>[],
  });

  final List<MontageCard> children;

  @override
  State<MontageSpinner> createState() => _MontageSpinnerState();
}

class _MontageSpinnerState extends State<MontageSpinner> with SingleTickerProviderStateMixin {
  late AnimationController animation;
  late Animation<double> rotation;
  late Animation<double> distance;
  late Timer timer;

  static const double _maxDistance = 800;

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
    rotation = ThetaTween().chain(CurveTween(curve: Curves.easeInOutCubic)).animate(animation);
    distance = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0, end: _maxDistance)
              .chain(CurveTween(curve: Curves.easeInOutSine)),
          weight: 48,
        ),
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(_maxDistance),
          weight: 4,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: _maxDistance, end: 0)
              .chain(CurveTween(curve: Curves.easeInOutSine)),
          weight: 48,
        ),
      ],
    ).animate(animation);

    timer = Timer.periodic(_rotationInterval, (Timer timer) {
      animation.forward(from: 0);
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
    animation.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Montage(
      rotation: rotation.value,
      distance: distance.value,
      children: widget.children,
    );
  }
}

class ThetaTween extends Tween<double> {
  ThetaTween() : super(begin: 0, end: _fullRotation);

  static const _fullRotation = -2 * math.pi;

  @override
  double lerp(double t) => ui.lerpDouble(0, _fullRotation, t)!;
}

class Montage extends MultiChildRenderObjectWidget {
  Montage({
    super.key,
    this.rotation = 0,
    this.distance = 0,
    List<MontageCard> super.children = const <MontageCard>[],
  });

  final double rotation;
  final double distance;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderMontage(
      rotation: rotation,
      distance: distance,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderMontage renderObject) {
    renderObject.rotation = rotation;
    renderObject.distance = distance;
  }
}

class MontageParentData extends ContainerBoxParentData<RenderBox> {}

class RenderMontage extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MontageParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MontageParentData> {
  RenderMontage({
    double rotation = 0,
    double distance = 0,
  })  : _rotation = rotation,
        _distance = distance;

  static final Matrix4 _perspectiveTransform = Matrix4(
    1.0, 0.0, 0.0, 0.0, // nodartfmt
    0.0, 1.0, 0.0, 0.0, // nodartfmt
    0.0, 0.0, 1.0, 0.001, // nodartfmt
    0.0, 0.0, 0.0, 1.0, // nodartfmt
  );

  double _rotation = 0;
  double get rotation => _rotation;
  set rotation(double value) {
    if (_rotation != value) {
      assert(rotation <= math.pi * 2 && rotation >= -math.pi * 2);
      _rotation = value;
      markNeedsPaint();
    }
  }

  double _distance = 0;
  double get distance => _distance;
  set distance(double value) {
    if (_distance != value) {
      _distance = value;
      markNeedsPaint();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MontageParentData) {
      child.parentData = MontageParentData();
    }
  }

  @override
  void performLayout() {
    assert(constraints.isTight);
    final double maxSize = math.max(constraints.maxWidth, constraints.maxHeight);
    final Constraints childConstraints = BoxConstraints.tight(Size.square(maxSize * 0.25));
    RenderBox? child = firstChild;
    while (child != null) {
      MontageParentData childParentData = child.parentData as MontageParentData;
      child.layout(childConstraints);
      child = childParentData.nextSibling;
    }
    size = constraints.biggest;
  }

  void paintBackwards(PaintingContext context, Offset offset) {
    RenderBox? child = lastChild;
    while (child != null) {
      final MontageParentData childParentData = child.parentData! as MontageParentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.previousSibling;
    }
  }

  void paintForwards(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    assert(() {
      if (_debugExtraInfo) {
        Paint paint = Paint()..color = const Color(0xffffffff);
        context.canvas.drawLine(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height),
          paint,
        );
      }
      return true;
    }());
    while (child != null) {
      final MontageParentData childParentData = child.parentData! as MontageParentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final double distanceDx = math.tan(perspectiveAngleRadians) * distance;
    final double centerDx = size.width / 2;
    assert(() {
      if (_debugExtraInfo) {
        Paint paint = Paint()..color = const Color(0xffcc0000);
        context.canvas.drawLine(
          Offset(centerDx, 0),
          Offset(centerDx, size.height),
          paint,
        );
      }
      return true;
    }());
    Matrix4 transform = _perspectiveTransform.clone()
      ..translate(centerDx + distanceDx, 0.0, distance)
      ..rotateY(rotation)
      ..translate(-centerDx);
    PaintingContextCallback painter = paintForwards;
    if (rotation.abs() >= math.pi / 2.85 && rotation.abs() < math.pi * 1.48) {
      painter = paintBackwards;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      transform,
      painter,
      oldLayer: layer as TransformLayer?,
    );
  }
}

class MontageCard extends SingleChildRenderObjectWidget {
  const MontageCard({
    super.key,
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.scale = 1,
    super.child,
  });

  final double x;
  final double y;
  final double z;
  final double scale;

  @override
  RenderMontageCard createRenderObject(BuildContext context) {
    return RenderMontageCard(
      x: x,
      y: y,
      z: z,
      scale: scale,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderMontageCard renderObject) {
    renderObject
      ..x = x
      ..y = y
      ..z = z
      ..scale = scale;
  }
}

class RenderMontageCard extends RenderProxyBox {
  RenderMontageCard({
    double x = 0,
    double y = 0,
    double z = 0,
    double scale = 0,
  })  : _x = x,
        _y = y,
        _z = z,
        _scale = scale;

  double _x = 0;
  double get x => _x;
  set x(double value) {
    if (value != _x) {
      _x = value;
      markNeedsPaint();
    }
  }

  double _y = 0;
  double get y => _y;
  set y(double value) {
    if (value != _y) {
      _y = value;
      markNeedsPaint();
    }
  }

  double _z = 0;
  double get z => _z;
  set z(double value) {
    if (value != _z) {
      _z = value;
      markNeedsPaint();
    }
  }

  double _scale = 1;
  double get scale => _scale;
  set scale(double value) {
    if (value != _scale) {
      _scale = value;
      markNeedsPaint();
    }
  }

  Matrix4 get transform {
    return Matrix4.identity()
      ..translate(x, y, z)
      ..scale(scale, scale, scale);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    layer = context.pushTransform(
      needsCompositing,
      offset,
      transform,
      super.paint,
      oldLayer: layer as TransformLayer?,
    );
  }
}
