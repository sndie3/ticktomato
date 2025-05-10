import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';
import '../database/database_helper.dart';

class QuizScreen extends StatefulWidget {
  final String category;
  final String categoryId;

  const QuizScreen({
    super.key,
    required this.category,
    required this.categoryId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _hasAnswered = false;
  String? _selectedAnswer;
  bool _quizCompleted = false;

  @override
  void initState() {
    super.initState();
    print(
      'QuizScreen initialized for category: ${widget.category} (ID: ${widget.categoryId})',
    );
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    print('Loading questions for category: ${widget.categoryId}');
    try {
      final questions = await _quizService.getQuestions(
        category: widget.categoryId,
        amount: 10,
      );
      print('Loaded ${questions.length} questions');
      print('First question: ${questions.first['question']}');

      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading questions: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading questions: $e')));
      }
    }
  }

  Future<void> _saveScore() async {
    print('Attempting to save score: $_score for category: ${widget.category}');
    try {
      final userId = await context.read<AuthService>().getCurrentUserId();
      print('Current user ID: $userId');

      if (userId != null) {
        await _dbHelper.saveQuizScore(
          int.parse(userId),
          _score,
          widget.category,
        );
        print('Score saved successfully');
      } else {
        print('Failed to save score: No user ID found');
      }
    } catch (e) {
      print('Error saving score: $e');
    }
  }

  void _handleAnswer(String answer) {
    if (_hasAnswered) {
      print('Answer already submitted, ignoring');
      return;
    }

    print('Handling answer: $answer');
    print(
      'Correct answer: ${_questions[_currentQuestionIndex]['correct_answer']}',
    );

    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
      if (answer == _questions[_currentQuestionIndex]['correct_answer']) {
        _score++;
        print('Correct answer! New score: $_score');
      } else {
        print('Incorrect answer. Score remains: $_score');
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          if (_currentQuestionIndex < _questions.length - 1) {
            _currentQuestionIndex++;
            _hasAnswered = false;
            _selectedAnswer = null;
            print('Moving to next question: ${_currentQuestionIndex + 1}');
          } else {
            _quizCompleted = true;
            print('Quiz completed. Final score: $_score/${_questions.length}');
            _saveScore();
          }
        });
      }
    });
  }

  void _restartQuiz() {
    print('Restarting quiz');
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _hasAnswered = false;
      _selectedAnswer = null;
      _quizCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print(
      'Building QuizScreen. Loading: $_isLoading, Completed: $_quizCompleted',
    );

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_quizCompleted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Completed')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Your Score: $_score/${_questions.length}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _restartQuiz,
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  print('Navigating back to home screen');
                  Navigator.of(context).pop();
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final allAnswers = [
      ...currentQuestion['incorrect_answers'],
      currentQuestion['correct_answer'],
    ]..shuffle();

    print('Current question: ${currentQuestion['question']}');
    print('Available answers: $allAnswers');

    return Scaffold(
      appBar: AppBar(title: Text('Quiz: ${widget.category}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
            ),
            const SizedBox(height: 16),
            Text(
              'Question ${_currentQuestionIndex + 1}/${_questions.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _quizService.decodeHtml(currentQuestion['question']),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            ...allAnswers.map((answer) {
              final isCorrect = answer == currentQuestion['correct_answer'];
              final isSelected = answer == _selectedAnswer;
              final showCorrect = _hasAnswered && isCorrect;
              final showIncorrect = _hasAnswered && isSelected && !isCorrect;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ElevatedButton(
                  onPressed: _hasAnswered ? null : () => _handleAnswer(answer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        showCorrect
                            ? Colors.green
                            : showIncorrect
                            ? Colors.red
                            : null,
                  ),
                  child: Text(
                    _quizService.decodeHtml(answer),
                    style: TextStyle(
                      color: showCorrect || showIncorrect ? Colors.white : null,
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            if (_hasAnswered)
              Text(
                _selectedAnswer == currentQuestion['correct_answer']
                    ? 'Correct!'
                    : 'Incorrect! The correct answer is: ${_quizService.decodeHtml(currentQuestion['correct_answer'])}',
                style: TextStyle(
                  color:
                      _selectedAnswer == currentQuestion['correct_answer']
                          ? Colors.green
                          : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
