import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'my_scaffold.dart';
import 'map_body.dart';
import 'screens/sign_in.dart';
import 'app_theme.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 

import 'objects/globals.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before the app runs
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  MapLibreMap.useHybridComposition = true;
  runApp(Root());
}

class Root extends StatelessWidget {
    const Root({super.key});

    @override
  Widget build(BuildContext context) {
    pixelRatio = MediaQuery.of(context).devicePixelRatio;
    return MaterialApp(
      theme: ThemeData(
        colorScheme: memoirTheme
      ),
      debugShowCheckedModeBanner: false,
      title: "Memoir",
       home: MyScaffold(),
    );
  }
}


class FirebaseCheckScreen extends StatelessWidget {
  const FirebaseCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder(
          future: Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return const Text(
                '✅ Firebase connected successfully!',
                style: TextStyle(fontSize: 18),
              );
            } else if (snapshot.hasError) {
              return Text('❌ Firebase error: ${snapshot.error}');
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}