import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:presentation/objects/globals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../objects/globals.dart';

class DatabaseService {
  // Singleton instance
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Get Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;


  Future<void> recordUser(String userID, String email, String username) async {
    String table = "user";
    Map<String, dynamic> data = {
      'uid' : userID,
      'email' : email,
      'username' : username
    };

    try {
        await _supabase
          .from(table)
          .insert(data);

    } catch (e) {
      print('Error inserting into $table: $e');
      rethrow;
    }
  }

  Future<int> recordMemory(String userID, LatLng position) async {
    String table = "memory";
    Map<String, dynamic> data = {
      'userID' : userID,
      'latitude' : position.latitude,
      'longitude' : position.longitude
    };

    late final supabaseMemoryResponse;

    try {
        supabaseMemoryResponse = await _supabase
          .from(table)
          .insert(data)
          .select('memoryID')
          .single();
        
        return supabaseMemoryResponse['memoryID'] as int;

    } catch (e) {
      print('Error inserting into $table: $e');
      rethrow;
    }
  }

  Future<bool> isUsernameAvailable(String username) async {

    String table = "user";
    Map<String, dynamic>? filters = {'username' : username};
    try {
      var query = _supabase.from(table).select();

      // Apply filters
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response).isEmpty;
    } catch (e) {
      print('Error querying $table: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchByUsername(String query, {bool hideSelf = true}) async {
    final response = await _supabase
    .from('user')
    .select('uid, username') // whatever fields you want
    .ilike('username', '%$query%')      // case-insensitive partial match
    .limit(10);

    if (!hideSelf) {
      return List<Map<String, dynamic>>.from(response);
    }
    else {
      List<Map<String, dynamic>> res = List<Map<String, dynamic>>.from(response);
      res = res.where((row) => row['username'] != activeUsername).toList();
      return res;
    }
  }



  /// Query records with filters
  Future<bool> isUserRecorded(String userID) async {

    String table = "user";
    Map<String, dynamic>? filters = {'uid' : userID};
    try {
      var query = _supabase.from(table).select();

      // Apply filters
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response).isNotEmpty;
    } catch (e) {
      print('Error querying $table: $e');
      rethrow;
    }
  }

  Future<String> getUserName(String userID) async {
    const table = "user";
    try {
      // Select only the 'name' column
      final response = await _supabase
          .from(table)
          .select('username')
          .eq('uid', userID)
          .maybeSingle(); // returns single row or null

      // response is Map<String, dynamic>
      return response!['username'] as String;
    } catch (e) {
      print('Error querying $table: $e');
      rethrow;
    }
  }


  Future<int> getFollowerCount(String userID) async {

    String table = "following";
    Map<String, dynamic>? filters = {'followingID' : userID};
    try {
      var query = _supabase.from(table).select();

      // Apply filters
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response).length;
    } catch (e) {
      print('Error querying $table: $e');
      rethrow;
    }
  }

  Future<int> getFollowingCount(String userID) async {

    String table = "following";
    Map<String, dynamic>? filters = {'followerID' : userID};
    try {
      var query = _supabase.from(table).select();

      // Apply filters
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response).length;
    } catch (e) {
      print('Error querying $table: $e');
      rethrow;
    }
  }

  Future<int> getMemoryCount(String userID) async {

    String table = "memory";
    Map<String, dynamic>? filters = {'userID' : userID};
    try {
      var query = _supabase.from(table).select();

      // Apply filters
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response).length;
    } catch (e) {
      print('Error querying $table: $e');
      rethrow;
    }
  }

  Future<void> toggleFollow(String userID) async {
    final String table = 'following';
    

    try {
      // Check if the follow relation already exists
      final existing = await _supabase
          .from(table)
          .select()
          .eq('followerID', storageService.currentUserId!)
          .eq('followingID', userID)
          .maybeSingle();

      if (existing == null) {
        // Not following yet → insert
        await _supabase.from(table).insert({
          'followerID': storageService.currentUserId!,
          'followingID': userID,
        });
        print('Now following $userID');
      } else {
        // Already following → delete
        await _supabase
            .from(table)
            .delete()
            .eq('followerID', storageService.currentUserId!)
            .eq('followingID', userID);
        print('Unfollowed $userID');
      }
    } catch (e) {
      print('Error toggling follow: $e');
      rethrow;
    }
  }


}

// Global instance
