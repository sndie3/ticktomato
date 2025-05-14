import 'dart:developer' as developer;
import 'supabase_service.dart';

class UserHistoryService {
  final SupabaseService _supabase = SupabaseService();
  List<Map<String, dynamic>>? _cachedQuizScores;
  DateTime? _lastCacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  Future<List<Map<String, dynamic>>> _getQuizScores(String userId) async {
    final now = DateTime.now();
    if (_cachedQuizScores != null &&
        _lastCacheTime != null &&
        now.difference(_lastCacheTime!) < _cacheDuration) {
      return _cachedQuizScores!;
    }

    try {
      final scores = await _supabase.getUserQuizScores(userId);
      _cachedQuizScores = scores;
      _lastCacheTime = now;
      return scores;
    } catch (e) {
      developer.log('Error fetching quiz scores: $e',
          name: 'UserHistoryService');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserHistory() async {
    try {
      final userId = _supabase.currentUser?.id;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final user = await _supabase.getUserById(userId);
      if (user == null) {
        throw Exception('User not found in user table');
      }

      final quizScores = await _getQuizScores(userId);
      final totalQuizzes = quizScores.length;
      final totalScore = quizScores.fold<int>(
        0,
        (sum, score) => sum + (score['score'] as int),
      );
      final averageScore = totalQuizzes > 0 ? totalScore / totalQuizzes : 0.0;

      final categoryScores = <String, double>{};
      for (final score in quizScores) {
        final category = score['category'] as String;
        categoryScores[category] =
            (categoryScores[category] ?? 0) + (score['score'] as int);
      }

      final lastActivity =
          quizScores.isNotEmpty ? quizScores.first['created_at'] : null;

      return {
        'username': user['username'],
        'email': user['email'],
        'totalQuizzes': totalQuizzes,
        'totalScore': totalScore,
        'averageScore': averageScore,
        'categoryScores': categoryScores,
        'lastActivity': lastActivity,
        'quizHistory': quizScores,
      };
    } catch (e) {
      developer.log('Error getting user history: $e',
          name: 'UserHistoryService', error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentQuizzes({
    int limit = 10,
  }) async {
    try {
      final userId = _supabase.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final quizScores = await _getQuizScores(userId);
      return quizScores.take(limit).toList();
    } catch (e) {
      developer.log('Error getting recent quizzes: $e',
          name: 'UserHistoryService', error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCategoryStats() async {
    try {
      final userId = _supabase.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final quizScores = await _getQuizScores(userId);
      final categoryStats = <String, Map<String, dynamic>>{};

      for (final score in quizScores) {
        final category = score['category'] as String;
        if (!categoryStats.containsKey(category)) {
          categoryStats[category] = {
            'totalQuizzes': 0,
            'totalScore': 0,
            'averageScore': 0.0,
          };
        }

        final stats = categoryStats[category]!;
        stats['totalQuizzes'] += 1;
        stats['totalScore'] += score['score'] as int;
        stats['averageScore'] = stats['totalScore'] / stats['totalQuizzes'];
      }

      return categoryStats;
    } catch (e) {
      developer.log('Error getting category stats: $e',
          name: 'UserHistoryService', error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }
}
