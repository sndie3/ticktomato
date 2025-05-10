import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/cohere_service.dart';
import '../services/quiz_service.dart';
import 'login_screen.dart';
import 'quiz_screen.dart';
import 'user_history_screen.dart';
import 'pomodoro_screen.dart';
import 'study_with_ai_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _topicController = TextEditingController();
  String _aiResponse = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;
  bool _showCategories = false;

  // Pomodoro timer state for compact widget
  static const int pomodoroDuration = 25 * 60;
  int _pomodoroSecondsLeft = pomodoroDuration;
  Timer? _pomodoroTimer;
  bool _pomodoroRunning = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await context.read<QuizService>().getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
      }
    }
  }

  Future<void> _getStudySuggestions() async {
    if (_topicController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final suggestions = await context
          .read<CohereService>()
          .getStudySuggestions(_topicController.text);
      setState(() {
        _aiResponse = suggestions.join('\n');
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _startQuiz(String category, String categoryId) async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(category: category, categoryId: categoryId),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await context.read<AuthService>().logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }

  // Pomodoro timer widget logic
  void _startPomodoro() {
    _pomodoroTimer?.cancel();
    setState(() => _pomodoroRunning = true);
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pomodoroSecondsLeft > 0) {
        setState(() => _pomodoroSecondsLeft--);
      } else {
        _pomodoroTimer?.cancel();
        setState(() => _pomodoroRunning = false);
        // TODO: Play sound when finished (handled in full Pomodoro screen)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pomodoro finished!')));
      }
    });
  }

  void _pausePomodoro() {
    _pomodoroTimer?.cancel();
    setState(() => _pomodoroRunning = false);
  }

  void _resetPomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _pomodoroRunning = false;
      _pomodoroSecondsLeft = pomodoroDuration;
    });
  }

  String _formatPomodoroTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Buddy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UserHistoryScreen()),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 32 : 8,
            vertical: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pomodoro Timer Widget
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isWide ? 32 : 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.timer, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Text(
                              'Pomodoro Timer',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const PomodoroScreen(),
                                  ),
                                );
                              },
                              child: const Text('Full Timer'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatPomodoroTime(_pomodoroSecondsLeft),
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_arrow),
                              color: Colors.green,
                              iconSize: isWide ? 40 : 32,
                              onPressed:
                                  _pomodoroRunning ? null : _startPomodoro,
                            ),
                            IconButton(
                              icon: const Icon(Icons.pause),
                              color: Colors.orange,
                              iconSize: isWide ? 40 : 32,
                              onPressed:
                                  _pomodoroRunning ? _pausePomodoro : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              color: Colors.blue,
                              iconSize: isWide ? 40 : 32,
                              onPressed: _resetPomodoro,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Study with AI Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.psychology),
                  label: const Text('Study with AI'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isWide ? 24 : 18),
                    textStyle: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StudyWithAIScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Quiz Section
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isWide ? 32 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.quiz, color: Colors.deepPurple),
                            const SizedBox(width: 8),
                            Text(
                              'Quiz',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Test your knowledge by taking a quiz! Choose a category to get started.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Quiz'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isWide ? 48 : 32,
                                vertical: isWide ? 20 : 16,
                              ),
                              textStyle: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              setState(
                                () => _showCategories = !_showCategories,
                              );
                            },
                          ),
                        ),
                        if (_showCategories)
                          _isLoadingCategories
                              ? const Center(child: CircularProgressIndicator())
                              : Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children:
                                      _categories.map((category) {
                                        return ActionChip(
                                          label: Text(category['name']),
                                          backgroundColor:
                                              Colors.deepPurple[50],
                                          labelStyle: const TextStyle(
                                            color: Colors.deepPurple,
                                          ),
                                          onPressed:
                                              () => _startQuiz(
                                                category['name'],
                                                category['id'].toString(),
                                              ),
                                        );
                                      }).toList(),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
