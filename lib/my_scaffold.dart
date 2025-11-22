//my_scaffold
import 'package:flutter/material.dart';
import 'map_body.dart';
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

  final _textFocusNode = FocusNode();
  final _searchBarKey = GlobalKey(); // Add this key

  final String currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

  void showMemory(List<MemoryData> memories, MemoryData selected, int index) {
    setState(() {
      activeMemories = memories;
      selectedMemory = selected;
      isClosing = false;
      activeMemoryIndex = index;
    });
  }

  void retryLocation() {
    _mapKey.currentState?.getLocation();
  }

  void closeMemory() {
    setState(() {
      isClosing = true;
    });
  }

  void setMemoryInactive() {
    setState(() {
      activeMemories = null;
      selectedMemory = null;
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
            SearchBarWidget(focusNode: _textFocusNode, key: _searchBarKey,),

            MapButtons(
              onRetryLocation: retryLocation,
              onPanToLocation: () => _mapKey.currentState?.panToCurrentPosition(),
              showLocationError: _mapKey.currentState?.showLocationError ?? false,
              ),

            // 🧠 Memory card overlay
            if (activeMemories != null)
              MemoryCard(
                memories: activeMemories!,
                selectedMemory: selectedMemory!,
                onClose: () => setMemoryInactive(),
                isClosing: isClosing,
                initialIndex: activeMemoryIndex,
              ),
          ],
        ),
      ),
    );
  }
}
