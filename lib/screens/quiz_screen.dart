import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:uuid/uuid.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

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
  final SupabaseService _supabase = SupabaseService();
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
    developer.log(
      'QuizScreen initialized for category: ${widget.category} (ID: ${widget.categoryId})',
      name: 'QuizScreen',
    );
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    developer.log(
      'Loading questions for category: ${widget.categoryId}',
      name: 'QuizScreen',
    );
    try {
      final questions = await _quizService.getQuestions(
        category: widget.categoryId,
        amount: 10,
      );
      developer.log(
        'Loaded ${questions.length} questions',
        name: 'QuizScreen',
      );
      developer.log(
        'First question: ${questions.first['question']}',
        name: 'QuizScreen',
      );

      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      developer.log(
        'Error loading questions: $e',
        name: 'QuizScreen',
        error: e,
      );
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading questions: $e')));
      }
    }
  }

  Future<void> _saveScore() async {
    developer.log(
      'Attempting to save score: [32m[0m$_score[0m for category: [34m${widget.category}[0m',
      name: 'QuizScreen',
    );
    try {
      final userId = await context.read<AuthService>().getCurrentUserId();
      developer.log(
        'Current user ID: [33m$userId[0m',
        name: 'QuizScreen',
      );
      print('Saving score for userId: ' +
          (userId ?? 'null') +
          ', score: ' +
          _score.toString() +
          ', category: ' +
          widget.category);
      if (userId != null) {
        final quizId = const Uuid().v4();
        await _supabase.saveQuizScore(
          userId: userId,
          score: _score,
          category: widget.category,
          quizId: quizId,
        );
        print('Score saved!');
        developer.log(
          'Score saved successfully',
          name: 'QuizScreen',
        );
      } else {
        developer.log(
          'Failed to save score: No user ID found',
          name: 'QuizScreen',
        );
      }
    } catch (e) {
      developer.log(
        'Error saving score: $e',
        name: 'QuizScreen',
        error: e,
      );
      print('Error saving score: ' + e.toString());
    }
  }

  void _handleAnswer(String answer) {
    if (_hasAnswered) {
      developer.log(
        'Answer already submitted, ignoring',
        name: 'QuizScreen',
      );
      return;
    }

    developer.log(
      'Handling answer: $answer',
      name: 'QuizScreen',
    );
    developer.log(
      'Correct answer: ${_questions[_currentQuestionIndex]['correct_answer']}',
      name: 'QuizScreen',
    );

    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
      if (answer == _questions[_currentQuestionIndex]['correct_answer']) {
        _score++;
        developer.log(
          'Correct answer! New score: $_score',
          name: 'QuizScreen',
        );
      } else {
        developer.log(
          'Incorrect answer. Score remains: $_score',
          name: 'QuizScreen',
        );
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          if (_currentQuestionIndex < _questions.length - 1) {
            _currentQuestionIndex++;
            _hasAnswered = false;
            _selectedAnswer = null;
            developer.log(
              'Moving to next question: ${_currentQuestionIndex + 1}',
              name: 'QuizScreen',
            );
          } else {
            _quizCompleted = true;
            developer.log(
              'Quiz completed. Final score: $_score/${_questions.length}',
              name: 'QuizScreen',
            );
            _saveScore();
          }
        });
      }
    });
  }

  void _restartQuiz() {
    developer.log(
      'Restarting quiz',
      name: 'QuizScreen',
    );
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
    developer.log(
      'Building QuizScreen. Loading: $_isLoading, Completed: $_quizCompleted',
      name: 'QuizScreen',
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
                  developer.log(
                    'Navigating back to home screen',
                    name: 'QuizScreen',
                  );
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

    developer.log(
      'Current question: ${currentQuestion['question']}',
      name: 'QuizScreen',
    );
    developer.log(
      'Available answers: $allAnswers',
      name: 'QuizScreen',
    );

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
                    backgroundColor: showCorrect
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
            }),
            const SizedBox(height: 16),
            if (_hasAnswered)
              Text(
                _selectedAnswer == currentQuestion['correct_answer']
                    ? 'Correct!'
                    : 'Incorrect! The correct answer is: ${_quizService.decodeHtml(currentQuestion['correct_answer'])}',
                style: TextStyle(
                  color: _selectedAnswer == currentQuestion['correct_answer']
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
