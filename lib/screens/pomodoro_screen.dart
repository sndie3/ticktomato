import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/pomodoro_timer_service.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PomodoroTimerService>.value(
      value: PomodoroTimerService(),
      child: const PomodoroScreenBody(),
    );
  }
}

class PomodoroScreenBody extends StatelessWidget {
  const PomodoroScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final timerService = Provider.of<PomodoroTimerService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mode selection boxes
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: screenWidth / 3 - 24,
                    child: _buildModeBox(
                        context, 'Pomodoro', 'Pomodoro', 25, Colors.redAccent),
                  ),
                  SizedBox(
                    width: screenWidth / 3 - 24,
                    child: _buildModeBox(
                        context, 'Short Break', 'Short Break', 5, Colors.green),
                  ),
                  SizedBox(
                    width: screenWidth / 3 - 24,
                    child: _buildModeBox(
                        context, 'Long Break', 'Long Break', 15, Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              // Timer display
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.05 * 255).toInt()),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Consumer<PomodoroTimerService>(
                        builder: (context, timer, _) => Text(
                          timer.formatTime(timer.secondsLeft),
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<PomodoroTimerService>(
                      builder: (context, timer, _) => Text(
                        timer.mode,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              // Controls
              Consumer<PomodoroTimerService>(
                builder: (context, timer, _) => Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: timer.isRunning ? null : timer.startTimer,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        backgroundColor: Colors.grey,
                      ),
                      onPressed: timer.isRunning ? timer.pauseTimer : null,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        backgroundColor: Colors.blueAccent,
                      ),
                      onPressed: timer.resetTimer,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Completed Pomodoros
              Consumer<PomodoroTimerService>(
                builder: (context, timer, _) => Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Completed Pomodoros: ${timer.completedPomodoros}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeBox(BuildContext context, String mode, String label,
      int minutes, Color color) {
    final timer = Provider.of<PomodoroTimerService>(context);
    final bool isActive = timer.mode == mode;
    return GestureDetector(
      onTap: () => timer.switchMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: color.withAlpha((0.3 * 255).toInt()),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$minutes min',
              style: TextStyle(
                fontSize: 14,
                color: isActive ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
