import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _client;

  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  // User auth
  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Create user account
  Future<String> createUser({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user != null) {
      final userId = response.user!.id;

      // Ensure the user row is added
      await _client.from('users').insert({
        'id': userId,
        'username': username,
        'email': email,
      });

      return userId;
    }
    throw Exception('Failed to create user');
  }

  /// Fetch user by ID (must match Supabase auth user.id)
  Future<Map<String, dynamic>?> getUserById(String id) async {
    final response =
        await _client.from('users').select().eq('id', id).maybeSingle();
    return response;
  }

  /// Fetch user by email (use with caution if not using email as primary key)
  Future<Map<String, dynamic>?> getUser(String email) async {
    final response =
        await _client.from('users').select().eq('email', email).maybeSingle();
    return response;
  }

  /// Get all users (admin use only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await _client.from('users').select().order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  // Quiz scores
  Future<void> saveQuizScore({
    required String userId,
    required int score,
    required String category,
    required String quizId,
  }) async {
    await _client.from('quiz_scores').insert({
      'user_id': userId,
      'score': score,
      'category': category,
      'quiz_id': quizId,
    });
  }

  Future<List<Map<String, dynamic>>> getUserQuizScores(String userId) async {
    final response = await _client
        .from('quiz_scores')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
