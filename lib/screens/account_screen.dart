import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart'; // for memoirTheme

final user = FirebaseAuth.instance.currentUser;
final followers = FirebaseAuth.instance.currentUser;
final following = FirebaseAuth.instance.currentUser;
final memories = FirebaseAuth.instance.currentUser;

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: memoirTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: memoirTheme.onBackground,
            onPressed: () {}, // placeholder
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: PageScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            CircleAvatar(
              radius: 50,
              backgroundImage: const AssetImage('assets/profile_placeholder.png'),
              backgroundColor: memoirTheme.surface,
            ),
            const SizedBox(height: 10),
            Text(
              user?.displayName ?? "Guest User",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: memoirTheme.onBackground,
              ),
            ),
            const SizedBox(height: 12),

            // paltan later to dynamic
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statItem("Followers", "240"),
                _dotDivider(),
                _statItem("Following", "180"),
                _dotDivider(),
                _statItem("Memories", "56"),
              ],
            ),

            const SizedBox(height: 30),

            // 📅 Activity preview placeholder
            GestureDetector(
              onTap: () {
                // TODO: navigate to calendar screen later
              },
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: memoirTheme.surface.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: memoirTheme.outline.withOpacity(0.2),
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Activity Preview (coming soon)",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 🧾 Placeholder for additional info
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: memoirTheme.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  "More profile content here...",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 60),

            // 🚪 Log Out button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // TODO: implement logout logic later
              },
              child: const Text(
                "Log Out",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: memoirTheme.onBackground,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: memoirTheme.onSurface),
        ),
      ],
    );
  }

  Widget _dotDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Text("•", style: TextStyle(color: Colors.grey, fontSize: 20)),
    );
  }
}
