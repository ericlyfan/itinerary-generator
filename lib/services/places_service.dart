import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class PlacesApiService {
  PlacesApiService();
  final String apiKey = dotenv.env['PLACES_API_KEY'] ?? '';
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0, errorMethodCount: 3, lineLength: 80));
  final Map<String, List<String>> _imageUrlsCache = {};

  Future<List<String>> fetchPlaceSuggestions(String input) async {
    const String url = 'https://places.googleapis.com/v1/places:autocomplete';
    final Map<String, dynamic> requestBody = {'input': input};

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'X-Goog-Api-Key': apiKey, 'X-Goog-FieldMask': 'suggestions.placePrediction.text'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('suggestions')) {
          final List suggestions = data['suggestions'];
          final result =
              suggestions
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

          return result;
        }
        return [];
      } else {
        _logger.e('Error fetching suggestions', error: 'Status ${response.statusCode}');
        throw Exception('Failed to load suggestions (Status: ${response.statusCode})');
      }
    } catch (e, stackTrace) {
      _logger.e('Exception fetching suggestions', error: e, stackTrace: stackTrace);
      throw Exception('Failed to load suggestions: $e');
    }
  }

  Future<List<String>> getPlaceImageUrls(String placeName, String placeType, String location) async {
    final cacheKey = '$placeName-$placeType-$location';

    if (_imageUrlsCache.containsKey(cacheKey)) {
      return _imageUrlsCache[cacheKey]!;
    }

    try {
      final placeId = await _getPlaceId(placeName, placeType, location);
      if (placeId.isEmpty) {
        _logger.i('No place ID found for: $placeName in $location');
        return [];
      }

      final photoNames = await _getPhotoNames(placeId);
      if (photoNames.isEmpty) {
        _logger.i('No photos found for: $placeName');
        return [];
      }

      // Create URLs for each photo using the Places Photo API format
      final List<String> imageUrls =
          photoNames.map((photoName) => 'https://places.googleapis.com/v1/$photoName/media?maxWidthPx=600&key=$apiKey').toList();

      _imageUrlsCache[cacheKey] = imageUrls;

      return imageUrls;
    } catch (e, stackTrace) {
      _logger.e('Error fetching images for $placeName', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<String> _getPlaceId(String placeName, String placeType, String location) async {
    final String url = 'https://places.googleapis.com/v1/places:searchText';
    final Map<String, dynamic> requestBody = {'textQuery': '$placeName $placeType in $location'};

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'X-Goog-Api-Key': apiKey, 'X-Goog-FieldMask': 'places.id'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['places'] != null && data['places'].isNotEmpty) {
          return data['places'][0]['id'] ?? '';
        }
      } else {
        _logger.e('Places API error', error: 'Status ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _logger.e('Places API exception', error: e, stackTrace: stackTrace);
    }

    return '';
  }

  Future<List<String>> _getPhotoNames(String placeId) async {
    final url = 'https://places.googleapis.com/v1/places/$placeId';

    try {
      final response = await http.get(Uri.parse(url), headers: {'X-Goog-Api-Key': apiKey, 'X-Goog-FieldMask': 'photos'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['photos'] != null && data['photos'].isNotEmpty) {
          final photos = data['photos'] as List;
          final int photoCount = photos.length > 1 ? 1 : photos.length;

          List<String> names = [];
          for (int i = 0; i < photoCount; i++) {
            final name = photos[i]['name'] as String?;
            if (name != null && name.isNotEmpty) {
              names.add(name);
            }
          }

          return names;
        }
      } else {
        _logger.e('Error fetching photos', error: 'Status ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _logger.e('Exception fetching photos', error: e, stackTrace: stackTrace);
    }

    return [];
  }

  // Call this method when you're done with the service
  void dispose() {
    _logger.close();
  }
}
