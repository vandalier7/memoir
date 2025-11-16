import 'package:flutter/material.dart';
import 'dart:async';
import '../app_theme.dart';
import '../screens/account_screen.dart';
import 'search_result.dart';
import 'globals.dart';

class SearchBarWidget extends StatefulWidget {
  final FocusNode? focusNode;

  const SearchBarWidget({super.key, this.focusNode});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late FocusNode _internalFocusNode;
  bool _isFocused = false;
  final TextEditingController _searchController = TextEditingController();
  bool _shouldPreventFocus = false;

  // User search results from database
  List<Map<String, dynamic>> _userResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  String _lastSearchQuery = ''; // Cache last query

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_onFocusChange);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Unfocus when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shouldPreventFocus && _internalFocusNode.hasFocus) {
        _internalFocusNode.unfocus();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _internalFocusNode.removeListener(_onFocusChange);
    _searchController.removeListener(_onSearchChanged);
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_shouldPreventFocus && _internalFocusNode.hasFocus) {
      // Immediately unfocus if we're preventing focus
      _internalFocusNode.unfocus();
      return;
    }
    
    setState(() {
      _isFocused = _internalFocusNode.hasFocus;
    });
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    final currentQuery = _searchController.text.trim();
    
    // Clear results if search is empty
    if (currentQuery.isEmpty) {
      if (_lastSearchQuery.isNotEmpty || _userResults.isNotEmpty || _isSearching) {
        setState(() {
          _userResults = [];
          _isSearching = false;
          _lastSearchQuery = '';
        });
      }
      return;
    }

    // If query hasn't changed and we have cached results, don't search again
    if (currentQuery == _lastSearchQuery && _userResults.isNotEmpty) {
      return;
    }

    // Only show loading if not already loading
    if (!_isSearching) {
      setState(() {
        _isSearching = true;
      });
    }

    // Set new timer for 500ms debounce
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(currentQuery);
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await databaseService.searchByUsername(query);
      
      if (mounted) {
        setState(() {
          _userResults = results;
          _isSearching = false;
          _lastSearchQuery = query; // Cache the query
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _userResults = [];
          _isSearching = false;
          _lastSearchQuery = ''; // Clear cache on error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 10,
      left: screenWidth * 0.02,
      right: screenWidth * 0.02,
      child: GestureDetector(
        // Prevent parent GestureDetector from unfocusing when tapping search UI
        onTap: () {},
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
                      controller: _searchController,
                      focusNode: _internalFocusNode,
                      enableInteractiveSelection: true,
                      decoration: const InputDecoration(
                        hintText: "Search users",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  // 👤 Account button
                  GestureDetector(
                    onTap: () {
                      // Remove focus completely
                      FocusScope.of(context).unfocus();
                      _internalFocusNode.unfocus();
                      
                      // Set flag to prevent refocus and clear focused state
                      setState(() {
                        _shouldPreventFocus = true;
                        _isFocused = false;
                      });
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AccountScreen()),
                      ).then((_) {
                        // When returning, ensure focus is cleared and keep prevention flag
                        FocusScope.of(context).unfocus();
                        // Reset flag after a brief delay
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            setState(() {
                              _shouldPreventFocus = false;
                            });
                          }
                        });
                      });
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

            // ✨ SEARCH RESULTS CARD (appears when focused and has results)
            if (_isFocused && (_userResults.isNotEmpty || _isSearching))
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _isSearching
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: memoirTheme.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _userResults.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            indent: 56,
                            color: Colors.grey.withOpacity(0.2),
                          ),
                          itemBuilder: (context, index) {
                            final user = _userResults[index];
                            final username = user['username'] ?? 'Unknown';
                            final userId = user['uid'];
                            final avatarUrl = user['avatar_url'];
                            final bio = user['bio']; // Optional bio field
                            
                            return SearchResultElement.user(
                              userId: userId,
                              username: username,
                              bio: bio,
                              avatarUrl: avatarUrl,
                              onTapCallback: () {
                                _internalFocusNode.unfocus();
                                debugPrint('Selected user: $username (ID: $userId)');
                              },
                            );
                          },
                        ),
                      ),
              ),

            // Show "No results" message when search is complete but empty
            if (_isFocused && 
                !_isSearching && 
                _userResults.isEmpty && 
                _searchController.text.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
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
                    Icon(
                      Icons.search_off,
                      color: Colors.grey.withOpacity(0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'No users found',
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

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
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}