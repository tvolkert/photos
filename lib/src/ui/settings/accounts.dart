import 'dart:async';

import 'package:flutter/material.dart' show CircleAvatar, Icons;
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:photos/src/model/auth.dart';

import 'common.dart';
import 'nav.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({
    super.key,
  });

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  GoogleSignInAccount? _account;

  Future<void> _handleAuthenticationAction(GoogleSignInAccount? previousUser) async {
    setState(() {
      _account = AuthBinding.instance.maybeUser;
    });
  }

  List<Widget> _getSignedInAccountRows() {
    final TextStyle baseStyle = DefaultTextStyle.of(context).style;
    List<Widget> results = [];
    if (_account != null) {
      final String initial = _account!.email.replaceAll(RegExp(r'[^a-zA-Z]'), '').substring(0, 1).toUpperCase();
      CircleAvatar avatar = CircleAvatar(
        backgroundColor: const Color(0xffcc0000),
        child: Text(initial),
      );
      Widget nameAndEmail = Text(
        _account!.email,
        style: baseStyle.copyWith(
          fontSize: 12,
          color: const Color(0xff686c72),
        ),
      );

      if (_account!.displayName != null) {
        final String initials = _account!.displayName!.replaceAll(RegExp(r'[^A-Z]'), '').substring(0, 2);
        avatar = CircleAvatar(
          backgroundColor: const Color(0xffcc0000),
          child: Text(initials),
        );
        nameAndEmail = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _account!.displayName!,
              style: baseStyle.copyWith(
                fontSize: 12,
                color: const Color(0xff979aa0),
              ),
            ),
            nameAndEmail,
          ],
        );
      }

      if (_account!.photoUrl != null) {
        avatar = CircleAvatar(
          backgroundImage: NetworkImage(_account!.photoUrl!),
        );
      }

      results.add(
        Setting(
          isActivePane: SettingsNav.of(context).isActivePage(context),
          debugLabel: 'avatar',
          leading: (BuildContext context, bool hasFocus) {
            return avatar;
          },
          body: (BuildContext context, bool hasFocus) {
            return nameAndEmail;
          },
          onGoForward: () {},
        ),
      );
    }
    return results;
  }

  @override
  void initState() {
    super.initState();
    AuthBinding.instance.onAuthenticationAction = _handleAuthenticationAction;
    _account = AuthBinding.instance.maybeUser;
  }

  @override
  void dispose() {
    AuthBinding.instance.onAuthenticationAction = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 40),
          child: Text(
            'Accounts & Sign In',
            style: DefaultTextStyle.of(context).style.copyWith(
              color: const Color(0xff979aa0),
              fontSize: 34,
            ),
          ),
        ),
        ..._getSignedInAccountRows(),
        if (_account == null)
          IconSetting(
            text: 'Sign in with Google',
            icon: Icons.login,
            isActivePane: SettingsNav.of(context).isActivePage(context),
            onGoForward: () {
              AuthBinding.instance.signIn();
            },
          ),
        if (_account != null)
          IconSetting(
            text: 'Sign out',
            icon: Icons.logout,
            isActivePane: SettingsNav.of(context).isActivePage(context),
            onGoForward: () {
              AuthBinding.instance.signOut();
            },
          ),
      ],
    );
    return result;
  }
}
