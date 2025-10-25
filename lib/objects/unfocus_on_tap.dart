import 'package:flutter/material.dart';

class UnfocusOnTap extends StatelessWidget {
  final Widget child;
  const UnfocusOnTap({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: child,
    );
  }
}
