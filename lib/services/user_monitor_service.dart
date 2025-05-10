import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class UserMonitorService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await _dbHelper.database;
    return await db.query('users', orderBy: 'created_at DESC');
  }

  // Get user activity statistics
  Future<Map<String, dynamic>> getUserStats(int userId) async {
    final db = await _dbHelper.database;

    // Get total quiz attempts
    final quizAttempts = await db.query(
      'quiz_scores',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    // Calculate statistics
    int totalQuizzes = quizAttempts.length;
    int totalScore = 0;
    Map<String, int> categoryScores = {};

    for (var attempt in quizAttempts) {
      totalScore += attempt['score'] as int;
      String category = attempt['category'] as String;
      categoryScores[category] =
          (categoryScores[category] ?? 0) + (attempt['score'] as int);
    }

    return {
      'total_quizzes': totalQuizzes,
      'total_score': totalScore,
      'average_score': totalQuizzes > 0 ? totalScore / totalQuizzes : 0,
      'category_scores': categoryScores,
      'last_activity':
          quizAttempts.isNotEmpty ? quizAttempts.first['date'] : null,
    };
  }

  // Get user's recent activity
  Future<List<Map<String, dynamic>>> getUserRecentActivity(int userId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'quiz_scores',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 10,
    );
  }

  // Get all users with their statistics
  Future<List<Map<String, dynamic>>> getAllUsersWithStats() async {
    final users = await getAllUsers();
    List<Map<String, dynamic>> usersWithStats = [];

    for (var user in users) {
      final stats = await getUserStats(user['id'] as int);
      usersWithStats.add({...user, 'stats': stats});
    }

    return usersWithStats;
  }

  // Get top performing users
  Future<List<Map<String, dynamic>>> getTopUsers({int limit = 10}) async {
    final db = await _dbHelper.database;

    // Get users with their average scores
    final result = await db.rawQuery(
      '''
      SELECT 
        u.id,
        u.username,
        u.email,
        COUNT(qs.id) as total_quizzes,
        AVG(qs.score) as average_score
      FROM users u
      LEFT JOIN quiz_scores qs ON u.id = qs.user_id
      GROUP BY u.id
      ORDER BY average_score DESC
      LIMIT ?
    ''',
      [limit],
    );

    return result;
  }

  // Get user's category performance
  Future<Map<String, dynamic>> getUserCategoryPerformance(int userId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT 
        category,
        COUNT(*) as attempts,
        AVG(score) as average_score,
        MAX(score) as best_score
      FROM quiz_scores
      WHERE user_id = ?
      GROUP BY category
    ''',
      [userId],
    );

    Map<String, dynamic> performance = {};
    for (var row in result) {
      performance[row['category'] as String] = {
        'attempts': row['attempts'],
        'average_score': row['average_score'],
        'best_score': row['best_score'],
      };
    }

    return performance;
  }
}
