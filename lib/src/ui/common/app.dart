import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:photos/src/extensions/list.dart';
import 'package:photos/src/model/ui.dart';

import 'debug.dart';

mixin AppControllerMixin<T extends StatefulWidget> on State<T> implements AppController {
  bool _showDebugInfo = false;
  final List<(Object, StackTrace?)> _errors = <(Object, StackTrace?)>[];

  void _removeLastError() {
    void doRemoveLastError() {
      if (mounted && _errors.isNotEmpty) {
        setState(() {
          _errors.removeLast();
        });
      }
    }
    if (showErrorsInReleaseMode) {
      doRemoveLastError();
    } else {
      assert(() {
        doRemoveLastError();
        return true;
      }());
    }
  }

  /// A copy of the errors list.
  List<(Object, StackTrace?)> get errors => _errors.clone();

  @override
  bool get isShowDebugInfo {
    bool showDebugInfo = _showDebugInfo;
    assert(() {
      showDebugInfo |= forceShowDebugInfo;
      return true;
    }());
    return showDebugInfo;
  }

  @override
  void toggleShowDebugInfo() {
    setState(() {
      _showDebugInfo = !_showDebugInfo;
      assert(() {
        debugInvertOversizedImages = !debugInvertOversizedImages;
        return true;
      }());
    });
  }

  @override
  void addError(Object error, [StackTrace? stack]) {
    void doAddError() {
      setState(() {
        _errors.insert(0, (error, stack));
        Timer(const Duration(seconds: 10), _removeLastError);
      });
    }
    if (showErrorsInReleaseMode) {
      doAddError();
    } else {
      assert(() {
        doAddError();
        return true;
      }());
    }
  }
}
