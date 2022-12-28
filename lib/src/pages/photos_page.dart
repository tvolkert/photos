import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:scoped_model/scoped_model.dart';

import '../model/photo_cards.dart';
import '../model/photo_producer.dart';
import '../model/photos_library_api_model.dart';

class PhotosHome extends StatefulWidget {
  const PhotosHome({
    Key? key,
    required this.montageBuilder,
    required this.producerBuilder,
  }) : super(key: key);

  @override
  State<PhotosHome> createState() => _PhotosHomeState();

  final PhotoMontageBuilder montageBuilder;
  final PhotoCardProducerBuilder producerBuilder;
}

class _PhotosHomeState extends State<PhotosHome> {
  late PhotoMontage montage;
  late PhotoCardProducer producer;

  @override
  void initState() {
    super.initState();
    final PhotosLibraryApiModel model = ScopedModel.of<PhotosLibraryApiModel>(context);
    montage = widget.montageBuilder();
    producer = widget.producerBuilder(model, montage)..start();
  }

  @override
  void dispose() {
    producer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<PhotoMontage>(
      model: montage,
      child: const _PhotosCascade(),
    );
  }
}

class _PhotosCascade extends StatelessWidget {
  const _PhotosCascade({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<PhotoMontage>(
      builder: (BuildContext context, Widget? child, PhotoMontage montage) {
        return Stack(
          children: montage.cards.map<Widget>((PhotoCard card) {
            return FloatingPhoto(
              card: card,
            );
          }).toList(),
        );
      },
    );
  }
}

class FloatingPhoto extends StatefulWidget {
  const FloatingPhoto({
    Key? key,
    required this.card,
  }) : super(key: key);

  final PhotoCard card;

  @override
  State<FloatingPhoto> createState() => _FloatingPhotoState();
}

class _FloatingPhotoState extends State<FloatingPhoto> with SingleTickerProviderStateMixin {
  late final Ticker ticker;

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
  void didUpdateWidget(FloatingPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    // TODO: do something?
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Positioned(
      left: screenSize.width * widget.card.column.left,
      top: screenSize.height - widget.card.top,
      child: SizedBox(
        width: widget.card.column.width * screenSize.width,
        height: widget.card.column.width * screenSize.width,
        child: Image.memory(
          widget.card.photo.bytes,
          alignment: Alignment.topCenter,
          scale: widget.card.photo.scale,
        ),
      ),
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
  const PeriodicSpinner({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  State<PeriodicSpinner> createState() => _PeriodicSpinnerState();
}

class _PeriodicSpinnerState extends State<PeriodicSpinner> with TickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> angleAnimation;
  Animation<double>? transformAnimation;
  late Timer timer;
  double? angle;

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
