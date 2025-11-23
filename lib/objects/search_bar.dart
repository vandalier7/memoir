import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ Added
import '../processes/database_service.dart'; // ✅ Added
import '../app_theme.dart';
import 'search_result.dart';
import 'globals.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  String _lastSearchQuery = '';

  // ✅ Get Current User ID for the Stream
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_onFocusChange);
    _searchController.addListener(_onSearchChanged);
  }

  // ... [Keep your existing dispose, didChangeDependencies, focus/search logic] ...
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shouldPreventFocus && _internalFocusNode.hasFocus) {
        _internalFocusNode.unfocus();
      }
      if (_shouldPreventFocus) {
        FocusScope.of(context).unfocus();
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
      _internalFocusNode.unfocus();
      return;
    }
    setState(() {
      _isFocused = _internalFocusNode.hasFocus;
    });
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    final currentQuery = _searchController.text.trim();
    
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

    if (currentQuery == _lastSearchQuery && _userResults.isNotEmpty) {
      return;
    }

    if (!_isSearching) {
      setState(() {
        _isSearching = true;
      });
    }

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
          _lastSearchQuery = query;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _userResults = [];
          _isSearching = false;
          _lastSearchQuery = '';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 🔍 SEARCH BAR
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95), // Updated from withOpacity
              borderRadius: BorderRadius.circular(200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
                      hintText: "Search",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                
                // 👤 ACCOUNT BUTTON (Updated to show Profile Picture)
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    _internalFocusNode.unfocus();
                    
                    setState(() {
                      _shouldPreventFocus = true;
                      _isFocused = false;
                    });
                    
                    Navigator.pushNamed(
                      context,
                      "/account",
                      arguments: storageService.currentUserId
                    ).then((_) {
                      FocusScope.of(context).unfocus();
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
                    padding: const EdgeInsets.only(right: 9),

                    // ✅ STREAM BUILDER HERE
                    child: StreamBuilder<Map<String, dynamic>>(
                      stream: DatabaseService().getUserStream(_currentUserId),
                      builder: (context, snapshot) {
                        String? avatarUrl;
                        if (snapshot.hasData) {
                          avatarUrl = snapshot.data!['profile_pic_url'];
                        }

                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: memoirTheme.outline,
                                blurRadius: 0,
                                spreadRadius: 3
                              ),
                              BoxShadow(
                                color: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 1),
                                blurRadius: 0,
                                spreadRadius: 1
                              ),
                            ]
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: memoirTheme.primary.withValues(alpha: 0.2), // Lighter bg behind image
                            // If URL exists, use it. If not, show default icon.
                            backgroundImage: avatarUrl != null 
                                ?  CachedNetworkImageProvider("$avatarUrl")
                                : const AssetImage('assets/temp.png'),

                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ✨ SEARCH RESULTS CARD
          if (_isFocused && (_userResults.isNotEmpty || _isSearching))
            // ... [Rest of your search results code remains exactly the same] ...
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
                        borderRadius: BorderRadius.circular(20),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          itemCount: _userResults.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            indent: 56,
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                          itemBuilder: (context, index) {
                            final user = _userResults[index];
                            return SearchResultElement.user(
                              userId: user['uid'],
                              username: user['username'] ?? 'Unknown',
                              bio: user['bio'],
                              avatarUrl: user['avatar_url'],
                              onTapCallback: () {
                                _internalFocusNode.unfocus();
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _shouldPreventFocus = true;
                                  _isFocused = false;
                                });
                                debugPrint('Selected user: ${user['username']}');
                                Navigator.pushNamed(
                                  context,
                                  "/account",
                                  arguments: user['uid']
                                ).then((_) {
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    if (mounted) {
                                      setState(() {
                                        _shouldPreventFocus = false;
                                      });
                                    }
                                  });
                                });
                              },
                            );
                          },
                        ),
                      ),
              ),
            ),

          // Show "No results" message
          if (_isFocused && !_isSearching && _userResults.isEmpty && _searchController.text.isNotEmpty)
             Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_off,
                    color: Colors.grey.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'No users found',
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Notification and Filter buttons row
          Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 🔔 NOTIFICATION BUTTON
            GestureDetector(
              onTap: () {
                //TODO: Navigator.pushNamed(context, '/notifications');
              },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: memoirTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    size: 18,
                    color: memoirTheme.onSurface,
                  ),
                ),
              ),
    
              const SizedBox(width: 8),
    
              // ✨ FILTERS BUTTON
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
                        color: Colors.black.withValues(alpha: 0.08),
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
        ],
      ),
    );
  }
}