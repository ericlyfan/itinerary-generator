import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import '../models.dart';

class LocalStorageService {
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();
  static final LocalStorageService _instance = LocalStorageService._internal();

  Future<File> _getFile() async {
    final dataPath = dotenv.env['DATA_PATH'];
    final String dirPath;
    if (dataPath != null && dataPath.isNotEmpty) {
      dirPath = dataPath;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      dirPath = dir.path;
    }
    await Directory(dirPath).create(recursive: true);
    return File('$dirPath/itineraries.json');
  }

  Future<List<Map<String, dynamic>>> _readAll() async {
    final file = await _getFile();
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    if (content.isEmpty) return [];
    final List<dynamic> data = jsonDecode(content);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> _writeAll(List<Map<String, dynamic>> itineraries) async {
    final file = await _getFile();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(itineraries));
  }

  Future<String> createItinerary({required TripPreferences preferences, required String title}) async {
    final all = await _readAll();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    all.add({
      'id': id,
      'title': title,
      'destination': preferences.destination,
      'start_date': preferences.startDate?.toIso8601String(),
      'end_date': preferences.endDate?.toIso8601String(),
      'preferences': preferences.toJson(),
      'selected_attractions': <Map<String, dynamic>>[],
      'selected_restaurants': <Map<String, dynamic>>[],
      'attractions_found': <String>[],
      'restaurants_found': <String>[],
      'finalized_itinerary': null,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _writeAll(all);
    return id;
  }

  Future<Map<String, dynamic>> getItinerary(String id) async {
    final all = await _readAll();
    return all.firstWhere((i) => i['id'] == id, orElse: () => throw Exception('Itinerary not found: $id'));
  }

  Future<List<Map<String, dynamic>>> getAllItineraries() => _readAll();

  Future<void> _updateItinerary(String id, Map<String, dynamic> updates) async {
    final all = await _readAll();
    final index = all.indexWhere((i) => i['id'] == id);
    if (index == -1) throw Exception('Itinerary not found: $id');
    all[index] = {...all[index], ...updates};
    await _writeAll(all);
  }

  Future<void> updateFoundPlaces({
    required String itineraryId,
    required List<String> attractionsFound,
    required List<String> restaurantsFound,
  }) => _updateItinerary(itineraryId, {'attractions_found': attractionsFound, 'restaurants_found': restaurantsFound});

  Future<void> updateItinerarySelections({
    required String itineraryId,
    required List<Map<String, dynamic>> selectedAttractions,
    required List<Map<String, dynamic>> selectedRestaurants,
  }) => _updateItinerary(itineraryId, {'selected_attractions': selectedAttractions, 'selected_restaurants': selectedRestaurants});

  Future<void> updatePreferences({required String itineraryId, required Map<String, dynamic> preferences}) =>
      _updateItinerary(itineraryId, {'preferences': preferences});

  Future<void> finalizeItinerary({required String itineraryId, required Map<String, dynamic> finalizedItinerary}) =>
      _updateItinerary(itineraryId, {'finalized_itinerary': finalizedItinerary});

  Future<void> deleteItinerary(String id) async {
    final all = await _readAll();
    all.removeWhere((i) => i['id'] == id);
    await _writeAll(all);
  }
}
