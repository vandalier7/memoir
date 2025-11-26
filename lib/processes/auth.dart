import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart'; 
import '../objects/globals.dart';




// Sign up
Future<void> registerUser(String username, String email, String password) async {
  try {

    bool isUsernameAvailable = await databaseService.isUsernameAvailable(username);
    if (!isUsernameAvailable) {
      throw FirebaseAuthException(code: "username-taken");
    }

    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await userCredential.user?.sendEmailVerification();

    

    debugPrint('User created in Firebase');

    await databaseService.recordUser(
      FirebaseAuth.instance.currentUser!.uid, 
      email,
      username
    );

    await FirebaseAuth.instance.signOut();
    
    debugPrint('User recorded in Supabase');

    // await setUpSession();

    debugPrint('✅ Registered successfully');
  } catch (e) {
    debugPrint('❌ Registration error: $e');
    rethrow;
  }
}

Future<bool> loginUser(String email, String password, BuildContext context) async {
  try {
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;

    if (user != null) {
        // Reload user to get latest emailVerified status
        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;

        // Check if email is verified
        if (refreshedUser?.emailVerified != true) {
          // Sign them out
          await FirebaseAuth.instance.signOut();
          if (!context.mounted) return false;
          // Show error dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Email Not Verified'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(8)
              ),
              content: Text(
                'Please verify your email before signing in.\n\n'
                'Check your inbox for the verification link.'
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Resend verification email
                    try {
                      // Need to sign in again temporarily to send email
                      final tempUser = await FirebaseAuth.instance
                          .signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                      await tempUser.user?.sendEmailVerification();
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Verification email sent!')),
                      );
                    } catch (e) {
                      print('Error resending email: $e');
                    }
                  },
                  child: Text('Resend Email', style: TextStyle(color: Theme.of(context).colorScheme.tertiary),),
                ),
                // TextButton(
                //   onPressed: () => Navigator.pop(context),
                //   child: Text('OK', style: TextStyle(color: Theme.of(context).colorScheme.tertiary),),
                // ),
              ],
            ),
          );
          return false;
        }

      debugPrint('Logged in to Firebase');

      bool hasUser = await databaseService.isUserRecorded(
        FirebaseAuth.instance.currentUser!.uid
      );

      debugPrint('User exists in Supabase: $hasUser');
      
      String username = await databaseService.getUserName(FirebaseAuth.instance.currentUser!.uid) ?? "Unknown User";

        if (!hasUser) {
          await databaseService.recordUser(
            FirebaseAuth.instance.currentUser!.uid, 
            email,
            username,
          );
          debugPrint('User recorded in Supabase');
        }


      await setUpSession();

      debugPrint('✅ Logged in successfully');
      return true;
    }
  } catch (e) {
    debugPrint('❌ Login error: $e');
    rethrow;
  }
  return false;
}

Future<void> setUpSession() async {
  storageService.listenUserMemories();
  activeUsername = await databaseService.getUserName(FirebaseAuth.instance.currentUser!.uid);
  refreshFriendsAndFollowers();
}

Future<void> logOut() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  storageService.dispose();
  await FirebaseAuth.instance.signOut();
}