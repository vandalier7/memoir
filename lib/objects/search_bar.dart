import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../app_theme.dart'; // for memoirTheme colors
import '../screens/account_screen.dart';
=======
import '../../app_theme.dart'; // adjust path if needed
import '../screens/account_screen.dart';// ✅ added this import for navigation
>>>>>>> account-settings

class SearchBarWidget extends StatelessWidget {
  final FocusNode? focusNode;

  const SearchBarWidget({super.key, this.focusNode});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top; // for notch/status bar

    return Positioned(
      top: topPadding + 10,
      left: screenWidth * 0.02,
      right: screenWidth * 0.02,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 🔍 SEARCH BAR
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                // 🔤 Search field
                Expanded(
                  child: TextField(
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      hintText: "Search",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                // 👤 Account button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
<<<<<<< HEAD
                        context,
                        MaterialPageRoute(builder: (context) => const AccountScreen()),
                      );
=======
                      context,
                      MaterialPageRoute(builder: (context) => const AccountScreen()),
                    );
>>>>>>> account-settings
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: memoirTheme.primary.withOpacity(0.8),
                      child: Icon(Icons.account_circle,
                          color: memoirTheme.onPrimary, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ✨ FILTERS BUTTON (aligned right)
          GestureDetector(
            onTap: () {
              debugPrint("Filters button tapped");
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: memoirTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.layers, size: 15, color: memoirTheme.onSurface),
                  const SizedBox(width: 6),
                  Text(
                    "Filters",
                    style: TextStyle(
                      color: memoirTheme.onSurface,
                      fontWeight: FontWeight.w400,
                      fontSize: 13
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
}
