import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../model/photo.dart';
import '../model/photo_producer.dart';
import '../model/photos_library_api_model.dart';

import 'app.dart';
import 'content_producer.dart';
import 'debug.dart';

const _rotationInterval = Duration(seconds: 60);
const double _perspectiveAngleRadians = 0.4315;

class MontageLayer {
  const MontageLayer({
    required this.spread,
    required this.scale,
    required this.zIndex,
    required this.speed,
    required this.debugColor,
  });

  /// How far apart photos in this layer should be in the x-axis.
  ///
  /// This number is a multiplier that is applied to the default spacing
  /// between photos in the x-axis. A value of 1 means no change to the
  /// default spacing.
  ///
  /// This exists because as [zIndex] changes, the transformations that are
  /// applied will make the photos appear to naturally be either more spread
  /// out or more compact. The [spread] value compensates for that appearance.
  final double spread;

  /// The magnification that is applied to all photos in this layer.
  ///
  /// This number is a multiplier that is applied to the default scale of
  /// photos. This multiplier is applied in both the x and y axes. A value of 1
  /// means no change to the default scale.
  ///
  /// The transformations that are applied as a result of [zIndex] will
  /// naturally yield the appearance of scaling (as the photos in the front
  /// layer get bigger and the photos in the back layer get smaller). This value
  /// is applied on top of that effect.
  final double scale;

  /// The coordinate on the z-axis at which photos in this layer will exist.
  ///
  /// Positive numbers will cause items in this later to appear to fall back
  /// farther "into the screen" (away from the viewer), whereas negative numbers
  /// will cause items in this layer to appear to jump "out of the screen"
  /// (towards the viewer). A value of 0 will cause items in this layer to
  /// be drawn inline in the screen.
  final double zIndex;

  /// How quickly photos in this layer should move.
  ///
  /// This number is a multiplier on the default speed, so a value of 1 will
  /// cause items in this layer to move at the normal speed. A negative value
  /// will cause items in this layer to move down instead of up.
  final double speed;

  /// A color that allows the viewer to visually distinguish item in one layer
  /// from item in another.
  ///
  /// See also:
  ///
  ///  * [PhotosAppController.isShowDebugInfo], which, when true, will cause
  ///    various debug information to be shown, including items in this layer
  ///    to have a colored box with this color shown in front of them.
  final Color debugColor;

  /// The back layer of items.
  ///
  /// Items in this layer will be painted behind the other two layers and will
  /// naturally appear farther away from the viewer.
  static const back = MontageLayer(
    spread: 1.3,
    scale: 0.7,
    zIndex: 500,
    speed: 0.4,
    debugColor: Color(0x33ff0000),
  );

  /// The middle layer of items.
  ///
  /// Items in this layer will be painted in between the other two layers and
  /// will appear to exist in between the other two layers from a depth
  /// perspective.
  static const middle = MontageLayer(
    spread: 0.75,
    scale: 1,
    zIndex: 0,
    speed: 0.5,
    debugColor: Color(0x3300ff00),
  );

  /// The front layer of items.
  ///
  /// Items in this layer will be painted in front of the other two layers and
  /// will naturally appear closer to the viewer.
  static const front = MontageLayer(
    spread: 0.25,
    scale: 1,
    zIndex: -500,
    speed: 0.45,
    debugColor: Color(0x330000ff),
  );
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
      child: MontageContainer(
        interactive: interactive,
      ),
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
      child: MontageContainer(
        interactive: interactive,
      ),
    );
  }
}

class MontageContainer extends StatelessWidget {
  const MontageContainer({super.key, required this.interactive});

  final bool interactive;

  static int _nextKeyIndex = 1;
  static CardKey _newKey() => CardKey(_nextKeyIndex++);

  @override
  Widget build(BuildContext context) {
    return PhotosApp(
      interactive: interactive,
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

class MontageController extends StatefulWidget {
  const MontageController({super.key, required this.builders});

  final List<MontageCardBuilder> builders;

  @override
  State<MontageController> createState() => _MontageControllerState();
}

class _MontageControllerState extends State<MontageController> {
  final Map<CardKey, Offset> _locations = <CardKey, Offset>{};
  final Map<CardKey, Future<Photo>> _futures = <CardKey, Future<Photo>>{};
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
    imageCache.maximumSize = widget.builders.length;
  }

  @override
  void didUpdateWidget(covariant MontageController oldWidget) {
    super.didUpdateWidget(oldWidget);
    imageCache.maximumSize = widget.builders.length;
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
    final List<Widget> children = <Widget>[];
    // TODO: some of the work being done here should be done in `onFrame()`
    for (MontageCardBuilder builder in widget.builders) {
      Offset location = builder.calculateLocation(_currentFrame, constraints.biggest);
      Offset? lastLocation = _locations[builder.key];
      Future<Photo>? future = _futures[builder.key];
      assert(future == null || lastLocation != null);
      if (lastLocation == null || lastLocation.dy < location.dy) {
        // Load a new photo
        const Size bounds = Size(500, 500);
        _futures[builder.key] = future = ContentProducer.of(context).producePhoto(bounds);
      }
      _locations[builder.key] = location;

      children.add(PhotoContainer(
        builder: builder,
        location: location,
        future: future!,
        debugImageLabel: builder.key.value.toString(),
      ));
    }
    return MontageSpinner(
      key: widget.key,
      children: children,
    );
  }
}

class PhotoContainer extends StatefulWidget {
  const PhotoContainer({
    super.key,
    required this.builder,
    required this.location,
    required this.future,
    this.debugImageLabel,
  });

  final MontageCardBuilder builder;
  final Offset location;
  final Future<Photo> future;
  final String? debugImageLabel;

  @override
  State<PhotoContainer> createState() => _PhotoContainerState();
}

class _PhotoContainerState extends State<PhotoContainer> {
  /// An object that identifies the currently active callbacks. Used to avoid
  /// calling setState from stale callbacks, e.g. after disposal of this state,
  /// or after widget reconfiguration to a new Future.
  Object? _activeCallbackIdentity;
  ImageStream? _imageStream;
  Photo? _currentPhoto;
  ImageInfo? _imageInfo;

  late final ImageStreamListener _imageStreamListener;

  void _subscribeFuture() {
    final Object callbackIdentity = Object();
    _activeCallbackIdentity = callbackIdentity;
    widget.future.then<void>((Photo photo) {
      if (callbackIdentity == _activeCallbackIdentity) {
        _disposePhoto();
        _currentPhoto = photo;
        _unsubscribeFuture();
        _subscribeImageStream();
      }
    }, onError: _handleError);
  }

  void _unsubscribeFuture() {
    _activeCallbackIdentity = null;
  }

  void _subscribeImageStream() {
    assert(_currentPhoto != null);
    final ImageConfiguration config = createLocalImageConfiguration(context);
    _imageStream = _currentPhoto!.image.resolve(config);
    _imageStream!.addListener(_imageStreamListener);
  }

  void _unsubscribeImageStream() {
    if (_imageStream != null) {
      _imageStream!.removeListener(_imageStreamListener);
      _imageStream = null;
    }
  }

  void _handleImage(ImageInfo image, bool synchronousCall) {
    assert(() {
      debugPrint('~!@ : for photo ${widget.builder.key.value}, '
          'given constraints of ${_currentPhoto!.boundingConstraints}} '
          'applied to media item size ${_currentPhoto!.mediaItem?.size}, '
          'we got ${_currentPhoto!.size} '
          'with scale of ${_currentPhoto!.scale}');
      return true;
    }());
    // If we wanted to NOT show animated GIFs, we'd call `_unsubscribeImageStream()`
    // here. By keeping the subscription here, we'll be notified of multi-frame
    // images, thus animating them.
    setState(() {
      _disposeImageInfo();
      _imageInfo = image;
    });
  }

  void _handleError(Object error, StackTrace? stack) {
    debugPrint('Error while loading image: $error\n$stack');
  }

  void _disposeImageInfo() {
    if (_imageInfo != null) {
      _imageInfo!.dispose();
      _imageInfo = null;
    }
  }

  void _disposePhoto() {
    if (_currentPhoto != null) {
      _currentPhoto!.dispose();
      _currentPhoto = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _imageStreamListener = ImageStreamListener(_handleImage, onError: _handleError);
    _subscribeFuture();
  }

  @override
  void didUpdateWidget(covariant PhotoContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.future != oldWidget.future) {
      _unsubscribeImageStream();
      _unsubscribeFuture();
      _subscribeFuture();
    }
  }

  @override
  void dispose() {
    _unsubscribeImageStream();
    _unsubscribeFuture();
    _disposeImageInfo();
    _disposePhoto();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = <Widget>[];
    if (_imageInfo == null) {
      children.add(Container());
    } else {
      children.add(RawImage(
        image: _imageInfo!.image,
        scale: _imageInfo!.scale,
        debugImageLabel: widget.debugImageLabel,
      ));
    }
    // List<Widget> children = <Widget>[
    //   FutureBuilder<Photo>(
    //     future: widget.future,
    //     builder: (BuildContext context, AsyncSnapshot<Photo> snapshot) {
    //       switch (snapshot.connectionState) {
    //         case ConnectionState.none:
    //         // Fallthrough
    //         case ConnectionState.waiting:
    //           // TODO: Return something with UI
    //           return Container();
    //         case ConnectionState.done:
    //           if (snapshot.hasError) {
    //             // TODO: Return something with UI
    //             return Container();
    //           } else {
    //             assert(snapshot.hasData);
    //             return _PhotoDisplay(photo: snapshot.data!);
    //           }
    //         case ConnectionState.active:
    //           // This state is unused in `FutureBuilder`.
    //           assert(false);
    //           break;
    //       }
    //       return Container();
    //     },
    //   ),
    // ];
    if (PhotosApp.of(context).isShowDebugInfo) {
      children.addAll(<Widget>[
        ColoredBox(color: widget.builder.layer.debugColor),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Text(
            widget.builder.key.value.toString(),
            style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16),
          ),
        ),
        if (_imageInfo != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Size: ${_imageInfo!.image.width} x ${_imageInfo!.image.height}'),
                Text('Scale: ${_imageInfo!.scale}'),
                Text('File size (KB): ${_imageInfo!.sizeBytes ~/ 1024}'),
              ],
            ),
          ),
      ]);
    }

    return MontageCard(
      key: widget.builder.key,
      x: widget.location.dx,
      y: widget.location.dy,
      z: widget.builder.layer.zIndex,
      scale: widget.builder.layer.scale,
      child: Stack(
        fit: StackFit.passthrough,
        children: children,
      ),
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
    this.children = const <Widget>[],
  });

  final List<Widget> children;

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
          tween: Tween<double>(begin: 0, end: _maxDistance).chain(CurveTween(curve: Curves.easeInOutSine)),
          weight: 48,
        ),
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(_maxDistance),
          weight: 4,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: _maxDistance, end: 0).chain(CurveTween(curve: Curves.easeInOutSine)),
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
    super.children,
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
      if (forceShowDebugInfo) {
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
    final double distanceDx = math.tan(_perspectiveAngleRadians) * distance;
    final double centerDx = size.width / 2;
    assert(() {
      if (forceShowDebugInfo) {
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
