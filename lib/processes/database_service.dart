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

  Future<void> updateUserAvatar(String userId, String url) async {
    await _supabase.from('user').update({
      'profile_pic_url': url,
    }).eq('uid', userId);
  }

  Stream<Map<String, dynamic>> getUserStream(String userId) {
    return _supabase.from('user').stream(primaryKey: ['uid']).eq('uid', userId).map((data) => data.first);
  }

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

  Future<List<String>> getFriends(String userID) async {
    const table = "following";

    try {
      // People you follow
      final followingRes = await _supabase
          .from(table)
          .select("followingID")
          .eq("followerID", userID);

      final following = List<Map<String, dynamic>>.from(followingRes)
          .map((row) => row["followingID"] as String)
          .toSet(); // use a Set for fast intersection


      // People who follow you
      final followersRes = await _supabase
          .from(table)
          .select("followerID")
          .eq("followingID", userID);

      final followers = List<Map<String, dynamic>>.from(followersRes)
          .map((row) => row["followerID"] as String)
          .toSet();


      // Intersection = friends
      final friends = following.intersection(followers);

      return friends.toList();
    } catch (e) {
      print("Error querying $table: $e");
      rethrow;
    }
  }


  Future<List<String>> getFollowingUsers(String userID) async {
    String table = "following";
    Map<String, dynamic>? filters = {'followerID' : userID};
    try {
      var query = _supabase.from(table).select("followingID");

      // Apply filters
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      final response = await query;
      final rows = List<Map<String, dynamic>>.from(response);

      // extract the ID value
      return rows.map((row) => row["followingID"] as String).toList();
    } catch (e) {
      print('Error querying $table: $e');
      rethrow;
    }
  }

  Future<List<String>> getFollowers(String userID) async {
    String table = "following";
    Map<String, dynamic>? filters = {'followingID' : userID};
    try {
      var query = _supabase.from(table).select("followerID");

      // Apply filters
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      final response = await query;
      final rows = List<Map<String, dynamic>>.from(response);

      // extract the ID value
      return rows.map((row) => row["followerID"] as String).toList();
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

  Future<bool> toggleFollow(String userID) async {
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
        return true;
      } else {
        // Already following → delete
        await _supabase
            .from(table)
            .delete()
            .eq('followerID', storageService.currentUserId!)
            .eq('followingID', userID);
        print('Unfollowed $userID');
        return false;
      }
    } catch (e) {
      print('Error toggling follow: $e');
      rethrow;
    }
  }

  Future<List<int>> fetchFilteredMemoryIds({
    LatLngBounds? bounds, // Optional: filter by map viewport
  }) async {
    final currentUserId = storageService.currentUserId;
    if (currentUserId == null) return [];

    try {
      // ✅ Get allowed user IDs (friends + followed users)
      final allowedUserIds = <String>{
        ...friends,
        ...followedUsers,
      };

      if (allowedUserIds.isEmpty) {
        return []; // No friends/follows, return empty
      }

      // ✅ Query memory table
      var query = _supabase
        .from('memory')
        .select('memoryID') // Supabase memory ID column
        .inFilter('userID', allowedUserIds.toList())
        .limit(500); // Filter by allowed users

      

      // ✅ Limit results


      final response = await query;
      
      // ✅ Extract memoryID integers and convert to strings
      final memoryIds = (response as List)
        .map((row) => (row['memoryID'] as int))
        .toList();

      print('🔵 Fetched ${memoryIds.length} memory IDs from Supabase');
      return memoryIds;

    } catch (e) {
      print('❌ Error fetching memory IDs: $e');
      return [];
    }
  }

}

// Global instance
