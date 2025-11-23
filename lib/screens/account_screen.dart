import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'settings_screen.dart';
import '../app_theme.dart'; // for memoirTheme
import '../processes/auth.dart';
import '../objects/globals.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../processes/storage_service.dart';
import '../processes/database_service.dart';
import '../skeletons/profile_skeleton.dart';

class AccountScreen extends StatefulWidget {
  final String? uid; // UID passed through navigation

  // final user = FirebaseAuth.instance.currentUser;

  const AccountScreen({super.key, this.uid});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final StorageService _storageService = StorageService();
  final DatabaseService _databaseService = DatabaseService();
  final SupabaseClient _supabase = Supabase.instance.client;

  late final String _userId;

  bool _isLoading = true;
  String _username = "Loading...";
  String? _profilepictureUrl;
  int _followerCount = 0;
  int _followingCount = 0;
  int _memoryCount = 0;
  String? _errorMessage;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    _userId = widget.uid ?? currentUser?.uid ?? '';
    _loadProfileData();
    _isFollowing = followedUsers.contains(widget.uid);
  }

  Future<void> _uploadFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File imageFile = File(image.path);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uploading image...")),
      );

      String? imageUrl = await _storageService.uploadProfileImage(imageFile);

      if (imageUrl != null) {
        final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
        await _databaseService.updateUserAvatar(currentUserId, imageUrl);
        
        if (mounted) {
          setState(() {
            // Only add timestamp when actually uploading a new image
            // Store the base URL without timestamp
            _profilepictureUrl = imageUrl;
          });
          
          // Clear the image cache for this URL to force reload of the new image
          NetworkImage(imageUrl).evict();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile picture updated successfully.")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to upload image.")),
          );
        }
      }
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap (
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  // _uploadFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadProfileData() async {
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
    // ✅ Get username safely
    final username = await databaseService.getUserName(_userId);

    // ✅ Get other counts
    final results = await Future.wait([
      databaseService.getFollowerCount(_userId),
      databaseService.getFollowingCount(_userId),
      databaseService.getMemoryCount(_userId),
    ]);

    try {
      final userData = await _supabase
          .from('user')
          .select('profile_pic_url')
          .eq('uid', _userId)
          .maybeSingle();

      if (userData != null && userData['profile_pic_url'] != null) {
        setState(() {
          _profilepictureUrl = userData['profile_pic_url'];
        });
      }
    } catch (imgError) {
      debugPrint("Could not load profile image: $imgError");
    }

    await Future.delayed(Duration(milliseconds: 200));

    if (mounted) {
      setState(() {
        _username = username ?? "Unknown User";
        _followerCount = results[0] as int? ?? 0;
        _followingCount = results[1] as int? ?? 0;
        _memoryCount = results[2] as int? ?? 0;
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
    final bool isOwnProfile = (currentUser != null) && (_userId == currentUser.uid);

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
              onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
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

                GestureDetector(
                  onTap: isOwnProfile ? _showPickerOptions : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: memoirTheme.surface,
                        // Logic: If URL exists, use NetworkImage, else use Asset
                        backgroundImage: _profilepictureUrl != null
                            ? NetworkImage(_profilepictureUrl!) as ImageProvider
                            : const AssetImage('assets/temp.png'),
                      ),
                      // Optional: Add a small camera icon overlay for better UX
                      if (isOwnProfile)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: memoirTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: memoirTheme.background, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
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
                    GestureDetector(
                      onTap: () {
                        if (!isOwnProfile) return;
                        Navigator.pushNamed(
                          context,
                          '/followers-following',
                          arguments: [_userId, 0], // Pass the profile's userId
                        );
                      },
                      child: _statItem("Followers", _followerCount.toString()),
                    ),
                    _dotDivider(),
                    GestureDetector(
                      onTap: () {
                        if (!isOwnProfile) return;
                        Navigator.pushNamed(
                          context,
                          '/followers-following',
                          arguments: [_userId, 1],
                        );
                      },
                      child: _statItem("Following", _followingCount.toString()),
                    ),
                    _dotDivider(),
                    _statItem("Memories", _memoryCount.toString()),
                  ],
                ),


                const SizedBox(height: 20),

                // Follow button - only show on other users' profiles
                if (!isOwnProfile)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: memoirTheme.tertiary,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:() async {
                      if (_isFollowLoading) {return;}

                      _isFollowLoading = true;
                      bool value = await databaseService.toggleFollow(_userId);
                      setState(() {
                        _loadProfileData();
                        _isFollowing = value;
                      });
                      await Future.delayed(Duration(milliseconds: 500));
                      _isFollowLoading = false;

                      setState(() {
                        
                      });

                      refreshFriendsAndFollowers();
                      
                      
                    },
                    child: SizedBox(
                      height: 24,
                      width: 80,
                      child: _isFollowLoading ?
                      Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: Colors.white,
                          ),
                        ),
                      ) : 
                      Center(child: Text(
                        _isFollowing ? "Unfollow" : "Follow",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      )),
                    )
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
                      toggleLoading(true);
                      await logOut();
                      await Future.delayed(Duration(milliseconds: 500));
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
            ProfileSkeleton(),

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
    return Container(
      color: Colors.transparent,
      child: Column(
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
      ),
    );
  }

  Widget _dotDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Text("•", style: TextStyle(color: Colors.grey, fontSize: 20)),
    );
  }
}