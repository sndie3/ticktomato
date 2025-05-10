import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_history_service.dart';

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({super.key});

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  final UserHistoryService _historyService = UserHistoryService();
  Map<String, dynamic>? _userHistory;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserHistory();
  }

  Future<void> _loadUserHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userId = await context.read<AuthService>().getCurrentUserId();
      if (userId != null) {
        final history = await _historyService.getUserHistory(int.parse(userId));
        setState(() {
          _userHistory = history;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            e.toString().contains('User not found')
                ? 'User not found. Please log in again.'
                : 'Error loading history: $e';
      });
      if (mounted) {
        debugPrint('UserHistoryScreen error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 18, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.home),
                      label: const Text('Back to Home'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              )
              : _userHistory == null
              ? const Center(child: Text('No history available'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Statistics
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overall Statistics',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            _buildStatRow(
                              'Total Quizzes',
                              _userHistory!['totalQuizzes'].toString(),
                            ),
                            _buildStatRow(
                              'Total Score',
                              _userHistory!['totalScore'].toString(),
                            ),
                            _buildStatRow(
                              'Average Score',
                              _userHistory!['averageScore'].toStringAsFixed(1),
                            ),
                            if (_userHistory!['lastActivity'] != null)
                              _buildStatRow(
                                'Last Activity',
                                _userHistory!['lastActivity'],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category Scores
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category Performance',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            ...(_userHistory!['categoryScores']
                                    as Map<String, double>)
                                .entries
                                .map(
                                  (entry) => _buildStatRow(
                                    entry.key,
                                    entry.value.toStringAsFixed(1),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Recent Quizzes
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Quizzes',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            ...(_userHistory!['quizHistory']
                                    as List<Map<String, dynamic>>)
                                .map(
                                  (quiz) => ListTile(
                                    title: Text(
                                      (quiz['category'] ?? 'Unknown') as String,
                                    ),
                                    subtitle: Text(
                                      'Score: ${quiz['score'] ?? '-'}',
                                    ),
                                    trailing: Text(
                                      (quiz['timestamp'] ?? '-') as String,
                                    ),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
