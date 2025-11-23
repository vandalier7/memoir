//globals.dart
import 'package:camera/camera.dart';
import 'memory.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:presentation/processes/storage_service.dart';
import 'package:presentation/processes/database_service.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'package:presentation/models/user_model.dart';
import '../processes/image_service.dart';

late final num pixelRatio;

enum Mood {
  happy,
  sad,
  angry,
  disgusted,
  afraid,
  calm,
  worried
}

Mood moodFromValue(int value) {
    switch (value) {
      case 0: return Mood.happy;
      case 1: return Mood.sad;
      case 2: return Mood.angry;
      case 3: return Mood.disgusted;
      case 4: return Mood.afraid;
      case 5: return Mood.calm;
      case 6: return Mood.worried;
      default: return Mood.happy;
    }
  }

AssetImage getMoodIcon (Mood mood) {
  switch (mood) {
      case Mood.happy:
        return AssetImage("assets/moods/Happy.png");
      case Mood.sad:
        return AssetImage("assets/moods/Sad.png");
      case Mood.angry:
        return AssetImage("assets/moods/Anger.png");
      case Mood.disgusted:
        return AssetImage("assets/moods/Disgust.png");
      case Mood.calm:
        return AssetImage("assets/moods/Chill.png");
      case Mood.afraid:
        return AssetImage("assets/moods/Scared.png");
      case Mood.worried:
        return AssetImage("assets/moods/Stressed.png");
      // Add more moods as needed
    }
}

Color getMoodColor(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return const Color.fromARGB(255, 226, 185, 0);
      case Mood.sad:
        return const Color.fromARGB(255, 33, 65, 243);
      case Mood.angry:
        return Colors.red.shade900;
      case Mood.disgusted:
        return Colors.green.shade800;
      case Mood.calm:
        return Colors.lightBlue.shade400;
      case Mood.afraid:
        return Colors.deepPurpleAccent;
      case Mood.worried:
        return Colors.deepOrangeAccent;
      // Add more moods as needed
    }
  }

const double clusterRadius = 30; // meters
const double clearanceRadius = 30; // pixels in screenSpace

List<CameraDescription> cameras = [];
List<MemoryData> memories = [];
List<MemoryData> myMemories = [];
List<MemoryData> unfilteredMemories = [];

late MapLibreMapController mapController;
LatLng? currentPosition;
LatLng? nearestMemoryPosition;

final StorageService storageService = StorageService(); 
final databaseService = DatabaseService();

String? activeUsername;

final GlobalKey<RootState> rootKey = GlobalKey<RootState>();

void toggleLoading(bool value) {
  rootKey.currentState?.toggleLoading(value);
}

List<String> followedUsers = [];
List<String> followers = [];
List<String> friends = [];

Future<void> refreshFriendsAndFollowers({bool alsoRefreshMemories = true}) async {
  
  followedUsers = await databaseService.getFollowingUsers(storageService.currentUserId!);
  followers = await databaseService.getFollowers(storageService.currentUserId!);
  friends = followedUsers.toSet().intersection(followers.toSet()).toList();
  
  final init = await databaseService.fetchFilteredMemoryIds();
  await storageService.fetchOthersMemories(init);

  if (alsoRefreshMemories) {
    await refreshMemories();
  }
}

Future<void> refreshMemories() async {
  final init = await databaseService.fetchFilteredMemoryIds();
  await storageService.fetchOthersMemories(init);
}

Future<String> Function(String imageUrl) imageUrlToPath = getCachedImagePath;
bool hasLocationError = false;

// Helper to find all memories at the same position as a given supabaseMemoryId
List<MemoryData>? getMemoriesAtSameLocation(int supabaseMemoryId) {
  // Find the memory with this supabaseMemoryId
  MemoryData? targetMemory;
  
  for (var memory in unfilteredMemories) {
    if (memory.supabaseMemoryId == supabaseMemoryId) {
      targetMemory = memory;
      break;
    }
  }
  
  // If memory not found, return null
  if (targetMemory == null) {
    print('⚠️ Memory with ID $supabaseMemoryId not found');
    return null;
  }
  
  // Get all memories at the same position
  final memoriesAtLocation = unfilteredMemories
      .where((m) => m.position == targetMemory!.position)
      .toList();
  
  return memoriesAtLocation;
}

// Helper to get the index of a specific memory in a list
int getMemoryIndex(List<MemoryData> memories, int supabaseMemoryId) {
  return memories.indexWhere((m) => m.supabaseMemoryId == supabaseMemoryId);
}

/// Creates a circular mood icon widget with customizable size and darkening
/// 
/// [mood] - The mood to display (if null, shows arrow up icon)
/// [size] - Diameter of the circle (default: 54)
/// [darkeningAlpha] - Alpha value for darkening overlay (0-255, default: 30)
Widget buildMoodCircle({
  Mood? mood,
  double size = 54,
  int darkeningAlpha = 30,
}) {
  final moodColor = mood != null 
      ? Color.alphaBlend(
          Colors.black.withAlpha(darkeningAlpha),
          getMoodColor(mood),
        )
      : const Color(0xFFF75270).withOpacity(0.9); // Default palette[0]

  return Container(
    height: size,
    width: size,
    decoration: BoxDecoration(
      color: moodColor,
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withOpacity(0.3),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Center(
      child: mood == null
          ? Icon(
              Icons.keyboard_arrow_up_rounded,
              color: Colors.white,
              size: size * 0.65, // Scale icon with circle size
            )
          : Padding(
              padding: EdgeInsets.all(0), // Proportional padding
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
                child: Image(
                  image: getMoodIcon(mood),
                  fit: BoxFit.contain,
                ),
              ),
            ),
    ),
  );
}