import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'my_scaffold.dart';
import 'map_body.dart';
import 'screens/sign_in.dart';
import 'app_theme.dart';

import './objects/map_buttons.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbauth;
import 'firebase_options.dart'; 
import 'processes/locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'processes/auth.dart';

import 'objects/globals.dart';

import 'screens/bin_screen.dart';
void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before the app runs
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: 'https://drnpxydotpjbxigrnlli.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRybnB4eWRvdHBqYnhpZ3JubGxpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2NjcwOTMsImV4cCI6MjA3NzI0MzA5M30.jMuA5DoAbWz-WCfcyqg6ndPy1pkxMUXOutj3UbGTptg',
  );

  loginUser("a@test.com", "1234Test");


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
      // Directly show the main map screen wrapper (MyScaffold)
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
