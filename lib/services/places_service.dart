import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlacesApiService {
  PlacesApiService();
  final String apiKey = dotenv.env['PLACES_API_KEY'] ?? '';

  Future<List<String>> fetchPlaceSuggestions(String input) async {
    const String url = 'https://places.googleapis.com/v1/places:autocomplete';

    final Map<String, dynamic> requestBody = {'input': input};

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'X-Goog-Api-Key': apiKey, 'X-Goog-FieldMask': 'suggestions.placePrediction.text'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.containsKey('suggestions')) {
        final List suggestions = data['suggestions'];
        return suggestions
            .map((suggestion) {
              if (suggestion.containsKey('placePrediction') &&
                  suggestion['placePrediction'].containsKey('text') &&
                  suggestion['placePrediction']['text'].containsKey('text')) {
                return suggestion['placePrediction']['text']['text'] as String;
              }
              return '';
            })
            .where((text) => text.isNotEmpty)
            .toList();
      }
      return [];
    } else {
      throw Exception('Failed to load suggestions (Status: ${response.statusCode})');
    }
  }
}
