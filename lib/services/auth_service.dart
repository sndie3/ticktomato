import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/database_helper.dart';

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<bool> register(String username, String email, String password) async {
    try {
      // Check if user already exists
      final existingUser = await _dbHelper.getUser(email);
      if (existingUser != null) {
        return false;
      }

      // Create new user
      final userId = await _dbHelper.createUser(username, email, password);
      if (userId > 0) {
        // Store user session
        await _secureStorage.write(key: 'user_id', value: userId.toString());
        await _secureStorage.write(key: 'email', value: email);
        return true;
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final user = await _dbHelper.getUser(email);
      if (user != null && user['password'] == password) {
        // Store user session
        await _secureStorage.write(
          key: 'user_id',
          value: user['id'].toString(),
        );
        await _secureStorage.write(key: 'email', value: email);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _secureStorage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final userId = await _secureStorage.read(key: 'user_id');
    return userId != null;
  }

  Future<String?> getCurrentUserId() async {
    return await _secureStorage.read(key: 'user_id');
  }
}
