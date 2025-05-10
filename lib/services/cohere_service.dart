import 'package:http/http.dart' as http;
import 'dart:convert';

class CohereService {
  final String apiKey;
  final String baseUrl = 'https://api.cohere.ai/v1';

  CohereService({required this.apiKey});

  Future<String> generateResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prompt': prompt,
          'max_tokens': 150,
          'temperature': 0.7,
          'k': 0,
          'stop_sequences': [],
          'return_likelihoods': 'NONE',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['generations'][0]['text'];
      } else {
        throw Exception('Failed to generate response: ${response.statusCode}');
      }
    } catch (e) {
      print('Cohere API error: $e');
      return 'Sorry, I encountered an error. Please try again.';
    }
  }

  Future<List<String>> getStudySuggestions(String topic) async {
    final prompt =
        'Generate 5 study suggestions for $topic. Format as a numbered list.';
    final response = await generateResponse(prompt);
    return response
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
  }

  Future<String> getExplanation(String concept) async {
    final prompt =
        'Explain $concept in simple terms that a student would understand.';
    return await generateResponse(prompt);
  }
}
