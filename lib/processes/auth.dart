import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart'; 
import '../objects/globals.dart';




// Sign up
Future<void> registerUser(String username, String email, String password) async {
  try {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    debugPrint('User created in Firebase');

    await databaseService.recordUser(
      FirebaseAuth.instance.currentUser!.uid, 
      email
    );
    
    debugPrint('User recorded in Supabase');

    storageService.listenUserMemories();

    debugPrint('✅ Registered successfully');
  } catch (e) {
    debugPrint('❌ Registration error: $e');
    rethrow;
  }
}

Future<void> loginUser(String email, String password) async {
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    debugPrint('Logged in to Firebase');

    bool hasUser = await databaseService.isUserRecorded(
      FirebaseAuth.instance.currentUser!.uid
    );

    debugPrint('User exists in Supabase: $hasUser');

    if (!hasUser) {
      await databaseService.recordUser(
        FirebaseAuth.instance.currentUser!.uid, 
        email
      );
      debugPrint('User recorded in Supabase');
    }

    storageService.listenUserMemories();

    debugPrint('✅ Logged in successfully');
  } catch (e) {
    debugPrint('❌ Login error: $e');
    rethrow;
  }
}

Future<void> logOut() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  storageService.dispose();
  await FirebaseAuth.instance.signOut();
}