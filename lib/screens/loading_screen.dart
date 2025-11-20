import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  final bool ignoring;

  const LoadingScreen({super.key, required this.ignoring});
  
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: ignoring,
      child: AnimatedOpacity(
        opacity: ignoring ? 0.0 : 1.0, 
        duration: Duration(milliseconds: 500),
        child: Material(  // ✅ Add this
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Theme.of(context).canvasColor.withAlpha(255),
            child: Center(
              child: Text("Loading Screen..."),
            ),
          ),
        ),
      ),
    );
  }
}