import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;
import 'supabase_service.dart';

class AuthService {
  final SupabaseService _supabase = SupabaseService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<bool> register(String username, String email, String password) async {
    try {
      // Check if user already exists
      final existingUser = await _supabase.getUser(email);
      if (existingUser != null) {
        return false;
      }

      // Create new user
      final userId = await _supabase.createUser(
        username: username,
        email: email,
        password: password,
      );

      // Store user session
      await _secureStorage.write(key: 'user_id', value: userId);
      await _secureStorage.write(key: 'email', value: email);
      return true;
    } catch (e) {
      developer.log('Registration error: $e', name: 'AuthService', error: e);
      rethrow;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _supabase.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Store user session
        await _secureStorage.write(
          key: 'user_id',
          value: response.user!.id,
        );
        await _secureStorage.write(key: 'email', value: email);
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Login error: $e', name: 'AuthService', error: e);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _supabase.signOut();
    await _secureStorage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    return _supabase.currentUser != null;
  }

  Future<String?> getCurrentUserId() async {
    return _supabase.currentUser?.id;
  }
}
