import 'package:flutter/widgets.dart';

class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({
    super.key,
    this.upperLeft,
    this.upperRight,
    this.bottomBar,
  });

  final Notification? upperLeft;
  final Notification? upperRight;
  final Notification? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        _NotificationCard(notification: upperLeft, placement: _NotificationPlacement.upperLeft),
        _NotificationCard(notification: upperRight, placement: _NotificationPlacement.upperRight),
        _NotificationCard(notification: bottomBar, placement: _NotificationPlacement.bottomBar),
      ],
    );
  }
}

abstract class Notification {
  const Notification();

  /// Returns true if this notification, when compared to `other`, should
  /// trigger a rebuild of the widget that's tied to this notification.
  @mustCallSuper
  bool shouldUpdate(Notification? other) {
    return other == null || runtimeType != other.runtimeType;
  }

  /// Build a widget that displays this notification to the user.
  ///
  /// This method returns null if the notification doesn't need to be shown to
  /// the user (e.g. an error notification with no errors).
  Widget? build(BuildContext context);
}

class NotificationBuilder extends Notification {
  const NotificationBuilder({this.builder});

  final WidgetBuilder? builder;

  @override
  bool shouldUpdate(Notification? other) {
    return super.shouldUpdate(other) || builder != (other as NotificationBuilder).builder;
  }

  @override
  Widget? build(BuildContext context) {
    return builder?.call(context);
  }
}

class ErrorsNotification extends Notification {
  const ErrorsNotification(this.errors);

  final List<(Object, StackTrace?)> errors;
  
  @override
  bool shouldUpdate(Notification? other) {
    return super.shouldUpdate(other)
        || errors.length != (other as ErrorsNotification).errors.length;
  }

  @override
  Widget? build(BuildContext context) {
    if (errors.isEmpty) {
      return null;
    }
    return ListView.builder(
      itemCount: errors.length,
      itemBuilder: (BuildContext context, int index) {
        return Text(
          '${errors[index].$1}\n${errors[index].$2 ?? ''}',
          style: DefaultTextStyle.of(context).style.copyWith(
            color: const Color(0xff757575),
          ),
        );
      },
    );
  }

  @override
  toString() => 'ErrorNotification(count=${errors.length})';
}

class NeedToLoginNotification extends Notification {
  const NeedToLoginNotification();

  @override
  Widget? build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'To be able to show your personal photos, you must sign in to Google Photos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0x99000000),
            ),
          ),
          Text(
            'Open System Screensaver Settings for this screensaver to sign in to Google Photos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0x99000000),
            ),
          ),
        ],
      ),
    );
  }
}

final class _NotificationPlacement {
  const _NotificationPlacement({
    this.left,
    this.top,
    this.right,
    this.bottom,
    BoxConstraints? Function(Size screenSize)? extraConstraints,
  }) : _extraConstraints = extraConstraints;

  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final  BoxConstraints? Function(Size screenSize)? _extraConstraints;

  static const double _padding = 10;

  static BoxConstraints _quadrant(Size screenSize) {
    return BoxConstraints(
      maxWidth: screenSize.width / 2 - 1.5 * _padding,
      maxHeight: screenSize.height / 2 - 1.5 * _padding,
    );
  }

  BoxConstraints applyExtraConstraints(Size screenSize) {
    BoxConstraints? calculatedConstraints = _extraConstraints?.call(screenSize);
    assert(() {
      if (calculatedConstraints != null && !calculatedConstraints!.isNormalized) {
        debugPrint('NotificationPlacement($left,$top,$right,$bottom) returned non-normalized constraints of $calculatedConstraints');
        calculatedConstraints = const BoxConstraints();
      }
      return true;
    }());
    return calculatedConstraints ?? const BoxConstraints();
  }

  static const _NotificationPlacement upperLeft = _NotificationPlacement(
    top: _padding,
    left: _padding,
    extraConstraints: _quadrant,
  );

  static const _NotificationPlacement upperRight = _NotificationPlacement(
    top: _padding,
    right: _padding,
  );

  static const _NotificationPlacement bottomBar = _NotificationPlacement(
    left: _padding,
    bottom: _padding,
    right: _padding,
  );
}

class _NotificationCard extends StatefulWidget {
  const _NotificationCard({
    required this.notification,
    required this.placement,
  });

  final Notification? notification;
  final _NotificationPlacement placement;

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  Widget? _child;
  CrossFadeState _state = CrossFadeState.showFirst;

  static const Duration _fadeDuration = Duration(milliseconds: 450);

  Widget _buildNotification(Notification? notification) {
    if (notification == null) {
      return const SizedBox.shrink();
    }
    Widget? result = notification.build(context);
    if (result == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      child: result,
    );
  }

  @override
  void didUpdateWidget(covariant _NotificationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notification == null && oldWidget.notification != null) {
      setState(() {
        _state = CrossFadeState.showSecond;
        _child = null;
      });
    } else if (widget.notification != null && widget.notification!.shouldUpdate(oldWidget.notification)) {
      setState(() {
        _state = CrossFadeState.showFirst;
        _child = _buildNotification(widget.notification);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Positioned(
      left: widget.placement.left,
      top: widget.placement.top,
      right: widget.placement.right,
      bottom: widget.placement.bottom,
      child: ConstrainedBox(
        constraints: widget.placement.applyExtraConstraints(screenSize),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xfff3eff3),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: Color(0xff000000),
            ),
            child: AnimatedCrossFade(
              firstChild: _child ?? const SizedBox.shrink(),
              secondChild: const SizedBox.shrink(),
              crossFadeState: _state,
              duration: _fadeDuration,
              firstCurve: Curves.easeOut,
              secondCurve: Curves.easeOut,
              sizeCurve: Curves.easeOut,
            ),
          ),
        ),
      ),
    );
  }
}
