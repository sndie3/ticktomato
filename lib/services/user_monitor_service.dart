import 'supabase_service.dart';

class UserMonitorService {
  final SupabaseService _supabase = SupabaseService();

  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await SupabaseService().getAllUsers();
  }

  // Get user activity statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final quizAttempts = await _supabase.getUserQuizScores(userId);

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
          quizAttempts.isNotEmpty ? quizAttempts.first['created_at'] : null,
    };
  }

  // Get user's recent activity
  Future<List<Map<String, dynamic>>> getUserRecentActivity(
      String userId) async {
    final quizAttempts = await _supabase.getUserQuizScores(userId);
    return quizAttempts.take(10).toList();
  }

  // Get all users with their statistics
  Future<List<Map<String, dynamic>>> getAllUsersWithStats() async {
    final users = await getAllUsers();
    List<Map<String, dynamic>> usersWithStats = [];

    for (var user in users) {
      final stats = await getUserStats(user['id'] as String);
      usersWithStats.add({...user, 'stats': stats});
    }

    return usersWithStats;
  }

  // Get top performing users
  Future<List<Map<String, dynamic>>> getTopUsers({int limit = 10}) async {
    final users = await getAllUsersWithStats();
    users.sort((a, b) => (b['stats']['average_score'] as num)
        .compareTo(a['stats']['average_score'] as num));
    return users.take(limit).toList();
  }

  // Get user's category performance
  Future<Map<String, dynamic>> getUserCategoryPerformance(String userId) async {
    final quizAttempts = await _supabase.getUserQuizScores(userId);

    Map<String, dynamic> performance = {};
    for (var attempt in quizAttempts) {
      String category = attempt['category'] as String;
      performance[category] ??= {
        'attempts': 0,
        'average_score': 0.0,
        'best_score': 0,
        'total_score': 0,
      };
      performance[category]['attempts'] += 1;
      performance[category]['total_score'] += attempt['score'] as int;
      if ((attempt['score'] as int) > performance[category]['best_score']) {
        performance[category]['best_score'] = attempt['score'] as int;
      }
    }
    // Calculate average
    performance.forEach((category, stats) {
      stats['average_score'] = stats['attempts'] > 0
          ? stats['total_score'] / stats['attempts']
          : 0.0;
    });

    return performance;
  }
}
