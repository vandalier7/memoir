import 'package:flutter/material.dart';
import 'map_body.dart';
import 'objects/map_buttons.dart';
import 'objects/search_bar.dart';
import 'objects/memory.dart';
import 'objects/memory_card.dart';

class MyScaffold extends StatefulWidget {
  const MyScaffold({super.key});

  @override
  State<MyScaffold> createState() => MyState();
}

class MyState extends State<MyScaffold> {
  MemoryData? activeMemory;
  bool isClosing = false;

  final _textFocusNode = FocusNode();

  void showMemory(MemoryData memory) {
    setState(() {
      activeMemory = memory;
      isClosing = false;
    });
  }

  void closeMemory() {
    setState(() {
      isClosing = true;
    });
  }

  void setMemoryInactive() {
    setState(() {
      activeMemory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        final currentFocus = FocusScope.of(context);
        if (_textFocusNode.hasFocus) {
          // check if tap is outside text field
          final renderBox = _textFocusNode.context?.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final offset = renderBox.localToGlobal(Offset.zero);
            final size = renderBox.size;
            final rect = offset & size;
            if (rect.contains(event.position)) return;
          }
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            MapBody(
              propagateMemory: showMemory,
              closeMemory: closeMemory,
            ),

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
            SearchBarWidget(focusNode: _textFocusNode),

            const MapButtons(),

            // 🧠 Memory card overlay
            if (activeMemory != null)
              MemoryCard(
                description: activeMemory!.description ?? "",
                imageUrl: activeMemory!.imageUrl ?? "",
                addressString: activeMemory!.addressString,
                borderColor: const Color.fromARGB(255, 219, 198, 9),
                borderWidth: 2,
                onClose: () => setMemoryInactive(),
                isClosing: isClosing,
              ),
          ],
        ),
      ),
    );
  }
}
