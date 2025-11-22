import 'package:flutter/material.dart';
import '../processes/database_service.dart';
import '../models/user_model.dart';

class FollowersFollowingScreen extends StatefulWidget {
  final String uid; // NEW

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
    followers =
        await DatabaseService().getFollowersDetailed(widget.uid);
    setState(() => loadingFollowers = false);
  }

  Future<void> loadFollowing() async {
    following =
        await DatabaseService().getFollowingDetailed(widget.uid);
    setState(() => loadingFollowing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connections"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Followers"),
            Tab(text: "Following"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          loadingFollowers
              ? const Center(child: CircularProgressIndicator())
              : buildUserList(followers),
          loadingFollowing
              ? const Center(child: CircularProgressIndicator())
              : buildUserList(following),
        ],
      ),
    );
  }

  Widget buildUserList(List<UserModel> users) {
    if (users.isEmpty) {
      return const Center(child: Text("No users found"));
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                user.profilePic != null ? NetworkImage(user.profilePic!) : null,
            child: user.profilePic == null ? const Icon(Icons.person) : null,
          ),
          title: Text(user.username),
          subtitle: Text(user.fullName ?? ""),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/account',
              arguments: user.id,
            );
          },
        );
      },
    );
  }
}
