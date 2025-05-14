import 'dart:async';
import 'package:flutter/foundation.dart';

class PomodoroTimerService extends ChangeNotifier {
  static final PomodoroTimerService _instance =
      PomodoroTimerService._internal();
  factory PomodoroTimerService() => _instance;
  PomodoroTimerService._internal();

  static const int pomodoroDuration = 25 * 60;
  static const int shortBreak = 5 * 60;
  static const int longBreak = 15 * 60;

  int _secondsLeft = pomodoroDuration;
  Timer? _timer;
  bool _isRunning = false;
  String _mode = 'Pomodoro';
  int _completedPomodoros = 0;

  int get secondsLeft => _secondsLeft;
  bool get isRunning => _isRunning;
  String get mode => _mode;
  int get completedPomodoros => _completedPomodoros;

  void startTimer() {
    _timer?.cancel();
    _isRunning = true;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        _secondsLeft--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _isRunning = false;
        notifyListeners();
        if (_mode == 'Pomodoro') {
          _completedPomodoros++;
          if (_completedPomodoros % 4 == 0) {
            switchMode('Long Break');
          } else {
            switchMode('Short Break');
          }
        } else {
          switchMode('Pomodoro');
        }
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _isRunning = false;
    if (_mode == 'Pomodoro') {
      _secondsLeft = pomodoroDuration;
    } else if (_mode == 'Short Break') {
      _secondsLeft = shortBreak;
    } else {
      _secondsLeft = longBreak;
    }
    notifyListeners();
  }

  void switchMode(String mode) {
    _mode = mode;
    if (mode == 'Pomodoro') {
      _secondsLeft = pomodoroDuration;
    } else if (mode == 'Short Break') {
      _secondsLeft = shortBreak;
    } else {
      _secondsLeft = longBreak;
    }
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}
