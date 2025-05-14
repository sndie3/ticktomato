// Import statements (unchanged)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import 'package:fl_chart/fl_chart.dart';

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({super.key});

  @override
  _UserHistoryScreenState createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  Map<String, dynamic>? _userHistory;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchUserHistory();
  }

  Future<void> fetchUserHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final userId = await authService.getCurrentUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final quizScoresResponse = await Supabase.instance.client
          .from('quiz_scores')
          .select('score, created_at, quiz_id, category')
          .eq('user_id', userId);

      final quizScores = List<Map<String, dynamic>>.from(quizScoresResponse);
      quizScores.sort((a, b) =>
          (b['created_at'] as String).compareTo(a['created_at'] as String));

      final categoryStats = getCategoryStats(quizScores);
      final totalScore = getTotalScore(quizScores);
      final totalQuizzes = quizScores.length;
      final lastActivity =
          quizScores.isNotEmpty ? quizScores.first['created_at'] : null;

      setState(() {
        _userHistory = {
          'totalScore': totalScore,
          'totalQuizzes': totalQuizzes,
          'lastActivity': lastActivity,
          'categoryStats': categoryStats,
          'quizHistory': quizScores,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> getCategoryStats(List<Map<String, dynamic>> quizScores) {
    final Map<String, Map<String, dynamic>> categoryStats = {};

    for (final score in quizScores) {
      final category = score['category'] as String? ?? 'Unknown';
      final scoreValue = (score['score'] as num).toDouble();

      categoryStats.putIfAbsent(category, () {
        return {'totalScore': 0.0, 'totalQuizzes': 0};
      });

      categoryStats[category]!['totalScore'] += scoreValue;
      categoryStats[category]!['totalQuizzes'] += 1;
    }

    for (final category in categoryStats.keys) {
      final stats = categoryStats[category]!;
      final totalScore = stats['totalScore'] as double;
      final totalQuizzes = stats['totalQuizzes'] as int;
      stats['averageScore'] =
          totalQuizzes > 0 ? totalScore / totalQuizzes : 0.0;
    }

    return categoryStats;
  }

  double getTotalScore(List<Map<String, dynamic>> quizScores) {
    double total = 0;
    for (final score in quizScores) {
      total += (score['score'] as num).toDouble();
    }
    return total;
  }

  String formatDate(String timestamp) {
    final date = DateTime.parse(timestamp);
    return DateFormat('MMM dd, yyyy, hh:mm a').format(date);
  }

  Widget _buildScoreChart() {
    final quizHistory = _userHistory!['quizHistory'] as List;
    if (quizHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get the last 10 quizzes for the chart
    final recentQuizzes = quizHistory.take(10).toList().reversed.toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score Progress',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= recentQuizzes.length) {
                            return const Text('');
                          }
                          final date = DateTime.parse(
                              recentQuizzes[value.toInt()]['created_at']);
                          return Text(DateFormat('MM/dd').format(date));
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(recentQuizzes.length, (index) {
                        return FlSpot(
                          index.toDouble(),
                          (recentQuizzes[index]['score'] as num).toDouble(),
                        );
                      }),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                  child: _buildStatItem(
                    'Total Quizzes',
                    _userHistory!['totalQuizzes'].toString(),
                    Icons.quiz,
                  ),
                ),
                Flexible(
                  child: _buildStatItem(
                    'Total Score',
                    _userHistory!['totalScore'].toStringAsFixed(1),
                    Icons.star,
                  ),
                ),
                if (_userHistory!['lastActivity'] != null)
                  Flexible(
                    child: _buildStatItem(
                      'Last Activity',
                      formatDate(_userHistory!['lastActivity']),
                      Icons.access_time,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildCategoryStats() {
    final categoryStats =
        _userHistory!['categoryStats'] as Map<String, dynamic>;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category Statistics',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...categoryStats.entries.map((entry) {
              final stats = entry.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (stats['averageScore'] as double) / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Average Score: ${stats['averageScore'].toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Quizzes Taken: ${stats['totalQuizzes']}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentQuizzes() {
    final quizHistory = _userHistory!['quizHistory'] as List;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Quizzes',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (quizHistory.isEmpty)
              const Center(
                child: Text('No recent quizzes taken.'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quizHistory.length,
                itemBuilder: (context, index) {
                  final quiz = quizHistory[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${quiz['score']}'),
                      ),
                      title: Text('Category: ${quiz['category']}'),
                      subtitle: Text(formatDate(quiz['created_at'])),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchUserHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchUserHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchUserHistory,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(),
                        const SizedBox(height: 16),
                        _buildScoreChart(),
                        const SizedBox(height: 16),
                        _buildCategoryStats(),
                        const SizedBox(height: 16),
                        _buildRecentQuizzes(),
                      ],
                    ),
                  ),
                ),
    );
  }
}
