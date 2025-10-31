import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'my_scaffold.dart';
import 'map_body.dart';
import 'screens/sign_in.dart';
import 'app_theme.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'package:firebase_auth/firebase_auth.dart' as fbauth;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'processes/auth.dart';

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

  registerUser("Test User", "a@joke.com", "1234qweQ");


  MapLibreMap.useHybridComposition = true;
  runApp(Root());
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {    
    return MaterialApp(
      theme: ThemeData(
        colorScheme: memoirTheme
      ),
      debugShowCheckedModeBanner: false,
      title: "Memoir",
      home: StreamBuilder<fbauth.User?>(
        stream: fbauth.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const BinScreen();
          } 
          else {
            return SignInCard();
          }
        },
      ),
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
