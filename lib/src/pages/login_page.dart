import 'dart:async';

import 'package:flutter/material.dart' show ElevatedButton, ScaffoldMessenger, SnackBar;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Notification;

import '../model/auth.dart';

import 'app.dart';
import 'notifications.dart';
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

class NeedToLoginNotification extends Notification {
  const NeedToLoginNotification({this.isInteractive = false});

  final bool isInteractive;

  @override
  Widget? build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'To be able to show your personal photos, you must sign in to Google Photos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0x99000000),
            ),
          ),
          if (isInteractive) const LoginButton(),
          if (!isInteractive)
            const Text(
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

class _LoginPageState extends State<LoginPage> {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Flexible(
                fit: FlexFit.tight,
                child: ColoredBox(
                  color: Color(0xff000000),
                  child: AssetPhotosMontageContainer(),
                ),
              ),
              ColoredBox(
                color: const Color(0xfff3eff3),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: NeedToLoginNotification(isInteractive: isInteractive).build(context),
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
  const LoginButton({super.key});

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> {
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    WidgetsBinding.instance.focusManager.rootScope.requestFocus(focusNode);
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
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      focusNode: focusNode,
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
