import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:presentation/camera_ui/preview_screen.dart';
import 'package:presentation/models/bin_item.dart';
import 'package:presentation/screens/account_screen.dart';
import 'app_theme.dart';


import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'my_scaffold.dart';
import 'screens/bin_screen.dart';

import 'screens/sign_in.dart';
import 'screens/loading_screen.dart';

import 'objects/notifications_screen.dart';

import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbauth;

import 'objects/globals.dart';
import 'screens/edit_profile.dart';
import 'screens/bin_screen.dart';
import 'camera_ui/camera_screen.dart';
import 'camera_ui/journal_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    pixelRatio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    // print("✅ REAL pixelRatio: $pixelRatio");
  });

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); 

  try {
    // Initialize Firebase before the app runs
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // Initialize Supabase with error handling
    await Supabase.initialize(
      url: 'https://drnpxydotpjbxigrnlli.supabase.co', 
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRybnB4eWRvdHBqYnhpZ3JubGxpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2NjcwOTMsImV4cCI6MjA3NzI0MzA5M30.jMuA5DoAbWz-WCfcyqg6ndPy1pkxMUXOutj3UbGTptg',
    );
    print('✅ Supabase initialized successfully');

    // Get available cameras
    cameras = await availableCameras();
    print('✅ Cameras initialized: ${cameras.length} camera(s) found');

  } catch (e) {
    print('❌ Initialization error: $e');
    // You might want to show an error screen here instead of continuing
  }

  if (fbauth.FirebaseAuth.instance.currentUser != null) {
    storageService.listenUserMemories();
    activeUsername = await databaseService.getUserName(fbauth.FirebaseAuth.instance.currentUser!.uid);
    await refreshFriendsAndFollowers();
  }
  

  MapLibreMap.useHybridComposition = true;
  
  runApp(Root(key: rootKey));
}

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<StatefulWidget> createState() => RootState();
}

class RootState extends State<Root> {
  bool isLoading = true;

  void toggleLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorScheme: memoirTheme),
      debugShowCheckedModeBanner: false,
      title: "Memoir",
      builder: (context, child) {
      return Stack(
          children: [
            child!,
            LoadingScreen(ignoring: !isLoading),
          ],
        );
      },
      // Directly show the main map screen wrapper (MyScaffold)
      home:  fbauth.FirebaseAuth.instance.currentUser != null ? MyScaffold() : SignInCard(), 
      // 🔗 Routes for navigation
      routes: {
        '/sign-in': (context) => const SignInCard(),
        '/map': (context) => const MyScaffold(),
        '/journal': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is String) {
            // ✅ Pass the imagePath and cameras to JournalScreen
            return JournalScreen(imagePath: args, cameras: cameras);
          }
          else if (args is List<dynamic>) {
            // ✅ Pass the imagePath and cameras to JournalScreen
            
            return FutureBuilder(
              future: imageUrlToPath(args.first as String), 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 5000,
                    width: 5000,
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ); // Loading state
                }
                
                if (snapshot.hasError) {
                  return Icon(Icons.error); // Error state
                }

                final filepath = snapshot.data!;
                BinItem item = args.last as BinItem;

                return JournalScreen(imagePath: filepath, cameras: cameras, item: item,);
              }
            );
            



          } else {
            // 🛠 Fallback (in case no image was passed)
            return JournalScreen(imagePath: '', cameras: cameras);
          }
        },
        '/account': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return AccountScreen(uid: args.toString());
        },
        '/bin': (context) => const BinScreen(),
        '/camera': (context) => CameraScreen(cameras: cameras,),
        '/preview': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (true) {
            // ✅ Pass the imagePath and cameras to JournalScreen
            return PreviewScreen(imagePath: args.toString());
          }
        },
        '/editProfile': (context) => const EditProfileScreen(),
        '/notifications': (context) => const NotificationsScreen(), 
      },
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
