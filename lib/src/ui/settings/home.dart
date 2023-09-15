import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import 'accounts.dart';
import 'common.dart';
import 'nav.dart';

class SettingsHome extends StatelessWidget {
  const SettingsHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 40),
          child: Text(
            'Settings',
            style: DefaultTextStyle.of(context).style.copyWith(fontSize: 35),
          ),
        ),
        IconSetting(
          text: 'Accounts & Sign In',
          icon: Icons.account_circle_outlined,
          autofocus: true,
          isActivePane: SettingsNav.of(context).isActivePage(context),
          onGainsFocus: () {
            SettingsNav.of(context).setNext(const AccountsPage());
          },
        ),
      ],
    );
  }
}
