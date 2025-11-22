import 'package:flutter/material.dart';
import 'package:presentation/objects/globals.dart';
import '../app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum SearchResultType { user, place }

class SearchResultElement extends StatelessWidget {
  final SearchResultType type;
  final String title;
  final String? subtitle;
  final String id; // ID for navigation (userId or placeId)
  final VoidCallback? onTapCallback; // Optional additional callback

  const SearchResultElement({
    super.key,
    required this.type,
    required this.title,
    required this.id,
    this.subtitle,
    this.onTapCallback,
  });

  // Factory constructors for convenience
  factory SearchResultElement.user({
    required String userId,
    required String username,
    String? bio,
    String? avatarUrl,
    VoidCallback? onTapCallback,
  }) {
    return SearchResultElement(
      type: SearchResultType.user,
      id: userId,
      title: username,
      subtitle: bio,
      onTapCallback: onTapCallback,
    );
  }

  factory SearchResultElement.place({
    required String placeId,
    required String placeName,
    String? address,
    String? photoUrl,
    VoidCallback? onTapCallback,
  }) {
    return SearchResultElement(
      type: SearchResultType.place,
      id: placeId,
      title: placeName,
      subtitle: address,
      onTapCallback: onTapCallback,
    );
  }

  IconData get _leadingIcon {
    switch (type) {
      case SearchResultType.user:
        return Icons.person;
      case SearchResultType.place:
        return Icons.place;
    }
  }

  Color get _iconColor {
    switch (type) {
      case SearchResultType.user:
        return memoirTheme.primary;
      case SearchResultType.place:
        return memoirTheme.secondary;
    }
  }

  void _handleTap(BuildContext context) {
    // Call the callback which handles all the logic
    // The callback itself will do the navigation
    onTapCallback?.call();
  }

  Widget _buildLeading() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: databaseService.getUserStream(id),
      builder: (context, snapshot) {
        String? avatarUrl;
        if (snapshot.hasData) {
          avatarUrl = snapshot.data!['profile_pic_url'];
        }

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // boxShadow: [
            //   BoxShadow(
            //     color: memoirTheme.outline,
            //     blurRadius: 0,
            //     spreadRadius: 3
            //   ),
            //   BoxShadow(
            //     color: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 1),
            //     blurRadius: 0,
            //     spreadRadius: 1
            //   ),
            // ]
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: memoirTheme.primary.withValues(alpha: 0.2), // Lighter bg behind image
            // If URL exists, use it. If not, show default icon.
            backgroundImage: avatarUrl != null 
                ?  CachedNetworkImageProvider("$avatarUrl")
                : null,
            child: avatarUrl == null 
                ? Icon(Icons.account_circle, color: memoirTheme.primary, size: 28)
                : null
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      leading: _buildLeading(),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: memoirTheme.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle != null && subtitle!.isNotEmpty
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: memoirTheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.withOpacity(0.5),
      ),
      onTap: () => _handleTap(context),
    );
  }
}