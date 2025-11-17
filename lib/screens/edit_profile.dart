import 'package:flutter/material.dart';
import '../app_theme.dart'; // use your theme if needed

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: memoirTheme.background,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: memoirTheme.onBackground,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Divider(height: 1),
          ListTile(
            title: const Text("Change Username"),
            onTap: () {
              //to do: update username in database(?)
            }
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text("Change Profile Picture"),
            onTap: () {
              //to do: open image picker and update profile picture
            }
          ),
          const Divider(height: 1),
          ListTile(
            //to do: add more profile editing options
          )
        ]
      )
    );
  }
}
