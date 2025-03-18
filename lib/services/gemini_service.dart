import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AttractionRecommendation {
  AttractionRecommendation({
    required this.name,
    required this.description,
    required this.timeNeeded,
    required this.category,
    required this.priceRange,
    required this.rating,
  });

  factory AttractionRecommendation.fromJson(Map<String, dynamic> json) {
    return AttractionRecommendation(
      name: json['name'] as String,
      description: json['description'] as String,
      timeNeeded: json['timeNeeded'] as String,
      category: json['category'] as String,
      priceRange: json['priceRange'] as String,
      rating: json['rating'] as double,
    );
  }

  final String name;
  final String description;
  final String timeNeeded;
  final String category;
  final String priceRange;
  final double rating;
}

class RestaurantRecommendation {
  RestaurantRecommendation({
    required this.name,
    required this.description,
    required this.cuisine,
    required this.category,
    required this.priceRange,
    required this.rating,
  });

  factory RestaurantRecommendation.fromJson(Map<String, dynamic> json) {
    return RestaurantRecommendation(
      name: json['name'] as String,
      description: json['description'] as String,
      cuisine: json['cuisine'] as String,
      category: json['category'] as String,
      priceRange: json['priceRange'] as String,
      rating: json['rating'] as double,
    );
  }

  final String name;
  final String description;
  final String cuisine;
  final String category;
  final String priceRange;
  final double rating;
}

class TripPreferences {
  TripPreferences({
    required this.destination,
    this.startDate,
    this.endDate,
    required this.adults,
    required this.children,
    required this.infants,
    required this.pets,
    required this.tripTypes,
    required this.travelStyles,
    required this.activities,
    required this.diningPreferences,
    required this.considerations,
    required this.specialRequests,
  });

  Map<String, dynamic> toJson() {
    return {
      'destination': destination,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'tripDuration': startDate != null && endDate != null ? endDate!.difference(startDate!).inDays + 1 : null,
      'adults': adults,
      'children': children,
      'infants': infants,
      'pets': pets,
      'tripTypes': tripTypes,
      'travelStyles': travelStyles,
      'activities': activities,
      'diningPreferences': diningPreferences,
      'considerations': considerations,
      'specialRequests': specialRequests,
    };
  }

  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final int adults;
  final int children;
  final int infants;
  final int pets;
  final List<String> tripTypes;
  final List<String> travelStyles;
  final List<String> activities;
  final List<String> diningPreferences;
  final List<String> considerations;
  final String specialRequests;
}

class GeminiService {
  final String apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

  Future<Map<String, dynamic>> getRecommendations(TripPreferences preferences) async {
    try {
      final prompt = _buildPrompt(preferences);

      final model = GenerativeModel(
        model: 'models/gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
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
          // Clean up the response by removing code fences and trimming
          String cleanedJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();

          final recommendationsJson = jsonDecode(cleanedJson);

          // Extract attractions
          if (recommendationsJson['attractions'] != null) {
            for (var item in recommendationsJson['attractions']) {
              fallbackResults['attractions'].add(AttractionRecommendation.fromJson(item));
            }
          }

          // Extract restaurants
          if (recommendationsJson['restaurants'] != null) {
            for (var item in recommendationsJson['restaurants']) {
              fallbackResults['restaurants'].add(RestaurantRecommendation.fromJson(item));
            }
          }

          return fallbackResults;
        } catch (e) {
          return fallbackResults; // Return empty lists if all parsing attempts fail
        }
      } catch (e) {
        throw Exception('Failed to parse response: $e');
      }
    } catch (e) {
      throw Exception('Error generating recommendations: $e');
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
}
