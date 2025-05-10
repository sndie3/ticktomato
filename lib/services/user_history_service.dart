import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';

class UserHistoryService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Map<String, dynamic>> getUserHistory(int userId) async {
    try {
      final user = await _dbHelper.getUserById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      final quizScores = await _dbHelper.getUserQuizScores(userId);
      final totalQuizzes = quizScores.length;
      final totalScore = quizScores.fold<int>(
        0,
        (sum, score) => sum + score['score'] as int,
      );
      final averageScore = totalQuizzes > 0 ? totalScore / totalQuizzes : 0;

      // Calculate category scores
      final categoryScores = <String, double>{};
      for (final score in quizScores) {
        final category = score['category'] as String;
        categoryScores[category] =
            (categoryScores[category] ?? 0) + (score['score'] as int);
      }

      // Get last activity
      final lastActivity =
          quizScores.isNotEmpty
              ? quizScores.reduce(
                (a, b) =>
                    (a['timestamp'] as String).compareTo(
                              b['timestamp'] as String,
                            ) >
                            0
                        ? a
                        : b,
              )['timestamp']
              : null;

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
      if (kDebugMode) {
        print('Error getting user history: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentQuizzes(
    int userId, {
    int limit = 10,
  }) async {
    try {
      final quizScores = await _dbHelper.getUserQuizScores(userId);
      quizScores.sort(
        (a, b) =>
            (b['timestamp'] as String).compareTo(a['timestamp'] as String),
      );
      return quizScores.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting recent quizzes: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCategoryStats(int userId) async {
    try {
      final quizScores = await _dbHelper.getUserQuizScores(userId);
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
        stats['totalQuizzes'] = (stats['totalQuizzes'] as int) + 1;
        stats['totalScore'] =
            (stats['totalScore'] as int) + (score['score'] as int);
        stats['averageScore'] =
            (stats['totalScore'] as int) / (stats['totalQuizzes'] as int);
      }

      return categoryStats;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting category stats: $e');
      }
      rethrow;
    }
  }
}
