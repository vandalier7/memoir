import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {

  final void Function()? onPressed;
  final Widget? child;
  const PrimaryButton({
    super.key, 
    this.onPressed, 
    this.child
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed, 
      
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),

      child: child,
      );
  }
}