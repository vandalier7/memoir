// import 'package:presentation/processes/notifications_service.dart';
import 'package:flutter/material.dart';
// import 'dart:async';

import '../app_theme.dart';

// import 'package:presentation/my_scaffold.dart';
// import 'package:presentation/objects/globals.dart';

class FeedButton extends StatelessWidget {
  const FeedButton ({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
                    margin: EdgeInsets.only(left: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 238, 106, 130),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.local_fire_department,
                      size: 24,
                      color: memoirTheme.onTertiary,
                    ),
                  );
  }
}