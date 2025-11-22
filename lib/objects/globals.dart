//globals.dart
import 'package:camera/camera.dart';
import 'memory.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:presentation/processes/storage_service.dart';
import 'package:presentation/processes/database_service.dart';
import 'package:flutter/material.dart';
import '../main.dart';
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

Color getMoodColor(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return Colors.yellow;
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
List<MemoryData> unfilteredMemories = [];

late MapLibreMapController mapController;
LatLng currentPosition = LatLng(14.5995, 120.9842);
LatLng? nearestMemoryPosition;

final StorageService storageService = StorageService(); 
final databaseService = DatabaseService();

String? activeUsername;

final GlobalKey<RootState> rootKey = GlobalKey<RootState>();

void toggleLoading(bool value) {
  rootKey.currentState?.toggleLoading(value);
}

List<String> followedUsers = [];
List<String> friends = [];

Future<void> refreshFriendsAndFollowers({bool alsoRefreshMemories = true}) async {
  friends = await databaseService.getFriends(storageService.currentUserId!);
  followedUsers = await databaseService.getFollowingUsers(storageService.currentUserId!);
  
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