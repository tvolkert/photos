import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:photos/src/model/photos_library_api_model.dart';

typedef LoginCallback = Future<bool> Function();

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
    debugPrint('Invoking login action');
    try {
      await onDoLogin() ? onLoginSuccess() : onLoginFailure();
    } on Exception catch (error) {
      print(error);
      onLoginFailure();
    }
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  FocusNode? focusNode;
  GlobalKey<_LoginPageState>? globalKey;

  @override
  void initState() {
    super.initState();
    globalKey = GlobalKey();
    focusNode = FocusNode();
    WidgetsBinding.instance!.focusManager.rootScope.requestFocus(focusNode);
  }

  @override
  void dispose() {
    focusNode!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<PhotosLibraryApiModel>(
      builder: (BuildContext context, Widget? child, PhotosLibraryApiModel apiModel) {
        return Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            // LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextFocusIntent(),
            LogicalKeySet(LogicalKeyboardKey.space): LoginAction.intent,
            LogicalKeySet(LogicalKeyboardKey.select): LoginAction.intent,
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              LoginIntent: LoginAction(
                onDoLogin: apiModel.signIn,
                onLoginSuccess: () => _navigateToPhotos(context),
                onLoginFailure: () => _showSignInError(context),
              ),
            },
            child: Scaffold(
              body: Center(
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
                    LoginButton(globalKey: globalKey, focusNode: focusNode),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  void _showSignInError(BuildContext context) {
    final SnackBar snackBar = SnackBar(
      duration: Duration(seconds: 3),
      content: const Text('Could not sign in.'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _navigateToPhotos(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/');
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({
    Key? key,
    required this.globalKey,
    required this.focusNode,
  }) : super(key: key);

  final GlobalKey<_LoginPageState>? globalKey;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      key: globalKey,
      focusNode: focusNode,
      padding: const EdgeInsets.all(15),
      child: const Text('Connect with Google Photos'),
      onPressed: () {
        final LoginAction action = Actions.find<LoginIntent>(context) as LoginAction;
        if (action.isEnabled(LoginAction.intent as LoginIntent)) {
          action.invoke(LoginAction.intent as LoginIntent);
        }
      },
    );
  }
}
