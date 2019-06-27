import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:scoped_model/scoped_model.dart';

import '../model/photo.dart';
import '../model/photo_cards.dart';
import '../model/photos_library_api_model.dart';

class PhotosPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<PhotosLibraryApiModel>(
      builder: (context, child, apiModel) {
        return _PhotosCascade(photos: apiModel.photos);
      },
    );
  }
}

class _PhotosCascade extends StatefulWidget {
  _PhotosCascade({
    Key key,
    @required this.photos,
  })  : assert(photos != null),
        super(key: key);

  /// The stream of photos to show.
  final Stream<Photo> photos;

  @override
  _PhotosCascadeState createState() => _PhotosCascadeState();
}

class _PhotosCascadeState extends State<_PhotosCascade> {
  StreamSubscription<Photo> subscription;

  @override
  void initState() {
    super.initState();
    subscription = widget.photos.listen((Photo photo) {
      PhotoMontage montage = ScopedModel.of<PhotoMontage>(context);
      montage.addPhoto(photo);
    }, onError: (dynamic error, StackTrace stackTrace) {
      debugPrint('$error\n$stackTrace');
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TODO(tvolkert): drop photos that are off-screen.
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('building cascade');
    return ScopedModelDescendant<PhotoMontage>(
      builder: (BuildContext context, Widget child, PhotoMontage montage) {
      return Stack(
        children: montage.cards.map<Widget>((PhotoCard card) {
          return FLoatingPhoto(
            card: card,
          );
        }).toList(),
      );
    });
  }
}

class FLoatingPhoto extends StatefulWidget {
  FLoatingPhoto({
    Key key,
    @required this.card,
  })  : assert(card != null),
        super(key: key);

  final PhotoCard card;

  @override
  _FLoatingPhotoState createState() => _FLoatingPhotoState();
}

class _FLoatingPhotoState extends State<FLoatingPhoto> with SingleTickerProviderStateMixin {
  Ticker ticker;

  @override
  void initState() {
    super.initState();
    ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    ticker
      ..stop()
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FLoatingPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    // TODO: do something?
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Positioned(
      child: Stack(
        children: <Widget>[
          Image.memory(
            widget.card.photo.bytes,
            scale: widget.card.photo.scale / widget.card.width,
          ),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Layer: ${widget.card.column.layer.index + 1}'),
                Text('Column: ${widget.card.column.index + 1}'),
                Text('Top: ${widget.card.top}'),
                Text('Bottom: ${widget.card.bottom}'),
                Text('ScreenSize: $screenSize'),
              ],
            ),
          ),
        ],
      ),
      left: screenSize.width * widget.card.left,
      top: screenSize.height - widget.card.top,
    );
  }

  void _tick(Duration elapsed) {
    setState(() {
      widget.card.nextFrame();
      double screenHeight = MediaQuery.of(context).size.height;
      if (widget.card.bottom > screenHeight) {
        widget.card.dispose();
      }
    });
  }
}

class PeriodicSpinner extends StatefulWidget {
  PeriodicSpinner({
    Key key,
    @required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  _PeriodicSpinnerState createState() => _PeriodicSpinnerState();
}

class _PeriodicSpinnerState extends State<PeriodicSpinner> with TickerProviderStateMixin {
  AnimationController controller;
  Animation<double> angleAnimation;
  Animation<double> transformAnimation;
  Timer timer;
  double angle;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    angleAnimation = controller.drive(
        Tween<double>(begin: 0, end: 2 * math.pi).chain(CurveTween(curve: Curves.easeInOutCubic)));
    transformAnimation = controller.drive(Tween<double>());
    timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      controller.forward().then((void _) {
        controller.reset();
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.rotationY(angleAnimation.value),
      child: widget.child,
    );
  }
}
