//my_scaffold
import 'package:flutter/material.dart';
import 'map_body.dart';
import 'package:presentation/objects/globals.dart';
import 'objects/map_buttons.dart';
import 'objects/search_bar.dart';
import 'objects/memory.dart';
import 'objects/memory_card.dart';
import 'screens/loading_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../processes/database_service.dart';
import 'screens/account_screen.dart';

class MyScaffold extends StatefulWidget {
  const MyScaffold({super.key});

  @override
  State<MyScaffold> createState() => MyState();
}

class MyState extends State<MyScaffold> {
  final GlobalKey<MapState> _mapKey = GlobalKey<MapState>();
  List<MemoryData>? activeMemories;
  MemoryData? selectedMemory;
  bool isClosing = false;
  int activeMemoryIndex = 0;
  int? targetCommentId;
  int _memoryCardKey = 0;
  bool hasActiveMemory = false;
  bool showFeed = false;
  int feedIndex = 0;

  final _textFocusNode = FocusNode();
  final _searchBarKey = GlobalKey(); // Add this key

  final String currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

  void updateFeedIndex(int index) {
    feedIndex = index;
  }

  void showFeedView(bool value) {
    setState(() {
      showFeed = value;
      if (value) {
        isClosing = false;
        hasActiveMemory = false;
        activeMemories = null;
        selectedMemory = null;
      }
    });
  }

  void showMemory(List<MemoryData> memories, MemoryData selected, int index) {
    setState(() {
      activeMemories = memories;
      hasActiveMemory = true;
      selectedMemory = selected;
      isClosing = false;
      activeMemoryIndex = index;
      showFeed = false;
    });
  }

  void retryLocation() {
    _mapKey.currentState?.getLocation();
  }

  void closeMemory() async {
    setState(() {
      isClosing = true;
    });
    
  }

  void navigateToMemory(int supabaseMemoryId, {int? commentId}) async {
    try {
      print('🧭 Navigating to memory with ID: $supabaseMemoryId, commentId: $commentId');

      // Get all memories at the same location
      final memoriesAtLocation = getMemoriesAtSameLocation(supabaseMemoryId);

      if (memoriesAtLocation == null || memoriesAtLocation.isEmpty) {
        print('❌ Memory not found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Memory not found or not loaded yet'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Find the specific memory
      final targetMemory = memoriesAtLocation.firstWhere(
        (m) => m.supabaseMemoryId == supabaseMemoryId,
      );

      // Get the index
      final index = getMemoryIndex(memoriesAtLocation, supabaseMemoryId);

      if (index == -1) {
        print('❌ Memory index not found');
        return;
      }

      print('✅ Found memory at index $index with ${memoriesAtLocation.length} total memories at location');

      // ✅ KEY FIX: If MemoryCard is already open, close it first and increment key
      if (activeMemories != null) {
        setState(() {
          activeMemories = null;
          selectedMemory = null;
          targetCommentId = null;
          _memoryCardKey++; // Force new widget instance
        });
        // Wait for the old card to be disposed
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Animate camera to the memory
      await _mapKey.currentState?.animateCameraWithOffset(
        target: targetMemory.position,
        showPreviewAfter: false,
        // yOffsetPixels: 200, DEFAULTED
      );

      // Wait for camera animation
      // await Future.delayed(const Duration(milliseconds: 400));

      // Show the memory card with the target comment
      if (mounted) {
        setState(() {
          targetCommentId = commentId;
          activeMemories = memoriesAtLocation;
          selectedMemory = targetMemory;
          isClosing = false;
          hasActiveMemory = true;
          activeMemoryIndex = index;
        });
      }

      print('🎉 Navigation complete');
    } catch (e) {
      print('❌ Error navigating to memory: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening memory: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void setMemoryInactive() async {
    setState(() {
      activeMemories = null;
      selectedMemory = null;
      targetCommentId = null;
    });
    await Future.delayed(Duration(milliseconds: 50));
    setState(() {
      hasActiveMemory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        final currentFocus = FocusScope.of(context);
        if (_textFocusNode.hasFocus) {
          // Check if tap is inside TextField
          final textFieldRenderBox = _textFocusNode.context?.findRenderObject() as RenderBox?;
          if (textFieldRenderBox != null) {
            final offset = textFieldRenderBox.localToGlobal(Offset.zero);
            final size = textFieldRenderBox.size;
            final rect = offset & size;

            if (rect.contains(event.position)) {
              return; // Tapped on TextField
            }
          }

          // Check if tap is inside SearchBar widget (includes results)
          final searchBarRenderBox = _searchBarKey.currentContext?.findRenderObject() as RenderBox?;
          if (searchBarRenderBox != null) {
            final offset = searchBarRenderBox.localToGlobal(Offset.zero);
            final size = searchBarRenderBox.size;
            final rect = offset & size;

            if (rect.contains(event.position)) {
              return; // Tapped on SearchBar area (including results)
            }
          }

          // Tapped outside → unfocus
          currentFocus.unfocus();
          _textFocusNode.unfocus();
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            MapBody(
              key: _mapKey,
              propagateMemory: showMemory,
              closeMemory: closeMemory,
            ),
            // IgnorePointer(
            //   child: Container(
            //     decoration: BoxDecoration(
            //       gradient: RadialGradient(
            //         center: AlignmentGeometry.xy(0, 0.075),
            //         radius: 1.0,
            //         colors: [
            //           Colors.transparent,
            //           Colors.black.withValues(alpha: 0.15),
            //           Colors.black.withValues(alpha: 0.3),
            //         ],
            //         stops: [0.7, 0.9, 1.0],
            //       ),
            //     ),
            //   ),
            // ),
            // SearchBarWidget(
            //   key: _searchBarKey, // Add the key here
            //   focusNode: _textFocusNode,
            // ),
            // const MapButtons(),

            // 🌫 Gradient overlay
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: AlignmentGeometry.xy(0, 0.075),
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.3),
                    ],
                    stops: [0.7, 0.9, 1.0],
                  ),
                ),
              ),
            ),

            // ✅ Single, clean search bar
            SearchBarWidget(focusNode: _textFocusNode, key: _searchBarKey, hasActiveMemory: hasActiveMemory, showFeed: showFeedView,),

            MapButtons(
              onRetryLocation: retryLocation,
              onPanToLocation: () => _mapKey.currentState?.panToCurrentPosition(),
              showLocationError: _mapKey.currentState?.showLocationError ?? false,
              ),

            // 🧠 Memory card overlay
            if (activeMemories != null && !showFeed)
              MemoryCard(
                key: ValueKey('memory_card_$_memoryCardKey'),
                memories: activeMemories!,
                selectedMemory: selectedMemory!,
                onClose: () => setMemoryInactive(),
                isClosing: isClosing,
                initialIndex: activeMemoryIndex,
                targetCommentId: targetCommentId,
              ),
            if (activeMemories == null && showFeed)
              MemoryCard(
                // key: ValueKey('memory_card_$_memoryCardKey'),
                memories: unfilteredMemories,
                selectedMemory: unfilteredMemories[0],
                onClose: () => showFeedView(false),
                isClosing: isClosing,
                initialIndex: feedIndex,
                updateFeedIndex: updateFeedIndex,
                asFeed: true,
                onAnimateCamera: _mapKey.currentState?.animateCameraWithOffset,
              ),
          ],
        ),
      ),
    );
  }
}
