import 'package:firebase_auth/firebase_auth.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:flutter/material.dart';

class CustomSettings extends StatelessWidget {
  const CustomSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsList(
      sections: [
        SettingsSection(
          title: Text('Common'),
          tiles: <SettingsTile>[
            SettingsTile.navigation( //hi
              leading: Icon(Icons.language),
              title: Text('Language'),
              value: Text('English'),
            ),
            SettingsTile.switchTile(
              onToggle: (value) {},
              initialValue: true,
              leading: Icon(Icons.format_paint),
              title: Text('Enable custom theme'),
            ),
            SettingsTile.navigation(
              leading: Icon(Icons.logout),
              title: Text('Log out'),
              onPressed: (context) async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/parent_login');
              },
            ),
          ],
        ),
        SettingsSection(
          title: Text('Account'),
          tiles: <SettingsTile>[
            SettingsTile.navigation(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onPressed: (context) {

              },
            ),
            SettingsTile.navigation(
              leading: Icon(Icons.lock),
              title: Text('Change Password'),
              onPressed: (context) {

              },
            ),
          ],
        ),
        SettingsSection(
          title: Text('Notifications'),
          tiles: <SettingsTile>[
            SettingsTile.switchTile(
              leading: Icon(Icons.notifications),
              title: Text('Enable Notifications'),
              onToggle: (value) {

              },
              initialValue: true,
            ),
          ],
        ),
        SettingsSection(
          title: Text('Privacy'),
          tiles: <SettingsTile>[
            SettingsTile.navigation(
              leading: Icon(Icons.lock_outline),
              title: Text('Privacy Policy'),
              onPressed: (context) {

              },
            ),
            SettingsTile.navigation(
              leading: Icon(Icons.security),
              title: Text('Security Settings'),
              onPressed: (context) {

              },
            ),
          ],
        ),
      ],
    );
  }
}
