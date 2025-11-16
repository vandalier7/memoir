import 'package:presentation/objects/globals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> recordMemory(String userID) async {
    String table = "memory";
    Map<String, dynamic> data = {
      'userID' : userID,
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

  Future<String> getActiveUsername(String userID) async {
    const table = "user";

    try {
      final response = await _supabase
          .from(table)
          .select('username')   
          .eq('uid', userID)
          .single();            

      return response['username'] as String;
    } catch (e) {
      print('Error querying $table: $e');
      rethrow;
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

}

// Global instance
