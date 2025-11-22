import 'package:flutter/material.dart';
import '../objects/settings_options.dart';
import '../app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: memoirTheme.background,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: memoirTheme.onBackground,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      //include text stating category of the settings option. How?
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
           Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Personalization",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: memoirTheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          SettingsOption(
            icon: Icons.palette_outlined,
            title: "Themes",
            onTap: () {
              // TODO: add change password logic
            },
          ),
          SettingsOption(
            icon: Icons.palette_outlined,
            title: "Filters",
            onTap: () {
              // TODO: add change password logic
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Account Settings",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: memoirTheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          SettingsOption(
            icon: Icons.person_outline,
            title: "Edit Profile",
            onTap: () {
              Navigator.pushNamed(context, '/editProfile');
            },
          ),
          SettingsOption(
            icon: Icons.lock_outline,
            title: "Change Password",
            onTap: () {
              // TODO: add change password logic
            },
          ),
          SettingsOption(
            icon: Icons.notifications_outlined,
            title: "Notifications",
            trailing: Transform.scale(
              scale: 0.7, // 
              child: Switch(
                value: true,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (value) {
                  // TODO: handle notification toggle
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Privacy Settings",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: memoirTheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          SettingsOption(
            icon: Icons.visibility_off_outlined,
            title: "Privacy Policy",
            onTap: () {
              // TODO: maybe toggle dark/light theme
            },
          ),
          
           SettingsOption(
            icon: Icons.person_outline,
            title: "privacy blah blah",
            onTap: () {
              Navigator.pushNamed(context, '/editProfile');
            },
          ),
          SettingsOption(
            icon: Icons.info_outline,
            title: "About App",
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "Memoir",
                applicationVersion: "1.0.0",
                applicationLegalese: "© 2025 Memoir Team",
              );
            },
          ),
        ],
      ),
    );
  }
}
