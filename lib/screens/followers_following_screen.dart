import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../processes/database_service.dart';
import '../models/user_model.dart';
import '../app_theme.dart';
import 'package:presentation/objects/globals.dart';

class FollowersFollowingScreen extends StatefulWidget {
  final String uid;

  const FollowersFollowingScreen({super.key, required this.uid});

  @override
  _FollowersFollowingScreenState createState() => _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> followers = [];
  List<UserModel> following = [];
  bool loadingFollowers = true;
  bool loadingFollowing = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadFollowers();
    loadFollowing();
  }

  Future<void> loadFollowers() async {
    followers = await DatabaseService().getFollowersDetailed(widget.uid);
    setState(() => loadingFollowers = false);
  }

  Future<void> loadFollowing() async {
    following = await DatabaseService().getFollowingDetailed(widget.uid);
    setState(() => loadingFollowing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: memoirTheme.background,
      appBar: AppBar(
        backgroundColor: memoirTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: memoirTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Connections",
          style: TextStyle(
            color: memoirTheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: memoirTheme.tertiary,
            indicatorWeight: 2,
            labelColor: memoirTheme.tertiary,
            unselectedLabelColor: memoirTheme.onSurface.withValues(alpha: 0.5),
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Followers"),
                    if (!loadingFollowers) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: memoirTheme.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${followers.length}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: memoirTheme.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Following"),
                    if (!loadingFollowing) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: memoirTheme.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${following.length}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: memoirTheme.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          loadingFollowers
              ? Center(
                  child: CircularProgressIndicator(color: memoirTheme.tertiary),
                )
              : buildUserList(followers),
          loadingFollowing
              ? Center(
                  child: CircularProgressIndicator(color: memoirTheme.tertiary),
                )
              : buildUserList(following),
        ],
      ),
    );
  }

  Widget buildUserList(List<UserModel> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: memoirTheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "No users found",
              style: TextStyle(
                color: memoirTheme.onSurface.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: memoirTheme.outline.withValues(alpha: 0.2),
        indent: 76,
      ),
      itemBuilder: (context, index) {
        final user = users[index];
        return InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/account',
              arguments: user.id,
            ).then((_) {
              // Reload when coming back
              if (mounted) {
                setState(() {
                  loadingFollowers = true;
                  loadingFollowing = true;
                });
                loadFollowers();
                loadFollowing();
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: memoirTheme.tertiary.withValues(alpha: 0.2),
                  backgroundImage: user.profilePic != ""
                      ? CachedNetworkImageProvider(user.profilePic!)
                      : const AssetImage('assets/temp.png') as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: TextStyle(
                          color: memoirTheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.fullName != null && user.fullName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.fullName!,
                          style: TextStyle(
                            color: memoirTheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: memoirTheme.onSurface.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}