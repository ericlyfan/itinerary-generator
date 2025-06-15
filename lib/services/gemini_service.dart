import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';
import 'places_service.dart';
import 'supabase_service.dart';
import '../models.dart';

class GeminiService {
  final String apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';
  final PlacesApiService _placesApiService = PlacesApiService();
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0, errorMethodCount: 3, lineLength: 80));
  final SupabaseService _supabaseService = SupabaseService();

  Future<Map<String, dynamic>> getRecommendations(TripPreferences preferences, String itineraryId) async {
    try {
      final prompt = _buildPrompt(preferences);
      _logger.i('Generating recommendations for ${preferences.destination} (Itinerary: $itineraryId)');
      final model = GenerativeModel(
        model: 'models/gemini-2.5-flash-preview-05-20',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 1.3,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
          responseMimeType: 'application/json',
        ),
      );

      // Generate context with Gemini
      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        _logger.e('Empty response from Gemini API');
        throw Exception('Empty response from Gemini API');
      }

      try {
        // Create a fallback mechanism to extract attractions and restaurants directly
        final Map<String, dynamic> fallbackResults = {
          'attractions': <AttractionRecommendation>[],
          'restaurants': <RestaurantRecommendation>[],
        };

        // First attempt: Try to parse the entire JSON
        try {
          String cleanedJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();

          final recommendationsJson = jsonDecode(cleanedJson);
          final List<String> attractionsFound = [];
          final List<String> restaurantsFound = [];

          // Extract attractions
          if (recommendationsJson['attractions'] != null) {
            for (var item in recommendationsJson['attractions']) {
              final attraction = AttractionRecommendation.fromJson(item);
              attractionsFound.add(attraction.name);
              fallbackResults['attractions'].add(attraction);
            }
          }

          // Extract restaurants
          if (recommendationsJson['restaurants'] != null) {
            for (var item in recommendationsJson['restaurants']) {
              final restaurant = RestaurantRecommendation.fromJson(item);
              restaurantsFound.add(restaurant.name);
              fallbackResults['restaurants'].add(restaurant);
            }
          }

          // Update the itinerary with found place names
          await _supabaseService.updateFoundPlaces(
            itineraryId: itineraryId,
            attractionsFound: attractionsFound,
            restaurantsFound: restaurantsFound,
          );

          await _fetchImagesForPlaces(fallbackResults, preferences.destination);

          return fallbackResults;
        } catch (e) {
          _logger.e('Failed to parse Gemini response', error: e);
          return fallbackResults;
        }
      } catch (e) {
        _logger.e('Failed to process response', error: e);
        throw Exception('Failed to parse response: $e');
      }
    } catch (e) {
      _logger.e('Error generating recommendations', error: e);
      throw Exception('Error generating recommendations: $e');
    }
  }

  Future<List<AttractionRecommendation>> getMoreAttractions(TripPreferences preferences, String itineraryId) async {
    try {
      final itinerary =
          await _supabaseService.supabase.from('itineraries').select('attractions_found, restaurants_found').eq('id', itineraryId).single();

      final List<String> existingAttractions =
          itinerary['attractions_found'] != null ? List<String>.from(itinerary['attractions_found']) : [];

      final List<String> existingRestaurants =
          itinerary['restaurants_found'] != null ? List<String>.from(itinerary['restaurants_found']) : [];

      final prompt = _buildMorePrompt(preferences, existingItems: existingAttractions, isAttraction: true);

      _logger.i('Generating more attractions for ${preferences.destination} (Itinerary: $itineraryId)');

      final model = GenerativeModel(
        model: 'models/gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 1.3,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
          responseMimeType: 'application/json',
        ),
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        _logger.e('Empty response from Gemini API for more attractions');
        throw Exception('Empty response from Gemini API');
      }

      // Create a list for new recommendations
      final List<AttractionRecommendation> moreAttractions = [];
      final List<String> newAttractionNames = [];

      try {
        String cleanedJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();

        final recommendationsJson = jsonDecode(cleanedJson);

        // Extract new attractions
        if (recommendationsJson['attractions'] != null) {
          for (var item in recommendationsJson['attractions']) {
            final attraction = AttractionRecommendation.fromJson(item);
            if (!existingAttractions.contains(attraction.name)) {
              newAttractionNames.add(attraction.name);
              moreAttractions.add(attraction);
            }
          }
        }

        // Add the new attractions to the existing list
        final List<String> allAttractions = [...existingAttractions, ...newAttractionNames];
        await _supabaseService.updateFoundPlaces(
          itineraryId: itineraryId,
          attractionsFound: allAttractions,
          restaurantsFound: existingRestaurants,
        );

        await _fetchImagesForAttractions(moreAttractions, preferences.destination);

        return moreAttractions;
      } catch (e) {
        _logger.e('Failed to parse Gemini response for more attractions', error: e);
        return moreAttractions;
      }
    } catch (e) {
      _logger.e('Error generating more attractions', error: e);
      throw Exception('Error generating more attractions: $e');
    }
  }

  Future<List<RestaurantRecommendation>> getMoreRestaurants(TripPreferences preferences, String itineraryId) async {
    try {
      final itinerary =
          await _supabaseService.supabase.from('itineraries').select('restaurants_found, attractions_found').eq('id', itineraryId).single();

      final List<String> existingRestaurants =
          itinerary['restaurants_found'] != null ? List<String>.from(itinerary['restaurants_found']) : [];

      final List<String> existingAttractions =
          itinerary['attractions_found'] != null ? List<String>.from(itinerary['attractions_found']) : [];

      final prompt = _buildMorePrompt(preferences, existingItems: existingRestaurants, isAttraction: false);

      _logger.i('Generating more restaurants for ${preferences.destination} (Itinerary: $itineraryId)');

      final model = GenerativeModel(
        model: 'models/gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 1.3,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
          responseMimeType: 'application/json',
        ),
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        _logger.e('Empty response from Gemini API for more restaurants');
        throw Exception('Empty response from Gemini API');
      }

      // Create a list for new recommendations
      final List<RestaurantRecommendation> moreRestaurants = [];
      final List<String> newRestaurantNames = [];

      try {
        String cleanedJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();

        final recommendationsJson = jsonDecode(cleanedJson);

        // Extract new restaurants
        if (recommendationsJson['restaurants'] != null) {
          for (var item in recommendationsJson['restaurants']) {
            final restaurant = RestaurantRecommendation.fromJson(item);
            if (!existingRestaurants.contains(restaurant.name)) {
              newRestaurantNames.add(restaurant.name);
              moreRestaurants.add(restaurant);
            }
          }
        }

        // Add the new restaurants to the existing list
        final List<String> allRestaurants = [...existingRestaurants, ...newRestaurantNames];
        await _supabaseService.updateFoundPlaces(
          itineraryId: itineraryId,
          attractionsFound: existingAttractions,
          restaurantsFound: allRestaurants,
        );

        await _fetchImagesForRestaurants(moreRestaurants, preferences.destination);

        return moreRestaurants;
      } catch (e) {
        _logger.e('Failed to parse Gemini response for more restaurants', error: e);
        return moreRestaurants;
      }
    } catch (e) {
      _logger.e('Error generating more restaurants', error: e);
      throw Exception('Error generating more restaurants: $e');
    }
  }

  Future<void> _fetchImagesForAttractions(List<AttractionRecommendation> attractions, String destination) async {
    _logger.i('Fetching images for ${attractions.length} attractions');

    for (var i = 0; i < attractions.length; i++) {
      try {
        final imageUrls = await _placesApiService.getPlaceImageUrls(attractions[i].name, 'attraction', destination);
        attractions[i].imageUrls = imageUrls;
      } catch (e) {
        _logger.e('Error fetching images for attraction ${attractions[i].name}', error: e);
      }
    }
  }

  Future<void> _fetchImagesForRestaurants(List<RestaurantRecommendation> restaurants, String destination) async {
    _logger.i('Fetching images for ${restaurants.length} restaurants');

    for (var i = 0; i < restaurants.length; i++) {
      try {
        final imageUrls = await _placesApiService.getPlaceImageUrls(restaurants[i].name, 'restaurant', destination);
        restaurants[i].imageUrls = imageUrls;
      } catch (e) {
        _logger.e('Error fetching images for restaurant ${restaurants[i].name}', error: e);
      }
    }
  }

  Future<void> _fetchImagesForPlaces(Map<String, dynamic> results, String destination) async {
    _logger.i('Fetching images for ${results['attractions'].length} attractions and ${results['restaurants'].length} restaurants');

    // Fetch images for attractions
    List<AttractionRecommendation> attractions = results['attractions'];
    for (var i = 0; i < attractions.length; i++) {
      try {
        final imageUrls = await _placesApiService.getPlaceImageUrls(attractions[i].name, 'attraction', destination);
        attractions[i].imageUrls = imageUrls;
      } catch (e) {
        _logger.e('Error fetching images for attraction ${attractions[i].name}', error: e);
      }
    }

    // Fetch images for restaurants
    List<RestaurantRecommendation> restaurants = results['restaurants'];
    for (var i = 0; i < restaurants.length; i++) {
      try {
        final imageUrls = await _placesApiService.getPlaceImageUrls(restaurants[i].name, 'restaurant', destination);
        restaurants[i].imageUrls = imageUrls;
      } catch (e) {
        _logger.e('Error fetching images for restaurant ${restaurants[i].name}', error: e);
      }
    }
  }

  String _buildPrompt(TripPreferences preferences) {
    return '''
    I'm planning a trip to ${preferences.destination}. To help me plan, I'm providing the following preferences:

    * **Destination:** ${preferences.destination}
    * **Dates:** ${preferences.startDate != null && preferences.endDate != null ? 'From ${preferences.startDate!.toIso8601String()} to ${preferences.endDate!.toIso8601String()}.' : 'Dates are flexible.'}
    * **Group Size:** ${preferences.adults} adults, ${preferences.children} children, ${preferences.infants} infants, and ${preferences.pets} pets. (Please consider accessibility and pet-friendliness when making recommendations.)
    * **Trip Types:** ${preferences.tripTypes.isNotEmpty ? preferences.tripTypes.join(', ') : 'No specific trip type specified.'}
    * **Travel Style:** ${preferences.travelStyles.isNotEmpty ? preferences.travelStyles.join(', ') : 'No specific travel style specified.'}
    * **Activities:** ${preferences.activities.isNotEmpty ? preferences.activities.join(', ') : 'Open to all activities.'}
    * **Dining:** ${preferences.diningPreferences.isNotEmpty ? preferences.diningPreferences.join(', ') : 'No specific dining preferences.'}
    * **Considerations:** ${preferences.considerations.isNotEmpty ? preferences.considerations.join(', ') : 'No special considerations.'}
    * **Special Requests:** ${preferences.specialRequests.isNotEmpty ? preferences.specialRequests : 'None'}

    Based on **my destination and preferences** (especially the activities and dining preferences), please provide **at least 20 attractions** and **at least 20 restaurants** in **${preferences.destination}**. Strive for a diverse range of options that align with my stated preferences. Prioritize providing recommendations that are highly relevant to my indicated activities, dining preferences, accessibility needs (based on group size), and other considerations. Recommendations will be displayed incrementally, so ensure variety across the entire set.

    Return the results in the following JSON format. It is **crucial** that the JSON is valid and complete. Ensure that the response adheres strictly to the schema provided below. If you cannot find enough information to completely fulfill a particular attribute (e.g., rating, priceRange, timeNeeded), omit that attribute from the JSON object for that specific attraction/restaurant. If you cannot find any attractions or restaurants that match my preferences, return an empty list for that category (e.g., `"attractions": []`).

    For each attraction and restaurant:

    *   **name:** The name of the attraction or restaurant (String).
    *   **description:** A concise description of the attraction or restaurant (String).  Focus on features relevant to the user's preferences.
    *   **rating:** A numerical rating from 1 to 5. The rating *must* be based on aggregated data from multiple reputable sources.

        *   **Rating Criteria:** When determining the rating, systematically gather information from multiple sources such as Google Reviews, TripAdvisor, Yelp, and official websites.
        *   **Aggregate Sentiment:** Use the aggregate sentiment and overall score from these diverse sources to calculate the final rating, aiming for a fair and representative assessment. Prioritize recency and volume of reviews.

    *   **priceRange:** A string representing the price range using "\$" symbols (e.g., "\$", "\$\$", "\$\$\$", "\$\$\$\$") (String). 
        *   **IMPORTANT NOTE:** In the JSON response, ensure that the priceRange field uses standard dollar signs directly. Do not escape dollar signs (\$) in your response. The escaped dollar signs (\$) in this prompt are due to my implementation constraints and must not appear in your JSON output.

    *   **timeNeeded:** An estimate of the total visit duration, expressed as a string. Use a time range (e.g., "1-2 hours") or a single estimate (e.g., "Half day").  Be realistic and consider the following factors: (String).

        *   **Visit Duration Factors:**
            *   Prioritize official websites for recommended visit times.
            *   Factor in potential wait times based on popularity, seasonality, and day of the week.
            *   Consider online reviews and recommendations regarding how much time other visitors spent.
            *   Estimate visit time based on the size and scope of the attraction.

        *   **Information Gathering:** Attempt to gather information from Google Maps, official websites, or reputable travel sites. If direct recommendations for time needed are unavailable, base the estimate on reviews, site size, scope, and other quantifiable information.

    For attractions:

    *   **category:** A category describing the type of attraction (e.g., "Museum", "Outdoor", "Historical", "Art", "Family-Friendly") (String).

    For restaurants:

    *   **cuisine:** The type of cuisine served at the restaurant (e.g., "Italian", "Mexican", "French", "American") (String).
    *   **category:** A category describing the type of restaurant (e.g., "Fine Dining", "Casual", "Bistro", "Cafe", "Family-Friendly", "Vegan") (String).

    ```json
    {
      "attractions": [
        {
          "name": "Attraction Name",
          "description": "Brief description of the attraction, highlighting relevant features based on user preferences.",
          "timeNeeded": "Estimated visit duration (e.g., 1-2 hours, Half day, Full day)",
          "category": "Category (e.g., Museum, Outdoor, Historical, Art, Family-Friendly, etc.)",
          "priceRange": "\$-\$\$\$\$",
          "rating": 4.5
        },
        ...more attractions (at least 19 more)
      ],
      "restaurants": [
        {
          "name": "Restaurant Name",
          "description": "Brief description of the restaurant, highlighting relevant features based on user preferences.",
          "cuisine": "Cuisine type (e.g., Italian, Mexican, French, American, etc.)",
          "category": "Category (e.g., Fine Dining, Casual, Bistro, Cafe, Family-Friendly, Vegan, etc.)",
          "priceRange": "\$-\$\$\$\$",
          "rating": 4.5
        },-
        ...more restaurants (at least 19 more)
      ]
    }
    ''';
  }

  String _buildMorePrompt(TripPreferences preferences, {required List<String> existingItems, required bool isAttraction}) {
    final itemType = isAttraction ? 'attractions' : 'restaurants';
    final excludeItemsText =
        existingItems.isEmpty
            ? ''
            : '\n\n**IMPORTANT: DO NOT include any of these $itemType that I already have:**\n${existingItems.map((name) => '* $name').join('\n')}';

    return '''
      I'm continuing my trip planning to ${preferences.destination} and need additional $itemType. To help me plan, I'm providing the following preferences:

      * **Destination:** ${preferences.destination}
      * **Dates:** ${preferences.startDate != null && preferences.endDate != null ? 'From ${preferences.startDate!.toIso8601String()} to ${preferences.endDate!.toIso8601String()}.' : 'Dates are flexible.'}
      * **Group Size:** ${preferences.adults} adults, ${preferences.children} children, ${preferences.infants} infants, and ${preferences.pets} pets. (Please consider accessibility and pet-friendliness when making recommendations.)
      * **Trip Types:** ${preferences.tripTypes.isNotEmpty ? preferences.tripTypes.join(', ') : 'No specific trip type specified.'}
      * **Travel Style:** ${preferences.travelStyles.isNotEmpty ? preferences.travelStyles.join(', ') : 'No specific travel style specified.'}
      * **Activities:** ${preferences.activities.isNotEmpty ? preferences.activities.join(', ') : 'Open to all activities.'}
      * **Dining:** ${preferences.diningPreferences.isNotEmpty ? preferences.diningPreferences.join(', ') : 'No specific dining preferences.'}
      * **Considerations:** ${preferences.considerations.isNotEmpty ? preferences.considerations.join(', ') : 'No special considerations.'}
      * **Special Requests:** ${preferences.specialRequests.isNotEmpty ? preferences.specialRequests : 'None'}
      $excludeItemsText

      Based on **my destination and preferences** (especially the ${isAttraction ? 'activities' : 'dining preferences'}), please provide **10 MORE $itemType** in **${preferences.destination}**. Strive for a diverse range of options that align with my stated preferences. Prioritize providing recommendations that are highly relevant to my indicated ${isAttraction ? 'activities' : 'dining preferences'}, accessibility needs (based on group size), and other considerations.

      IMPORTANT: Please ensure these are DIFFERENT recommendations than what I already have listed above. I need unique $itemType that don't overlap with my existing selections.

      Return the results in the following JSON format. It is **crucial** that the JSON is valid and complete. Ensure that the response adheres strictly to the schema provided below. If you cannot find enough information to completely fulfill a particular attribute (e.g., rating, priceRange, ${isAttraction ? 'timeNeeded' : 'cuisine'}), omit that attribute from the JSON object for that specific ${isAttraction ? 'attraction' : 'restaurant'}.

      For each ${isAttraction ? 'attraction' : 'restaurant'}:

      *   **name:** The name of the ${isAttraction ? 'attraction' : 'restaurant'} (String).
      *   **description:** A concise description of the ${isAttraction ? 'attraction' : 'restaurant'} (String). Focus on features relevant to my preferences.
      *   **rating:** A numerical rating from 1 to 5. The rating *must* be based on aggregated data from multiple reputable sources.
      *   **priceRange:** A string representing the price range using "\$" symbols (e.g., "\$", "\$\$", "\$\$\$", "\$\$\$\$") (String). 
      *       **IMPORTANT NOTE:** In the JSON response, ensure that the priceRange field uses standard dollar signs directly. Do not escape dollar signs (\$) in your response. The escaped dollar signs (\$) in this prompt are due to my implementation constraints and must not appear in your JSON output.
      ${isAttraction ? '''*   **timeNeeded:** An estimate of the total visit duration, expressed as a string. Use a time range (e.g., "1-2 hours") or a single estimate (e.g., "Half day").
      *   **category:** A category describing the type of attraction (e.g., "Museum", "Outdoor", "Historical", "Art", "Family-Friendly") (String).''' : '''*   **cuisine:** The type of cuisine served at the restaurant (e.g., "Italian", "Mexican", "French", "American") (String).
      *   **category:** A category describing the type of restaurant (e.g., "Fine Dining", "Casual", "Bistro", "Cafe", "Family-Friendly", "Vegan") (String).'''}

      ```json
      {
        "$itemType": [
          {
            "name": "${isAttraction ? 'Attraction' : 'Restaurant'} Name",
            "description": "Brief description highlighting relevant features based on user preferences.",
            ${isAttraction ? '"timeNeeded": "Estimated visit duration (e.g., 1-2 hours, Half day, Full day)",' : '"cuisine": "Cuisine type (e.g., Italian, Mexican, French, American, etc.)",'}
            "category": "${isAttraction ? "Category (e.g., Museum, Outdoor, Historical, Art, etc.)" : "Category (e.g., Fine Dining, Casual, Bistro, Cafe, etc.)"}",
            "priceRange": "\$-\$\$\$\$",
            "rating": 4.5
          },
          ...more $itemType (at least 9 more)
        ]
      }
      ```

      I need ONLY new recommendations that I haven't already seen. Please verify that none of your recommendations match any names in my exclusion list.
      ''';
  }

  void dispose() {
    _logger.close();
  }
}
