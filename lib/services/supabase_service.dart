import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  // Initialize service
  Future<void> initialize() async {
    // Service initialization if needed
  }

  // Auth helpers
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  String? get currentUserId => currentUser?.id;

  // Auth operations
  Future<AuthResponse> signUp(
    String email,
    String password, {
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Generic CRUD operations
  Future<List<T>> selectAll<T>(
    String table,
    T Function(Map<String, dynamic>) fromJson, {
    int? limit,
    String? orderBy,
    bool ascending = true,
  }) async {
    try {
      PostgrestFilterBuilder query = client.from(table).select();

      if (orderBy != null && limit != null) {
        final response = await query
            .order(orderBy, ascending: ascending)
            .limit(limit);
        return (response as List).map((json) => fromJson(json)).toList();
      } else if (orderBy != null) {
        final response = await query.order(orderBy, ascending: ascending);
        return (response as List).map((json) => fromJson(json)).toList();
      } else if (limit != null) {
        final response = await query.limit(limit);
        return (response as List).map((json) => fromJson(json)).toList();
      } else {
        final response = await query;
        return (response as List).map((json) => fromJson(json)).toList();
      }
    } catch (e) {
      throw Exception('Failed to fetch $table: $e');
    }
  }

  Future<List<T>> selectByUserId<T>(
    String table,
    T Function(Map<String, dynamic>) fromJson, {
    int? limit,
    String? orderBy,
    bool ascending = true,
  }) async {
    try {
      if (currentUserId == null) return [];

      PostgrestFilterBuilder query = client
          .from(table)
          .select()
          .eq('user_id', currentUserId!);

      if (orderBy != null && limit != null) {
        final response = await query
            .order(orderBy, ascending: ascending)
            .limit(limit);
        return (response as List).map((json) => fromJson(json)).toList();
      } else if (orderBy != null) {
        final response = await query.order(orderBy, ascending: ascending);
        return (response as List).map((json) => fromJson(json)).toList();
      } else if (limit != null) {
        final response = await query.limit(limit);
        return (response as List).map((json) => fromJson(json)).toList();
      } else {
        final response = await query;
        return (response as List).map((json) => fromJson(json)).toList();
      }
    } catch (e) {
      throw Exception('Failed to fetch $table: $e');
    }
  }

  Future<T?> selectSingle<T>(
    String table,
    T Function(Map<String, dynamic>) fromJson,
    String id,
  ) async {
    try {
      final response = await client
          .from(table)
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch $table with id $id: $e');
    }
  }

  Future<T> insert<T>(
    String table,
    T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await client.from(table).insert(data).select().single();

      return fromJson(response);
    } catch (e) {
      throw Exception('Failed to insert into $table: $e');
    }
  }

  Future<T> update<T>(
    String table,
    T Function(Map<String, dynamic>) fromJson,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await client
          .from(table)
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return fromJson(response);
    } catch (e) {
      throw Exception('Failed to update $table with id $id: $e');
    }
  }

  Future<void> delete(String table, String id) async {
    try {
      await client.from(table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete from $table with id $id: $e');
    }
  }

  // Realtime subscriptions
  RealtimeChannel subscribe(String table) {
    return client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (payload) {
            // Handle realtime updates
          },
        )
        .subscribe();
  }

  // Utility methods
  Future<bool> checkConnection() async {
    try {
      await client.from('profiles').select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  // File storage operations
  Future<String> uploadFile(
    String bucket,
    String path,
    List<int> fileBytes,
  ) async {
    try {
      final uint8List = Uint8List.fromList(fileBytes);
      await client.storage.from(bucket).uploadBinary(path, uint8List);
      return client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> deleteFile(String bucket, String path) async {
    try {
      await client.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // RPC function calls
  Future<dynamic> rpc(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    try {
      return await client.rpc(functionName, params: params);
    } catch (e) {
      throw Exception('Failed to call RPC function $functionName: $e');
    }
  }
}
