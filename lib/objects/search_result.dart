import 'package:flutter/material.dart';
import '../app_theme.dart';

enum SearchResultType { user, place }

class SearchResultElement extends StatelessWidget {
  final SearchResultType type;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String id; // ID for navigation (userId or placeId)
  final VoidCallback? onTapCallback; // Optional additional callback

  const SearchResultElement({
    super.key,
    required this.type,
    required this.title,
    required this.id,
    this.subtitle,
    this.imageUrl,
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
      imageUrl: avatarUrl,
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
      imageUrl: photoUrl,
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
    // Call optional callback first
    onTapCallback?.call();
    
    // Handle navigation based on type
    switch (type) {
      case SearchResultType.user:
        Navigator.pushNamed(context, '/user-profile', arguments: id);
        break;
      case SearchResultType.place:
        Navigator.pushNamed(context, '/place-details', arguments: id);
        break;
    }
  }

  Widget _buildLeading() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: _iconColor.withOpacity(0.2),
        backgroundImage: NetworkImage(imageUrl!),
        onBackgroundImageError: (_, __) {},
        child: const SizedBox(), // Shows background color if image fails
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: _iconColor.withOpacity(0.2),
      child: Icon(
        _leadingIcon,
        size: 22,
        color: _iconColor,
      ),
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