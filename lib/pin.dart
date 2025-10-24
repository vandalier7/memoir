import 'package:flutter/material.dart';

class UserPin extends StatelessWidget {
  final Size size;
  final Color color;

  const UserPin({
    super.key, 
    this.size = const Size(50, 50),
    this.color = Colors.white
  });

  @override
  Widget build(BuildContext context) {

    return Image.asset(
      'assets/sprites/basePin.png',
      color: color,
      width: size.width,
      height: size.height,  
    );
  }
}