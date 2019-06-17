import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:scoped_model/scoped_model.dart';

import '../model/photo.dart';
import '../model/photos_library_api_model.dart';
import '../model/random.dart';

const int _zIndexCount = 4;

double _scale(int zIndex) {
  return 1.15 * (_zIndexCount - zIndex);
}

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
  _PhotosCascade({Key key, @required this.photos}) : super(key: key);

  final Stream<Photo> photos;

  @override
  _PhotosCascadeState createState() => _PhotosCascadeState();
}

class _PhotosCascadeState extends State<_PhotosCascade> with TickerProviderStateMixin {
  List<List<PhotoCard>> cards;
  StreamSubscription<Photo> subscription;
  Ticker ticker;

  @override
  void initState() {
    super.initState();
    cards = List<List<PhotoCard>>.generate(_zIndexCount, (int index) => <PhotoCard>[]);
    ticker = createTicker(_tick)..start();
    subscription = widget.photos.listen((Photo photo) {
      setState(() {
        Size mediaSize = MediaQuery.of(context).size;
        int zIndex = random.nextInt(_zIndexCount);
        double scale = _scale(zIndex);
        double maxLeft = math.max(mediaSize.width - (photo.size.width / scale), 0);
        double left = random.nextDouble() * maxLeft;
        cards[zIndex].add(PhotoCard(
          photo: photo,
          zIndex: zIndex,
          left: left,
          top: mediaSize.height,
        ));
      });
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    ticker
      ..stop()
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TODO(tvolkert): drop photos that are off-screen.
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: cards.expand((List<PhotoCard> cards) => cards).map<Widget>((PhotoCard card) {
        return FLoatingPhoto(card: card);
      }).toList(),
    );
  }

  void _tick(Duration elapsed) {
    setState(() {
      List<PhotoCard> localCards = cards.expand((List<PhotoCard> cards) => cards).toList();
      for (PhotoCard card in localCards) {
        card.top -= (card.zIndex + 1) / _zIndexCount;
        if (card.top + card.photo.size.height < 0) {
          bool removed = cards[card.zIndex].remove(card);
          assert(removed);
        }
      }
    });
  }
}

class PhotoCard {
  PhotoCard({
    @required this.photo,
    @required this.zIndex,
    @required this.left,
    @required this.top,
  });

  final Photo photo;
  final int zIndex;
  final double left;
  double top;

  @override
  int get hashCode => hashValues(photo.hashCode, left);

  @override
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    PhotoCard typedOther = other;
    return photo == typedOther.photo && left == typedOther.left;
  }

  @override
  String toString() => '$zIndex :: $left,$top';
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

class _FLoatingPhotoState extends State<FLoatingPhoto> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: Image.memory(
        widget.card.photo.bytes,
        scale: widget.card.photo.scale * _scale(widget.card.zIndex),
      ),
      left: widget.card.left,
      top: widget.card.top,
    );
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
