import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart'; 




// Sign up
Future<void> registerUser(String username, String email, String password) async {

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    debugPrint('✅ Registered successfully');
  } on FirebaseAuthException catch (e) {
    debugPrint('❌ Register error: ${e.message}');
  }
}

// Sign in
Future<void> loginUser(String email, String password) async {

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    debugPrint('✅ Logged in successfully');
  } on FirebaseAuthException catch (e) {
    debugPrint('❌ Login error: ${e.message}and${email}and${password}');
  }
}
