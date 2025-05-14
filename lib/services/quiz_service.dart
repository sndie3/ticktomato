import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class QuizService {
  final String baseUrl = 'https://opentdb.com/api.php';

  Future<List<Map<String, dynamic>>> getQuestions({
    int amount = 10,
    String category = '',
    String difficulty = 'medium',
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl?amount=$amount&category=$category&difficulty=$difficulty&type=multiple',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['response_code'] == 0) {
          return List<Map<String, dynamic>>.from(data['results']);
        }
      }
      throw Exception('Failed to load questions');
    } catch (e) {
      developer.log('Quiz API error: $e', name: 'QuizService', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://opentdb.com/api_category.php'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['trivia_categories']);
      }
      throw Exception('Failed to load categories');
    } catch (e) {
      developer.log('Categories API error: $e', name: 'QuizService', error: e);
      rethrow;
    }
  }

  String decodeHtml(String htmlString) {
    return htmlString
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}
