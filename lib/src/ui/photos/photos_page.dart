import 'dart:async';
import 'dart:io' show HttpStatus;
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart' hide Notification;

import 'package:photos/src/model/photo.dart';
import 'package:photos/src/model/photo_producer.dart';
import 'package:photos/src/model/photos_api.dart';
import 'package:photos/src/ui/common/animation.dart';
import 'package:photos/src/ui/common/notifications.dart';
import 'package:photos/src/ui/photos/key_press_handler.dart';

import 'app.dart';
import 'content_producer.dart';
import 'intents.dart';
import 'montage.dart';

const _rotationInterval = Duration(seconds: 60);

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

  static final List<PhotoCard> _cards = _generateCards();

  static List<PhotoCard> _generateCards() {
    int nextKeyIndex = 1;
    CardKey newKey() => CardKey(nextKeyIndex++);
    return <PhotoCard>[
      PhotoCard(xPercentages: const <double>[0.07], baseY: 0.90, layer: MontageLayer.back, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.54], baseY: 0.70, layer: MontageLayer.back, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.96], baseY: 0.50, layer: MontageLayer.back, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.04], baseY: 0.40, layer: MontageLayer.back, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.35], baseY: 0.20, layer: MontageLayer.back, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.79], baseY: 0.10, layer: MontageLayer.back, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.01], baseY: 0.90, layer: MontageLayer.middle, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.47], baseY: 0.80, layer: MontageLayer.middle, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.85], baseY: 0.60, layer: MontageLayer.middle, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.05], baseY: 0.50, layer: MontageLayer.middle, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.50], baseY: 0.38, layer: MontageLayer.middle, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.90], baseY: 0.25, layer: MontageLayer.middle, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.15], baseY: 0.15, layer: MontageLayer.middle, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.85], baseY: 0.00, layer: MontageLayer.middle, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.10], baseY: 0.90, layer: MontageLayer.front, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.90], baseY: 0.70, layer: MontageLayer.front, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.20], baseY: 0.45, layer: MontageLayer.front, key: newKey()),
      PhotoCard(xPercentages: const <double>[0.75], baseY: 0.20, layer: MontageLayer.front, key: newKey()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ContentProducer(
      producer: producer,
      child: MontageFrameDriver(
        cards: _cards,
      ),
    );
  }
}

class CardKey extends ValueKey<int> {
  const CardKey(super.value);
}

class MontageFrameDriver extends StatefulWidget {
  const MontageFrameDriver({super.key, required this.cards});

  final List<PhotoCard> cards;

  @override
  State<MontageFrameDriver> createState() => _MontageFrameDriverState();
}

class _MontageFrameDriverState extends State<MontageFrameDriver> {
  int? _scheduledFrameCallbackId;
  int _currentFrame = 0;
  Timer? _resumeTimer;

  static const Duration _resumeDuration = Duration(seconds: 5);

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
    _cancelFrame();
    _scheduleResume();
    setState(() => _currentFrame -= 20);
  }

  void _handleFastForward(Intent intent) {
    _cancelFrame();
    _scheduleResume();
    setState(() => _currentFrame+= 20);
  }

  void _scheduleResume() {
    if (_resumeTimer != null) {
      _resumeTimer!.cancel();
    }
    _resumeTimer = Timer(_resumeDuration, _handleResume);
  }

  void _handleResume() {
    _resumeTimer = null;
    _scheduleFrame();
  }

  void _updateImageCacheSize() {
    imageCache.maximumSize = widget.cards.length;
  }

  @override
  void initState() {
    super.initState();
    _scheduleFrame();
    _updateImageCacheSize();
  }

  @override
  void didUpdateWidget(covariant MontageFrameDriver oldWidget) {
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
      },
      child: KeyPressHandler(
        child: MontageSpinner(
          frame: _currentFrame,
          children: widget.cards,
        ),
      ),
    );
  }
}

class MontageSpinner extends StatefulWidget {
  const MontageSpinner({
    super.key,
    this.isPerspective = true,
    this.fovYRadians = math.pi * 4 / 10000,
    this.zNear = 1,
    this.zFar = 10,
    this.rotation = 0,
    this.distance = -1900,
    this.pullback = -5100,
    this.extraPullback = -7000,
    this.frame = 0,
    this.children = const <Widget>[],
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
  final List<Widget> children;

  @override
  State<MontageSpinner> createState() => _MontageSpinnerState();
}

class _MontageSpinnerState extends State<MontageSpinner> with SingleTickerProviderStateMixin {
  late AnimationController animation;
  late Animation<double> rotation;
  late Animation<double> distance;
  late Timer timer;

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
          tween: Tween<double>(begin: 0, end: -7000).chain(CurveTween(curve: Curves.easeInOutSine)),
          weight: 48,
        ),
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(-7000),
          weight: 4,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: -7000, end: 0).chain(CurveTween(curve: Curves.easeInOutSine)),
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
      isPerspective: widget.isPerspective,
      fovYRadians: widget.fovYRadians,
      zNear: widget.zNear,
      zFar: widget.zFar,
      rotation: rotation.value,
      distance: widget.distance,
      pullback: widget.pullback,
      extraPullback: distance.value,
      frame: widget.frame,
      children: widget.children,
    );
  }
}

/// A widget that creates a [MontageCard] given a `Future<Photo>`.
///
/// Until the future completes, the card will house an empty container. Once
/// the future completes, it will house the photo.
class PhotoCard extends StatefulWidget {
  const PhotoCard({
    super.key,
    required this.xPercentages,
    required this.baseY,
    required this.layer,
    this.useShadow = false,
    this.debugImageLabel,
  }) : assert(xPercentages.length > 0);

  final List<double> xPercentages;
  final double baseY;
  final MontageLayer layer;
  final bool useShadow;
  final String? debugImageLabel;

  @override
  State<PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<PhotoCard> {
  Future<Photo>? _photoFuture;
  Photo? _currentPhoto;
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;
  int _updateCount = 0;
  bool _isShowDebugInfo = false;
  int _xPercentageIndex = 0;

  late final ImageStreamListener _imageStreamListener;

  void _producePhoto(MontageCardConstraints constraints) {
    assert(_photoFuture == null);
    Future<Photo> future = _photoFuture = ContentProducer.of(context).producePhoto(
      context: context,
      sizeConstraints: Size.square(constraints.transformedExtent),
    );
    future.then<void>((Photo photo) {
      assert(_photoFuture == future);
      _photoFuture = null;
      _disposePhoto();
      if (mounted) {
        _currentPhoto = photo;
        _subscribeImageStream();
      } else {
        photo.dispose();
      }
    }, onError: _handleErrorFromPhotoFuture);
  }

  void _subscribeImageStream() {
    assert(_photoFuture == null);
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
    // If we wanted to NOT show animated GIFs, we'd call `_unsubscribeImageStream()`
    // here. By keeping the subscription here, we'll be notified of multi-frame
    // images, thus animating them.
    setState(() {
      _disposeImageInfo();
      _imageInfo = image;
      _updateCount++;
    });
  }

  void _handleErrorFromPhotoFuture(Object error, StackTrace? stack) {
    _handleError('loading image', error, stack);
  }

  void _handleErrorFromImageStream(Object error, StackTrace? stack) {
    _handleError('loading image info', error, stack);
  }

  void _handleError(String description, Object error, StackTrace? stack) async {
    if (error is NetworkImageLoadException && error.statusCode == HttpStatus.forbidden) {
      debugPrint('Renewing auth token');
      await PhotosApiBinding.instance.handleAuthTokenExpired();
    } else {
      debugPrint('Error while $description: $error\n$stack');
      PhotosApp.of(context).addError(error, stack);
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

  void _handleReload(MontageCardConstraints constraints) {
    _producePhoto(constraints);
    setState(() {
      _xPercentageIndex = (_xPercentageIndex + 1) % widget.xPercentages.length;
    });
  }

  void _handleFirstLayoutIsBelowFold(MontageCardConstraints constraints) {
    _producePhoto(constraints);
  }

  Widget _buildChild(BuildContext context, MontageCardConstraints constraints) {
    Widget child;
    if (_imageInfo == null) {
      child = Container();
    } else {
      child = RawImage(
        image: _imageInfo!.image,
        scale: _imageInfo!.scale,
        fit: BoxFit.contain,
        debugImageLabel: widget.debugImageLabel,
      );
    }

    if (_isShowDebugInfo) {
      List<Widget> children = <Widget>[child];
      children.addAll(<Widget>[
        ColoredBox(color: widget.layer.debugColor),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Text(widget.key.toString()),
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
      child = DefaultTextStyle.merge(
        style: TextStyle(fontSize: 16 * constraints.scale),
        child: Stack(
          fit: StackFit.passthrough,
          children: children,
        ),
      );
    }

    if (widget.useShadow) {
      child = DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: 20 * constraints.scale,
              color: const Color(0x66000000),
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
    _imageStreamListener = ImageStreamListener(_handleImage, onError: _handleErrorFromImageStream);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool isShowDebugInfo = PhotosApp.of(context).isShowDebugInfo;
    if (_isShowDebugInfo != isShowDebugInfo) {
      _isShowDebugInfo = isShowDebugInfo;
      _updateCount++;
    }
  }

  @override
  void didUpdateWidget(covariant PhotoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.useShadow != oldWidget.useShadow ||
        widget.debugImageLabel != oldWidget.debugImageLabel) {
      _updateCount++;
    }
  }

  @override
  void dispose() {
    _unsubscribeImageStream();
    _disposeImageInfo();
    _disposePhoto();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MontageCard(
      xPercentage: widget.xPercentages[_xPercentageIndex],
      baseY: widget.baseY,
      layer: widget.layer,
      updateCount: _updateCount,
      onReload: _handleReload,
      onFirstLayoutIsBelowFold: _handleFirstLayoutIsBelowFold,
      builder: _buildChild,
    );
  }
}
