import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:photos/src/model/photos_library_api_model.dart';

import 'photos_page.dart';

class UndoableActionDispatcher extends ActionDispatcher implements Listenable {
  /// Constructs a new [UndoableActionDispatcher].
  ///
  /// The [maxUndoLevels] argument must not be null.
  UndoableActionDispatcher({
    int maxUndoLevels = _defaultMaxUndoLevels,
  })  : assert(maxUndoLevels != null),
        _maxUndoLevels = maxUndoLevels;

  // A stack of actions that have been performed. The most recent action
  // performed is at the end of the list.
  final List<UndoableAction> _completedActions = <UndoableAction>[];
  // A stack of actions that can be redone. The most recent action performed is
  // at the end of the list.
  final List<UndoableAction> _undoneActions = <UndoableAction>[];

  static const int _defaultMaxUndoLevels = 1000;

  /// The maximum number of undo levels allowed.
  ///
  /// If this value is set to a value smaller than the number of completed
  /// actions, then the stack of completed actions is truncated to only include
  /// the last [maxUndoLevels] actions.
  int get maxUndoLevels => _maxUndoLevels;
  int _maxUndoLevels;
  set maxUndoLevels(int value) {
    _maxUndoLevels = value;
    _pruneActions();
  }

  final Set<VoidCallback> _listeners = <VoidCallback>{};

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notifies listeners that the [ActionDispatcher] has changed state.
  ///
  /// May only be called by subclasses.
  @protected
  void notifyListeners() {
    for (VoidCallback callback in _listeners) {
      callback();
    }
  }

  @override
  bool invokeAction(Action action, Intent intent, {FocusNode focusNode}) {
    final bool result = super.invokeAction(action, intent, focusNode: focusNode);
    print('Invoking ${action is UndoableAction ? 'undoable ' : ''}$intent as $action: $this ');
    if (action is UndoableAction) {
      _completedActions.add(action);
      _undoneActions.clear();
      _pruneActions();
      notifyListeners();
    }
    return result;
  }

  // Enforces undo level limit.
  void _pruneActions() {
    while (_completedActions.length > _maxUndoLevels) {
      _completedActions.removeAt(0);
    }
  }

  /// Returns true if there is an action on the stack that can be undone.
  bool get canUndo {
    if (_completedActions.isNotEmpty) {
      final Intent lastIntent = _completedActions.last.invocationIntent;
      return lastIntent.isEnabled(WidgetsBinding.instance.focusManager.primaryFocus.context);
    }
    return false;
  }

  /// Returns true if an action that has been undone can be re-invoked.
  bool get canRedo {
    if (_undoneActions.isNotEmpty) {
      final Intent lastIntent = _undoneActions.last.invocationIntent;
      return lastIntent.isEnabled(WidgetsBinding.instance.focusManager.primaryFocus?.context);
    }
    return false;
  }

  /// Undoes the last action executed if possible.
  ///
  /// Returns true if the action was successfully undone.
  bool undo() {
    print('Undoing. $this');
    if (!canUndo) {
      return false;
    }
    final UndoableAction action = _completedActions.removeLast();
    action.undo();
    _undoneActions.add(action);
    notifyListeners();
    return true;
  }

  /// Re-invokes a previously undone action, if possible.
  ///
  /// Returns true if the action was successfully invoked.
  bool redo() {
    print('Redoing. $this');
    if (!canRedo) {
      return false;
    }
    final UndoableAction action = _undoneActions.removeLast();
    action.invoke(action.invocationNode, action.invocationIntent);
    _completedActions.add(action);
    _pruneActions();
    notifyListeners();
    return true;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('undoable items', _completedActions.length));
    properties.add(IntProperty('redoable items', _undoneActions.length));
    properties.add(IterableProperty<UndoableAction>('undo stack', _completedActions));
    properties.add(IterableProperty<UndoableAction>('redo stack', _undoneActions));
  }
}

/// An action that can be undone.
abstract class UndoableAction extends Action {
  /// A const constructor to [UndoableAction].
  ///
  /// The [intentKey] parameter must not be null.
  UndoableAction(LocalKey intentKey) : super(intentKey);

  /// The node supplied when this command was invoked.
  FocusNode get invocationNode => _invocationNode;
  FocusNode _invocationNode;

  @protected
  set invocationNode(FocusNode value) => _invocationNode = value;

  /// The [Intent] this action was originally invoked with.
  Intent get invocationIntent => _invocationTag;
  Intent _invocationTag;

  @protected
  set invocationIntent(Intent value) => _invocationTag = value;

  /// Returns true if the data model can be returned to the state it was in
  /// previous to this action being executed.
  ///
  /// Default implementation returns true.
  bool get undoable => true;

  /// Reverts the data model to the state before this command executed.
  @mustCallSuper
  void undo();

  @override
  @mustCallSuper
  void invoke(FocusNode node, Intent tag) {
    invocationNode = node;
    invocationIntent = tag;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusNode>('invocationNode', invocationNode));
  }
}

class SetFocusActionBase extends UndoableAction {
  SetFocusActionBase(LocalKey name) : super(name);

  FocusNode _previousFocus;

  @override
  void invoke(FocusNode node, Intent tag) {
    super.invoke(node, tag);
    _previousFocus = WidgetsBinding.instance.focusManager.primaryFocus;
    node.requestFocus();
  }

  @override
  void undo() {
    if (_previousFocus == null) {
      WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
      return;
    }
    if (_previousFocus is FocusScopeNode) {
      // The only way a scope can be the _previousFocus is if there was no
      // focusedChild for the scope when we invoked this action, so we need to
      // return to that state.

      // Unfocus the current node to remove it from the focused child list of
      // the scope.
      WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
      // and then let the scope node be focused...
    }
    _previousFocus.requestFocus();
    _previousFocus = null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusNode>('previous', _previousFocus));
  }
}

class NextFocusAction extends SetFocusActionBase {
  NextFocusAction() : super(key);

  static const LocalKey key = ValueKey<Type>(NextFocusAction);

  @override
  void invoke(FocusNode node, Intent tag) {
    debugPrint('Invoking next focus action');
    super.invoke(node, tag);
    debugPrint('before :: ${node.enclosingScope.focusedChild}');
    node.nextFocus();
    debugPrint('after :: ${node.enclosingScope.focusedChild}');
  }
}

class LoginAction extends SetFocusActionBase {
  LoginAction(this.globalKey) : super(key);

  static const LocalKey key = ValueKey<Type>(LoginAction);
  static const Intent intent = Intent(key);

  final GlobalKey<_LoginPageState> globalKey;

  @override
  void invoke(FocusNode node, Intent tag) {
    debugPrint('Invoking login action');
    super.invoke(node, tag);
    RaisedButton loginButton = globalKey.currentWidget;
    loginButton.onPressed();
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  UndoableActionDispatcher dispatcher;
  FocusNode focusNode;
  GlobalKey<_LoginPageState> globalKey;

  @override
  void initState() {
    super.initState();
    globalKey = GlobalKey();
    dispatcher = UndoableActionDispatcher();
    focusNode = FocusNode();
    WidgetsBinding.instance.focusManager.rootScope.requestFocus(focusNode);
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const Intent(NextFocusAction.key),
        LogicalKeySet(LogicalKeyboardKey.space): LoginAction.intent,
        LogicalKeySet(LogicalKeyboardKey.select): LoginAction.intent,
      },
      child: Actions(
        dispatcher: dispatcher,
        actions: <LocalKey, ActionFactory>{
          NextFocusAction.key: () => NextFocusAction(),
          LoginAction.key: () => LoginAction(globalKey),
        },
        child: Scaffold(
          body: ScopedModelDescendant<PhotosLibraryApiModel>(
            builder: (BuildContext context, Widget child, PhotosLibraryApiModel apiModel) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(30),
                      child: const Text(
                        'To be able to access your photos, you must sign in to Google Photos',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w500, color: Color(0x99000000)),
                      ),
                    ),
                    RaisedButton(
                      key: globalKey,
                      focusNode: focusNode,
                      padding: const EdgeInsets.all(15),
                      child: const Text('Connect with Google Photos'),
                      onPressed: () async {
                        try {
                          await apiModel.signIn() ? _navigateToPhotos(context) : _showSignInError(context);
                        } on Exception catch (error) {
                          print(error);
                          _showSignInError(context);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSignInError(BuildContext context) {
    final SnackBar snackBar = SnackBar(
      duration: Duration(seconds: 3),
      content: const Text('Could not sign in.'),
    );
    Scaffold.of(context).showSnackBar(snackBar);
  }

  void _navigateToPhotos(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => PhotosPage(),
      ),
    );
  }
}
