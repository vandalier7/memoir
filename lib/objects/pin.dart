import 'package:flutter/material.dart';

class UserPin extends StatelessWidget {
  final Size size;
  final Color color;
  final String addressString;

  const UserPin({
    super.key, 
    this.size = const Size(50, 50),
    this.color = Colors.white,
    required this.addressString
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        Image.asset(
          'assets/sprites/basePin.png',
          color: color,
          width: size.width,
          height: size.height,  
        ),
        SizedBox(width: 150, height: 30, child: Text(addressString, textAlign: TextAlign.center, style: TextStyle(overflow: TextOverflow.ellipsis),),)
      ],
    );
  }
}