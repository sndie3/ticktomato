import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cohere_service.dart';

class StudyWithAIScreen extends StatefulWidget {
  const StudyWithAIScreen({super.key});

  @override
  State<StudyWithAIScreen> createState() => _StudyWithAIScreenState();
}

class _StudyWithAIScreenState extends State<StudyWithAIScreen> {
  final TextEditingController _topicController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Conversation history: list of maps with 'role' and 'text'
  final List<Map<String, String>> _messages = [];

  Future<void> _sendMessage() async {
    final userInput = _topicController.text.trim();
    if (userInput.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': userInput});
      _isLoading = true;
      _topicController.clear();
    });
    try {
      // Use getExplanation for any user input, including code generation
      final aiResponse =
          await context.read<CohereService>().getExplanation(userInput);
      setState(() {
        _messages.add({'role': 'ai', 'text': aiResponse});
        _isLoading = false;
      });
      // Scroll to bottom after response
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'ai',
          'text': 'Sorry, I encountered an error. Please try again.'
        });
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: isUser ? 40 : 8,
          right: isUser ? 8 : 40,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Study with AI'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 16,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';
                  return _buildBubble(msg['text'] ?? '', isUser);
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: CircularProgressIndicator(),
              ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _topicController,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything to study... ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.blueAccent,
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
