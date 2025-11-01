import 'package:flutter/material.dart';
import 'map_body.dart';
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
      // get RenderBox for TextField
      final renderBox = _textFocusNode.context?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final offset = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        final rect = offset & size; // rectangle of the TextField

        // check if tap is inside
        if (rect.contains(event.position)) {
          // tapped on TextField itself → do nothing
          return;
        }
      }
      // tapped outside → unfocus
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
            closeMemory: closeMemory
          )
          ,       
          IgnorePointer( // so touches go to the map
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: AlignmentGeometry.xy(0, 0.075),
            radius: 1.0,
            colors: [
              Colors.transparent,   // center is clear
              Colors.black.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.3),
            ],
            stops: [0.7, 0.9, 1.0],
            
          ),
        ),
      ),
    ),
          Container(
            margin: EdgeInsets.fromLTRB(10, 40, 10, 0),
            child: TextField(
              focusNode: _textFocusNode,
              decoration: InputDecoration(
                hintText: "Search",
                hintStyle: TextStyle(
                  color: Colors.grey
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide.none
                ),
                suffixIcon: Container(
                  child: CircleAvatar(),
                  margin: EdgeInsets.fromLTRB(0, 0, 12, 0),
                ),
                fillColor: Colors.white
              )
              
            )),
            if (activeMemory != null)
              MemoryCard(
                description: "Lorem ipsum dolor sit amet.",
                addressString: activeMemory!.addressString,
                borderColor: const Color.fromARGB(255, 219, 198, 9),
                borderWidth: 2,
                onClose: () => setMemoryInactive(),
                isClosing: isClosing,
              ),
        ],
      )
      
      
    ,
    )
    );
  }
}