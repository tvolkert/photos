import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:photos/src/model/auth.dart';
import 'package:photos/src/pages/login_page.dart';

import 'src/model/app.dart';
import 'src/model/photos_library_api_model.dart';
import 'src/pages/home_page.dart';
import 'src/pages/app.dart';

@pragma('vm:entry-point')
void main() => settingsMain();//run(interactive: true);

@pragma('vm:entry-point')
void dream() => run(interactive: false);

Future<void> run({required bool interactive}) async {
  await AppBinding.ensureInitialized();
  final PhotosLibraryApiModel apiModel = PhotosLibraryApiModel();
  AuthBinding.instance.signInSilently();
  runApp(
    PhotosApp(
      interactive: interactive,
      apiModel: apiModel,
      child: const HomePage(),
    ),
  );
}

@pragma('vm:entry-point')
void settingsMain() async {
  await AppBinding.ensureInitialized();
  final PhotosLibraryApiModel apiModel = PhotosLibraryApiModel();
  AuthBinding.instance.signInSilently();
  runApp(
    PhotosApp(
      interactive: true,
      apiModel: apiModel,
      child: const LoginPage(),
      // child: SettingsPage(),
    ),
  );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  GoogleSignInAccount? _account;

  Future<void> _handleCurrentUserChanged() async {
    setState(() {
      _account = AuthBinding.instance.maybeUser;
    });
  }

  @override
  void initState() {
    super.initState();
    AuthBinding.instance.onUserChanged = _handleCurrentUserChanged;
    AuthBinding.instance.signInSilently();
  }

  @override
  void dispose() {
    AuthBinding.instance.onUserChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xffffcc00),
      child: Text('${_account?.email ?? 'Todd'}'),
    );
  }
}
