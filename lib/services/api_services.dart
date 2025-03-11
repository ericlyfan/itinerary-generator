import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlacesApiService {
  final String apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

  Future<List<String>> fetchPlaceSuggestions(String input) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List predictions = data['predictions'];
      return predictions.map((prediction) => prediction['description'] as String).toList();
    } else {
      throw Exception('Failed to load suggestions');
    }
  }
}
