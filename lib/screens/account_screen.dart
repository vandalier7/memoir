import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart'; // for memoirTheme
import '../processes/auth.dart';
import '../objects/globals.dart';

class AccountScreen extends StatefulWidget {
  final String? uid; // UID passed through navigation

  const AccountScreen({super.key, this.uid});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isLoading = true;
  String _username = "Loading...";
  int _followerCount = 0;
  int _followingCount = 0;
  int _memoryCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    // _isLoading = true;
    final currentUser = FirebaseAuth.instance.currentUser;
    final String profileUid = widget.uid ?? currentUser?.uid ?? '';

    if (profileUid.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "No user ID available";
      });
      return;
    }

    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        databaseService.getActiveUsername(profileUid),
        databaseService.getFollowerCount(profileUid),
        databaseService.getFollowingCount(profileUid),
        databaseService.getMemoryCount(profileUid),
      ]);

      if (mounted) {
        setState(() {
          _username = results[0] as String? ?? "Unknown User";
          _followerCount = results[1] as int? ?? 0;
          _followingCount = results[2] as int? ?? 0;
          _memoryCount = results[3] as int? ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load profile";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String profileUid = widget.uid ?? currentUser?.uid ?? '';
    final bool isOwnProfile = profileUid == currentUser?.uid;

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
          // Only show settings button on own profile
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              color: memoirTheme.onBackground,
              onPressed: () {}, // placeholder
            ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            physics: const PageScrollPhysics(),
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
                  _username,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: memoirTheme.onBackground,
                  ),
                ),
                const SizedBox(height: 12),

                // Dynamic stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statItem("Followers", _followerCount.toString()),
                    _dotDivider(),
                    _statItem("Following", _followingCount.toString()),
                    _dotDivider(),
                    _statItem("Memories", _memoryCount.toString()),
                  ],
                ),

                const SizedBox(height: 20),

                // Follow button - only show on other users' profiles
                if (!isOwnProfile)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: memoirTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await databaseService.toggleFollow(profileUid);
                      setState(() {
                        _loadProfileData();
                      });
                    },
                    child: const Text(
                      "Follow",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
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

                // 🚪 Log Out button - only show on own profile
                if (isOwnProfile)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await logOut();
                      if (!context.mounted) return;
                      Navigator.pushNamed(context, '/sign-in');
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

          // Loading overlay
          if (_isLoading)
            Container(
              color: memoirTheme.background.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: memoirTheme.primary,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Loading profile...",
                      style: TextStyle(
                        color: memoirTheme.onBackground,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error overlay
          if (_errorMessage != null && !_isLoading)
            Container(
              color: memoirTheme.background.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: memoirTheme.onBackground,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _loadProfileData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: memoirTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text(
                        "Retry",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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