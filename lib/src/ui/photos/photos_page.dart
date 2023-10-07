import 'dart:async';
import 'dart:io' show HttpStatus;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart' hide Notification;
import 'package:vector_math/vector_math_64.dart';

import 'package:photos/src/extensions/double.dart';
import 'package:photos/src/model/photo.dart';
import 'package:photos/src/model/photo_producer.dart';
import 'package:photos/src/model/photos_api.dart';
import 'package:photos/src/ui/common/animation.dart';
import 'package:photos/src/ui/common/debug.dart';
import 'package:photos/src/ui/common/notifications.dart';
import 'package:photos/src/ui/photos/key_press_handler.dart';

import 'app.dart';
import 'content_producer.dart';
import 'intents.dart';

const _rotationInterval = Duration(seconds: 60);

class MontageLayer {
  const MontageLayer({
    required this.xSpread,
    required this.ySpread,
    required this.paintScale,
    required this.layoutScale,
    required this.zIndex,
    required this.travelTime,
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
  /// out or more compact. The [xSpread] value compensates for that appearance.
  final double xSpread;

  /// How far apart photos in this layer should be in the y-axis.
  ///
  /// This number is a multiplier that is applied to the default spacing
  /// between photos in the y-axis. A value of 1 means no change to the
  /// default spacing.
  ///
  /// This exists because as [zIndex] changes, the transformations that are
  /// applied will make the photos appear to naturally be either more spread
  /// out or more compact. The [ySpread] value compensates for that appearance.
  final double ySpread;

  /// The scale transformation that is applied to all photos in this layer when
  /// they're painted.
  ///
  /// This number is a multiplier that is applied to the default scale of
  /// photos (using [Matrix4.scale]). This multiplier is applied in the x, y,
  /// and z axes. A value of 1 means no change to the default scale.
  ///
  /// The transformations that are applied as a result of [zIndex] will
  /// naturally yield the appearance of scaling (as the photos in the front
  /// layer get bigger and the photos in the back layer get smaller). This value
  /// is applied on top of that effect.
  final double paintScale;

  /// The scale that will be applied to photos in this layer when they're being
  /// loaded and laid out.
  ///
  /// The constrained size of photos will be determined as follows during
  /// loading and layout:
  ///
  /// 1. The maximum width constraint will be taken during layout of the photo
  ///    montage, and it will be used to form a square size. This is done
  ///    because the montage is designed to be viewed in landscape orientation,
  ///    so the width is the dominant dimension.
  /// 2. The square size will be multiplied by this `layoutScale` value to
  ///    form the constrained size into which the photo will be loaded.
  /// 3. Unless the photo is perfectly square, its loaded dimensions will be
  ///    smaller in one dimension than its constraints. See
  ///    [ResizeImagePolicy.fit] for a discussion of how this works.
  /// 4. The image will then be laid out using the same calculation of
  ///    constrained size. If the photo montage constraints are the same as when
  ///    the photo was loaded, this will mean the photo will be laid out at its
  ///    loaded size.
  ///
  /// From the above process, it follows that this value should always be less
  /// than 1.0, otherwise the photo will occupy the entire screen.
  final double layoutScale;

  /// The coordinate on the z-axis at which photos in this layer will exist.
  ///
  /// Positive numbers will cause items in this later to appear to fall back
  /// farther "into the screen" (away from the viewer), whereas negative numbers
  /// will cause items in this layer to appear to jump "out of the screen"
  /// (towards the viewer). A value of 0 will cause items in this layer to
  /// be drawn inline in the screen.
  final double zIndex;

  /// The number of frames that it will take for a photo in this layer to travel
  /// from the bottom of the screen to the top.
  ///
  /// To fully travel from the bottom to the top of the screen, a photo must
  /// move from being completely off the bottom (the top of the photo is flush
  /// with the bottom of the screen) to be completely off the top (the bottom
  /// of the photo is flush with the top of the screen).
  ///
  /// At an assumed 60fps, a value of 60 implies that it will take 1 second for
  /// a photo to travel up the screen.
  final int travelTime;

  /// How quickly photos in this layer should move.
  ///
  /// This number is a multiplier on the default speed, so a value of 1 will
  /// cause items in this layer to move at the normal speed. A negative value
  /// will cause items in this layer to move down instead of up.
  final double speed;

  /// A color that allows the viewer to visually distinguish items in one layer
  /// from items in another.
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
    xSpread: 1.4,
    ySpread: 1,
    paintScale: 0.8,
    layoutScale: 0.2,
    zIndex: 500,
    travelTime: 600,
    speed: 0.4,
    debugColor: Color(0x33ff0000),
  );

  /// The middle layer of items.
  ///
  /// Items in this layer will be painted in between the other two layers and
  /// will appear to exist in between the other two layers from a depth
  /// perspective.
  static const middle = MontageLayer(
    xSpread: 0.85,
    ySpread: 1,
    paintScale: 1,
    layoutScale: 0.33,
    zIndex: 0,
    travelTime: 600,
    speed: 0.33,
    debugColor: Color(0x3300ff00),
  );

  /// The front layer of items.
  ///
  /// Items in this layer will be painted in front of the other two layers and
  /// will naturally appear closer to the viewer.
  static const front = MontageLayer(
    xSpread: 0.25,
    ySpread: 1.5,
    paintScale: 1,
    layoutScale: 0.5,
    zIndex: -500,
    travelTime: 600,
    speed: 0.75,
    debugColor: Color(0x330000ff),
  );
}

/// A widget that will load a [MontageContainer] with a specified [PhotoProducer]
/// along with an optional [Notification] to show in the app's bottom bar.
///
/// If you don't want to show any notification in the app's botton bar, consider
/// using [GooglePhotosMontageContainer] or [AssetPhotosMontageContainer]
/// instead.
///
/// See also:
///
///  * [PhotosApp.setBottomBarNotification], the API method that sets the
///    notification that appears in the app's bottom bar.
class MontageScaffold extends StatefulWidget {
  const MontageScaffold({
    super.key,
    this.producer = const AssetPhotoProducer(),
    this.bottomBarNotification,
  });

  /// The object that produces photos to show.
  ///
  /// Defaults to an instance of [AssetPhotoProducer].
  final PhotoProducer producer;

  /// The optional notification to show in the app's bottom bar.
  ///
  /// If this is unspecified, this widget behaves exactly like [MontageContainer].
  final Notification? bottomBarNotification;

  @override
  State<MontageScaffold> createState() => _MontageScaffoldState();
}

class _MontageScaffoldState extends State<MontageScaffold> {
  @override
  void initState() {
    super.initState();
    if (widget.bottomBarNotification != null) {
      // This needs to be done in the next frame because setting the bottom bar
      // notification forces a PhotosApp rebuild, which isn't allowed to happen
      // during an existing build phase (which we're currently in).
      SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
        final PhotosAppController app = PhotosApp.of(context);
        app.setBottomBarNotification(widget.bottomBarNotification);
      });
    }
  }

  @override
  void dispose() {
    PhotosApp.of(context).setBottomBarNotification(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MontageContainer(producer: widget.producer);
  }
}

/// A widget that builds a [MontageContainer] with photos produces using an
/// instance of [GooglePhotosPhotoProducer].
class GooglePhotosMontageContainer extends StatelessWidget {
  const GooglePhotosMontageContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return MontageContainer(producer: GooglePhotosPhotoProducer());
  }
}

/// A widget that builds a [MontageContainer] with photos produces using an
/// instance of [AssetPhotoProducer].
class AssetPhotosMontageContainer extends StatelessWidget {
  const AssetPhotosMontageContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return const MontageContainer(producer: AssetPhotoProducer());
  }
}

/// The top-level widget that hosts a photos montage.
class MontageContainer extends StatelessWidget {
  const MontageContainer({
    super.key,
    required this.producer,
  });

  final PhotoProducer producer;

  static final List<MontageCardBuilder> _cards = _generateCards();

  static List<MontageCardBuilder> _generateCards() {
    int nextKeyIndex = 1;
    CardKey newKey() => CardKey(nextKeyIndex++);
    return <MontageCardBuilder>[
      MontageCardBuilder(x: 0.30, y: 0.5, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.00, y: 0.53, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 1.00, y: 0.55, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 1.00, y: 0.00, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.20, y: 0.05, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.60, y: 0.09, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.05, y: 0.15, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.80, y: 0.20, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.35, y: 0.25, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.64, y: 0.30, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.25, y: 0.35, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.85, y: 0.40, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.10, y: 0.45, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.85, y: 0.49, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.40, y: 0.50, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.60, y: 0.56, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.15, y: 0.60, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 1.00, y: 0.65, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.65, y: 0.66, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.20, y: 0.70, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.45, y: 0.75, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.75, y: 0.80, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.09, y: 0.85, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.88, y: 0.89, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.50, y: 0.90, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.25, y: 0.95, layer: MontageLayer.back, key: newKey()),
      MontageCardBuilder(x: 0.04, y: 0.05, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.40, y: 0.10, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.96, y: 0.15, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.24, y: 0.20, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.80, y: 0.25, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.10, y: 0.30, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.70, y: 0.35, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 1.00, y: 0.40, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.10, y: 0.42, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.67, y: 0.48, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.22, y: 0.55, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.84, y: 0.60, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.15, y: 0.65, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.74, y: 0.70, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.10, y: 0.75, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.88, y: 0.80, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.35, y: 0.85, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.03, y: 0.92, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.85, y: 0.95, layer: MontageLayer.middle, key: newKey()),
      MontageCardBuilder(x: 0.00, y: 0.25, layer: MontageLayer.front, key: newKey()),
      MontageCardBuilder(x: 1.00, y: 0.35, layer: MontageLayer.front, key: newKey()),
      MontageCardBuilder(x: 0.50, y: 0.45, layer: MontageLayer.front, key: newKey()),
      MontageCardBuilder(x: 1.00, y: 0.55, layer: MontageLayer.front, key: newKey()),
      MontageCardBuilder(x: 0.00, y: 0.65, layer: MontageLayer.front, key: newKey()),
      MontageCardBuilder(x: 0.50, y: 0.80, layer: MontageLayer.front, key: newKey()),
      MontageCardBuilder(x: 0.00, y: 1.00, layer: MontageLayer.front, key: newKey()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ContentProducer(
      producer: producer,
      child: MontageController(
        builders: _cards,
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
  // The offset dx and dy values here range from 0.0..1.0
  final Map<CardKey, Offset> _locations = <CardKey, Offset>{};
  final Map<CardKey, Future<Photo>> _futures = <CardKey, Future<Photo>>{};
  int? _scheduledFrameCallbackId;
  int _currentFrame = 0;
  double _zoom = -2;

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
    setState(() => _currentFrame++);
    _scheduleFrame(rescheduling: true);
  }

  void _handleRewind(Intent intent) {
    setState(() => _currentFrame--);
  }

  void _handleFastForward(Intent intent) {
    setState(() => _currentFrame++);
  }

  void _handleZoom(Intent intent) {
    setState(() => _zoom += 1);
  }

  void _handleShrink(Intent intent) {
    setState(() => _zoom -= 1);
  }

  void _updateImageCacheSize() {
    imageCache.maximumSize = widget.builders.length;
  }

  @override
  void initState() {
    super.initState();
    _scheduleFrame();
    _updateImageCacheSize();
  }

  @override
  void didUpdateWidget(covariant MontageController oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateImageCacheSize();
  }

  @override
  void dispose() {
    _cancelFrame();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        RewindIntent: CallbackAction(onInvoke: _handleRewind),
        FastForwardIntent: CallbackAction(onInvoke: _handleFastForward),
        ZoomIntent: CallbackAction(onInvoke: _handleZoom),
        ShrinkIntent: CallbackAction(onInvoke: _handleShrink),
      },
      child: KeyPressHandler(
        child: buildCards(context),
        // child: LayoutBuilder(builder: buildWithConstraints),
      ),
    );
  }

  Widget buildCards(BuildContext context) {
    final List<MontageCardLoader> children = <MontageCardLoader>[];
    for (MontageCardBuilder builder in widget.builders) {
      Offset location = builder.calculateLocation2(_currentFrame);
      Offset? lastLocation = _locations[builder.key];
      Future<Photo>? future = _futures[builder.key];
      assert(future == null || lastLocation != null);
      if (lastLocation == null || location.dy < lastLocation.dy) {
        // Load a new photo
        final Size screenSize = MediaQuery.of(context).size;
        final Size squareScreenSize = Size.square(screenSize.width,);
        _futures[builder.key] = future = ContentProducer.of(context).producePhoto(
          // TODO: instead of using layooutScale, get the inverse transform and
          //       apply it to a standard photo size, like half the screen width
          sizeConstraints: squareScreenSize * builder.layer.layoutScale,
          scaleMultiplier: builder.layer.layoutScale,
        );
      }
      _locations[builder.key] = location;

      children.add(MontageCardLoader(
        builder: builder,
        location: location,
        zoom: _zoom,
        future: future!,
        debugImageLabel: builder.key.value.toString(),
      ));
    }
    return MontageSpinner(
      key: widget.key,
      children: children,
    );
  }

  Widget buildWithConstraints(BuildContext context, BoxConstraints constraints) {
    final List<MontageCardLoader> children = <MontageCardLoader>[];
    // TODO: some of the work being done here should be done in `onFrame()`
    for (MontageCardBuilder builder in widget.builders) {
      Offset location = builder.calculateLocation(_currentFrame, constraints.biggest);
      Offset? lastLocation = _locations[builder.key];
      Future<Photo>? future = _futures[builder.key];
      assert(future == null || lastLocation != null);
      if (lastLocation == null || location.dy > lastLocation.dy) {
        // Load a new photo
        final Size screenSize = MediaQuery.of(context).size;
        final Size squareScreenSize = Size.square(math.max(screenSize.width, screenSize.height));
        _futures[builder.key] = future = ContentProducer.of(context).producePhoto(
          sizeConstraints: squareScreenSize * builder.layer.layoutScale,
          scaleMultiplier: builder.layer.layoutScale,
        );
      }
      _locations[builder.key] = location;

      children.add(MontageCardLoader(
        builder: builder,
        location: location,
        zoom: _zoom,
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

/// A widget that creates a [MontageCard] given a `Future<Photo>`.
///
/// Until the future completes, the card will house an empty container. Once
/// the future completes, it will house the photo.
class MontageCardLoader extends StatefulWidget {
  const MontageCardLoader({
    super.key,
    required this.builder,
    required this.location,
    required this.zoom,
    required this.future,
    this.debugImageLabel,
  });

  final MontageCardBuilder builder;
  final Offset location;
  final double zoom;
  final Future<Photo> future;
  final String? debugImageLabel;

  @override
  State<MontageCardLoader> createState() => _MontageCardLoaderState();
}

class _MontageCardLoaderState extends State<MontageCardLoader> {
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
    }, onError: _handleErrorFromWidgetFuture);
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
    // debugPrint('received image info :: ${image.image.width}x${image.image.height}');
    assert(() {
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

  void _handleErrorFromWidgetFuture(Object error, StackTrace? stack) {
    _handleError('loading image', error, stack);
  }

  void _handleErrorFromImageStream(Object error, StackTrace? stack) {
    _handleError('loading image info', error, stack);
  }

  void _handleError(String description, Object error, StackTrace? stack) async {
    debugPrint('Error while $description: $error\n$stack');
    PhotosApp.of(context).addError(error, stack);
    if (error is NetworkImageLoadException && error.statusCode == HttpStatus.forbidden) {
      debugPrint('Renewing auth token');
      await PhotosApiBinding.instance.handleAuthTokenExpired();
    }
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
    _imageStreamListener = ImageStreamListener(_handleImage, onError: _handleErrorFromImageStream);
    _subscribeFuture();
  }

  @override
  void didUpdateWidget(covariant MontageCardLoader oldWidget) {
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
    Widget child;
    int? imageWidth;
    int? imageHeight;
    if (_imageInfo == null) {
      child = Container();
    } else {
      // debugPrint('building raw image at ${_imageInfo!.image.width}x${_imageInfo!.image.height} scaled ${_imageInfo!.scale}x');
      child = RawImage(
        image: _imageInfo!.image,
        scale: _imageInfo!.scale,
        debugImageLabel: widget.debugImageLabel,
      );
      imageWidth = _imageInfo!.image.width;
      imageHeight = _imageInfo!.image.height;
    }
    if (PhotosApp.of(context).isShowDebugInfo) {
      List<Widget> children = <Widget>[child];
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
                const Text('---'),
                Text('Location: ${widget.location.dx.toPrecision(1)},${widget.location.dy.toPrecision(1)}'),
                Text('Zoom: ${widget.zoom.toPrecision(2)}'),
              ],
            ),
          ),
      ]);
      child = Stack(
        fit: StackFit.passthrough,
        children: children,
      );
    }

    return MontageCard(
      key: widget.builder.key,
      x: widget.location.dx,
      y: widget.location.dy,
      z: widget.builder.layer.zIndex,
      zoom: widget.zoom,
      paintScale: widget.builder.layer.paintScale,
      layoutScale: widget.builder.layer.layoutScale,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      child: child,
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

  /// The key associated with this card.
  ///
  /// This is used when [PhotosAppController.isShowDebugInfo] is true to show
  /// the user the unique identifier of each card.
  final CardKey key;

  /// The initial x-position of the card.
  ///
  /// This is expressed as a floating point number from 0.0 to 1.0, where
  /// 0.0 represents the left-most position in the montage, and 1.0
  /// represents the right-most position in the montage.
  ///
  /// The real position of this card for any given frame is calculated by
  /// [calculateLocation] using this value.
  final double x;

  /// The initial y-position of the card.
  ///
  /// This is expressed as a floating point number from 0.0 to 1.0, where
  /// 0.0 represents the bottom-most position in the montage, and 1.0
  /// represents the top-most position in the montage.
  ///
  /// The real position of this card for any given frame is calculated by
  /// [calculateLocation] using this value.
  final double y;

  /// The layer in which this card lives.
  ///
  /// The real position of this card for any given frame is calculated by
  /// [calculateLocation] using properties of this layer.
  final MontageLayer layer;

  /// A height of the canvas upon which photos are painted relative to the
  /// height of the screen.
  ///
  /// The [y] value is expressed in terms of the canvas height, so if this value
  /// were `1.0`, then as soon as photo cards got to the top of the screen,
  /// they'd disappear and reappear at the bottom of the screen. Having a larger
  /// value allows photo cards to float "off the screen" and not reappear for a
  /// while.
  static const double _canvasScreenRatio = 7;

  double _calculateDx(int currentFrame, Size screenSize) {
    return screenSize.width * x * layer.xSpread;
  }

  double _calculateDy(int currentFrame, Size screenSize) {
    double canvasHeight = screenSize.height * _canvasScreenRatio;
    double yOffset = canvasHeight * y * layer.ySpread;
    double frameOffset = canvasHeight - ((currentFrame * layer.speed) % canvasHeight);
    double yPos = (frameOffset + yOffset) % canvasHeight;
    double viewportOffset = (canvasHeight - screenSize.height) / -2;
    return yPos + viewportOffset;
  }

  double _calculateDx2(int currentFrame) {
    return x;
  }

  double _calculateDy2(int currentFrame) {
    return y + currentFrame / layer.travelTime;
  }

  /// Calculates the real location of this card at the specified frame number
  /// and screen size.
  ///
  /// This is called by [MontageController] to calculate the location at which
  /// this card should be drawn based on its [x], [y], and [layer] values.
  Offset calculateLocation(int currentFrame, Size screenSize) {
    return Offset(
      _calculateDx(currentFrame, screenSize),
      _calculateDy(currentFrame, screenSize),
    );
  }

  Offset calculateLocation2(int currentFrame) {
    return Offset(
      _calculateDx2(currentFrame),
      _calculateDy2(currentFrame),
    );
  }
}

class MontageSpinner extends StatefulWidget {
  const MontageSpinner({
    super.key,
    this.children = const <MontageCardLoader>[],
  });

  final List<MontageCardLoader> children;

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

class Montage extends MultiChildRenderObjectWidget {
  const Montage({
    super.key,
    this.rotation = 0,
    this.distance = 0,
    List<MontageCardLoader> children = const <MontageCardLoader>[],
  }) : super(children: children);

  final double rotation;
  final double distance;

  @override
  List<MontageCardLoader> get children => super.children.cast<MontageCardLoader>();

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderMontage(
      rotation: rotation,
      distance: distance,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderMontage renderObject) {
    renderObject
      ..rotation = rotation
      ..distance = distance;
  }
}

class MontageParentData extends ContainerBoxParentData<RenderMontageCard> {
  late MontageCanvasInfo canvasInfo;
}

class RenderMontage extends RenderBox
    with
        ContainerRenderObjectMixin<RenderMontageCard, MontageParentData>,
        RenderBoxContainerDefaultsMixin<RenderMontageCard, MontageParentData> implements MontageCanvasInfo {
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
  void setupParentData(covariant RenderMontageCard child) {
    if (child.parentData is! MontageParentData) {
      child.parentData = MontageParentData();
    }
  }

  @override
  void performLayout() {
    assert(constraints.isTight);
    size = constraints.biggest;
    // debugPrint('laying out RenderMontage - constraints=$constraints');
    RenderMontageCard? child = firstChild;
    while (child != null) {
      MontageParentData childParentData = child.parentData as MontageParentData;
      childParentData.canvasInfo = this;
      final Constraints childConstraints = constraints.copyWith(
        minHeight: constraints.minWidth,
        maxHeight: constraints.maxWidth,
      ) * child.layoutScale; // TODO: this layout scale should probably be 0.5 for all layers
      // debugPrint('$child - ${child.runtimeType} - $childConstraints');
      child.layout(childConstraints);
      child = childParentData.nextSibling;
    }
  }

  void paintBackwards(PaintingContext context, Offset offset) {
    RenderMontageCard? child = lastChild;
    while (child != null) {
      final MontageParentData childParentData = child.parentData! as MontageParentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.previousSibling;
    }
  }

  void paintForwards(PaintingContext context, Offset offset) {
    RenderMontageCard? child = firstChild;
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
    Matrix4 transform = _perspectiveTransform;
    PaintingContextCallback painter = paintForwards;
    if (rotation % math.pi != 0 || distance != 0) {
      final Size center = size / 2;
      assert(() {
        if (forceShowDebugInfo) {
          Paint paint = Paint()..color = const Color(0xffcc0000);
          context.canvas.drawLine(
            Offset(center.width, 0),
            Offset(center.width, size.height),
            paint,
          );
        }
        return true;
      }());
      transform = Matrix4.identity()
          ..translate(center.width, center.height)
          ..multiply(_perspectiveTransform)
          ..translate(0.0, 0.0, distance)
          ..rotateY(rotation)
          ..translate(-center.width, -center.height);
      if (rotation.abs() >= math.pi / 2.85 && rotation.abs() < math.pi * 1.48) {
        painter = paintBackwards;
      }
    }
    _transform = transform;
    layer = context.pushTransform(
      needsCompositing,
      offset,
      transform,
      painter,
      oldLayer: layer as TransformLayer?,
    );
  }

  @override
  Matrix4 get transform => _transform!;
  Matrix4? _transform;
}

abstract class MontageCanvasInfo {
  Size get size;
  Matrix4 get transform;
}

class MontageCard extends SingleChildRenderObjectWidget {
  const MontageCard({
    super.key,
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.zoom = 1,
    this.paintScale = 1,
    this.layoutScale = 1,
    this.imageWidth,
    this.imageHeight,
    super.child,
  });

  final double x;
  final double y;
  final double z;
  final double zoom;
  final double paintScale;
  final double layoutScale;
  final int? imageWidth;
  final int? imageHeight;

  @override
  RenderMontageCard createRenderObject(BuildContext context) {
    return RenderMontageCard(
      x: x,
      y: y,
      z: z,
      zoom: zoom,
      painScale: paintScale,
      layoutScale: layoutScale,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderMontageCard renderObject) {
    renderObject
      ..x = x
      ..y = y
      ..z = z
      ..zoom = zoom
      ..paintScale = paintScale
      ..layoutScale = layoutScale;
  }
}

class RenderMontageCard extends RenderProxyBox {
  RenderMontageCard({
    double x = 0,
    double y = 0,
    double z = 0,
    double zoom = 1,
    double painScale = 0,
    double layoutScale = 0,
  })  : _x = x,
        _y = y,
        _z = z,
        _zoom = zoom,
        _paintScale = painScale,
        _layoutScale = layoutScale;

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

  double _zoom = 1;
  double get zoom => _zoom;
  set zoom(double value) {
    if (value != _zoom) {
      _zoom = value;
      markNeedsPaint();
    }
  }

  double _paintScale = 1;
  double get paintScale => _paintScale;
  set paintScale(double value) {
    if (value != _paintScale) {
      _paintScale = value;
      markNeedsPaint();
    }
  }

  double _layoutScale = 1;
  double get layoutScale => _layoutScale;
  set layoutScale(double value) {
    if (value != _layoutScale) {
      _layoutScale = value;
      markNeedsPaint();
    }
  }

  Matrix4 get transform {
    return Matrix4.identity()
        ..translate(x, y, z)
        ..scale(paintScale, paintScale, paintScale);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // final MontageParentData parentData = this.parentData as MontageParentData;
    // final MontageCanvasInfo canvasInfo = parentData.canvasInfo;
    // final Size canvasSize = canvasInfo.size;
    // final Matrix4 transform = canvasInfo.transform.clone()..multiply(this.transform.clone());
    // debugPrint('$transform');
    // final Matrix4 inverseTransform = Matrix4.inverted(transform);
    // debugPrint('$inverseTransform');

    // Vector3 v1 = inverseTransform.perspectiveTransform(Vector3(canvasSize.width, canvasSize.height, 0));
    // Vector3 v2 = transform.perspectiveTransform(Vector3(canvasSize.width, canvasSize.height, 0));
    // debugPrint('FOO << ${v1.x},${v1.y} << ${canvasSize.width},${canvasSize.height} << ${v2.x},${v2.y}');
    // // Rect preTransformCanvasBounds = MatrixUtils.transformRect(inverseTransform, Offset.zero & canvasSize);
    // // Rect postTransformCanvasBounds = MatrixUtils.transformRect(transform, Offset.zero & canvasSize);
    // // debugPrint('FOO << $preTransformCanvasBounds << ${Offset.zero & canvasSize} << $postTransformCanvasBounds');

    // final Size postTransformSize = transform.transformSize(size);
    // debugPrint('size $size -> $postTransformSize');
    // final Size postTransformCanvasSize = transform.transformSize(canvasSize);
    // final Size preTransformCanvasSize = inverseTransform.transformSize(canvasSize);
    // Vector3 cS = Vector3(canvasSize.width, canvasSize.height, 0);
    // Vector3 preTS = inverseTransform.transform3(cS.clone());
    // Vector3 postTS = transform.transform3(cS.clone());
    // debugPrint('canvasSize $preTransformCanvasSize -> $canvasSize -> $postTransformCanvasSize :: $preTS -> $cS -> $postTS');
    // final Vector3 postTransformStart = Vector3(0, canvasSize.height, z);
    // final Vector3 preTransformStart = inverseTransform.transform3(postTransformStart.clone());
    // final Vector3 postTransformEnd = Vector3(canvasSize.width - size.width, -postTransformSize.height, z);
    // final Vector3 preTransformEnd = inverseTransform.transform3(postTransformEnd.clone());
    // final double deltaX = preTransformEnd.x - preTransformStart.x;
    // final double deltaY = preTransformEnd.y - preTransformStart.y;
    // debugPrint('pre-transform start $preTransformStart .. end $preTransformEnd');
    // final Offset realOffset = Offset(
    //   x * deltaX + preTransformStart.x,
    //   y * deltaY + preTransformStart.y,
    // );
    // debugPrint('$x,$y,$z -> $realOffset');
    // debugPrint('base offset $offset');
    // Vector3 v3 = Vector3(0, 1014.6, 500);
    // transform.transform3(v3);
    // debugPrint('v3 = $v3');

    // debugPrint(zoom.toString());
    // debugPrint(Matrix4.fromList(context.canvas.getTransform()).toString());
    layer = context.pushTransform(
      needsCompositing,
      offset,
      transform,
      super.paint,
      oldLayer: layer as TransformLayer?,
    );
  }
}
