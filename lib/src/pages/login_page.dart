import 'dart:async';

import 'package:flutter/material.dart' show ElevatedButton, ScaffoldMessenger, SnackBar;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../model/auth.dart';
import '../model/photos_library_api_model.dart';

import 'app.dart';
import 'photos_page.dart';

typedef LoginCallback = Future<void> Function();

class LoginIntent extends Intent {
  const LoginIntent();
}

class LoginAction extends Action<LoginIntent> {
  LoginAction({
    required this.onDoLogin,
    required this.onLoginSuccess,
    required this.onLoginFailure,
  });

  final LoginCallback onDoLogin;
  final VoidCallback onLoginSuccess;
  final VoidCallback onLoginFailure;

  static const LocalKey key = ValueKey<Type>(LoginAction);
  static const Intent intent = LoginIntent();

  @override
  Future<void> invoke(LoginIntent intent) async {
    try {
      await onDoLogin();
      if (AuthBinding.instance.isSignedIn) {
        onLoginSuccess();
      } else {
        onLoginFailure();
      }
    } on Exception catch (error, stack) {
      debugPrint('Failed to log in: $error\n$stack');
      onLoginFailure();
    }
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  FocusNode? focusNode;
  GlobalKey<_LoginPageState>? globalKey;

  @override
  void initState() {
    super.initState();
    globalKey = GlobalKey();
    focusNode = FocusNode();
    WidgetsBinding.instance.focusManager.rootScope.requestFocus(focusNode);
  }

  @override
  void dispose() {
    focusNode!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = PhotosApp.of(context).isInteractive;
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextFocusIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): LoginAction.intent,
        LogicalKeySet(LogicalKeyboardKey.select): LoginAction.intent,
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          LoginIntent: LoginAction(
            onDoLogin: AuthBinding.instance.signIn,
            onLoginSuccess: () => _navigateToPhotos(context),
            onLoginFailure: () => _showSignInError(context),
          ),
        },
        child: SizedBox.expand(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Flexible(
                flex: 2,
                fit: FlexFit.tight,
                child: ColoredBox(
                  color: Color(0xff000000),
                  child: AssetPhotosMontageContainer(),
                ),
              ),
              Flexible(
                flex: 1,
                fit: FlexFit.tight,
                child: ColoredBox(
                  color: const Color(0xfff3eff3),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(30),
                            child: const Text(
                              'To be able to show your personal photos, you must sign in to Google Photos',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0x99000000),
                              ),
                            ),
                          ),
                          if (isInteractive) LoginButton(globalKey: globalKey, focusNode: focusNode),
                          if (!isInteractive)
                            const Text(
                              'To sign in to Google Photos, launch this app from your home screen',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0x99000000),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignInError(BuildContext context) {
    const SnackBar snackBar = SnackBar(
      duration: Duration(seconds: 3),
      content: Text('Could not sign in.'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _navigateToPhotos(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/');
  }
}

class LoginButton extends StatefulWidget {
  const LoginButton({
    Key? key,
    required this.globalKey,
    required this.focusNode,
  }) : super(key: key);

  final GlobalKey<State<LoginPage>>? globalKey;
  final FocusNode? focusNode;

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.focusManager.addListener(() {
      final StringBuffer buf = StringBuffer();
      BuildContext? focusContext = WidgetsBinding.instance.focusManager.primaryFocus?.context;
      buf.write('focus has transfered to $focusContext');
      if (focusContext != null) {
        buf.writeln(' - widget ancestors are:');
        focusContext.visitAncestorElements((Element element) {
          buf.writeln('${element.widget}');
          return true;
        });
      }
      debugPrint(buf.toString());
    });
    scheduleMicrotask(() {
      if (widget.focusNode?.canRequestFocus ?? false) {
        widget.focusNode?.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      key: widget.globalKey,
      focusNode: widget.focusNode,
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
      child: const Text('Connect with Google Photos'),
      onFocusChange: (bool hasFocus) {
        debugPrint('Has focus? $hasFocus');
      },
      onPressed: () {
        debugPrint('*' * 100);
        final LoginAction action = Actions.find<LoginIntent>(context) as LoginAction;
        if (action.isEnabled(LoginAction.intent as LoginIntent)) {
          action.invoke(LoginAction.intent as LoginIntent);
        }
      },
    );
  }
}
