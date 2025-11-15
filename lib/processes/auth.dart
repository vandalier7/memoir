import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart'; 
import '../objects/globals.dart';




// Sign up
Future<void> registerUser(String username, String email, String password) async {

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  storageService.listenUserMemories();
  debugPrint('✅ Registered successfully');

}

// Sign in
Future<void> loginUser(String email, String password) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
  storageService.listenUserMemories();

  debugPrint('✅ Logged in successfully');
}

Future<void> logOut() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  storageService.dispose();
  await FirebaseAuth.instance.signOut();
}