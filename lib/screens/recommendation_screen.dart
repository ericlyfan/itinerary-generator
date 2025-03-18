import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key, required this.tripPreferences});
  final TripPreferences tripPreferences;

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final GeminiService _geminiService = GeminiService();
  late Future<Map<String, dynamic>> _recommendationsFuture;

  final Set<String> _selectedAttractions = {};
  final Set<String> _selectedRestaurants = {};

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = _geminiService.getRecommendations(widget.tripPreferences);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recommendations', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _recommendationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SafeArea(
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE6D5C7))),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'Crafting your personalized itinerary...',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      "We're building recommendations based on your preferences for ${widget.tripPreferences.destination}.",
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error generating itinerary', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Error generating itinerary. Please try again later.', textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final recommendations = snapshot.data!;
            final List<AttractionRecommendation> attractions = recommendations['attractions'] ?? [];
            final List<RestaurantRecommendation> restaurants = recommendations['restaurants'] ?? [];

            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    color: Theme.of(context).appBarTheme.backgroundColor,
                    child: const TabBar(
                      tabs: [Tab(text: 'Attractions', icon: Icon(Icons.place)), Tab(text: 'Restaurants', icon: Icon(Icons.restaurant))],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Attractions Tab
                        _buildAttractionsList(attractions),

                        // Restaurants Tab
                        _buildRestaurantsList(restaurants),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No recommendations found. Try adjusting your preferences.'));
          }
        },
      ),
    );
  }

  Widget _buildAttractionsList(List<AttractionRecommendation> attractions) {
    if (attractions.isEmpty) {
      return const Center(child: Text('No attractions found for your preferences'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attractions.length,
      itemBuilder: (context, index) {
        final attraction = attractions[index];
        final bool isSelected = _selectedAttractions.contains(attraction.name);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedAttractions.remove(attraction.name);
              } else {
                _selectedAttractions.add(attraction.name);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF5F0E5) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? Colors.black : Colors.grey[300]!, width: isSelected ? 2.0 : 1.0),
              boxShadow:
                  isSelected
                      ? [BoxShadow(color: Colors.black.withAlpha(38), blurRadius: 4, offset: const Offset(0, 2))]
                      : [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          attraction.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: isSelected ? Colors.black : Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFE6D5C7), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.black87),
                            const SizedBox(width: 4),
                            Text(attraction.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected ? Border.all() : null,
                    ),
                    child: Text(
                      attraction.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.black : Colors.grey[800],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(attraction.description, style: TextStyle(fontSize: 14, color: isSelected ? Colors.black87 : Colors.grey[700])),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: isSelected ? Colors.black54 : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            attraction.timeNeeded,
                            style: TextStyle(
                              color: isSelected ? Colors.black54 : Colors.grey,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        attraction.priceRange,
                        style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.grey[800]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRestaurantsList(List<RestaurantRecommendation> restaurants) {
    if (restaurants.isEmpty) {
      return const Center(child: Text('No restaurants found for your preferences'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = restaurants[index];
        final bool isSelected = _selectedRestaurants.contains(restaurant.name);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedRestaurants.remove(restaurant.name);
              } else {
                _selectedRestaurants.add(restaurant.name);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF5F0E5) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? Colors.black : Colors.grey[300]!, width: isSelected ? 2.0 : 1.0),
              boxShadow:
                  isSelected
                      ? [BoxShadow(color: Colors.black.withAlpha(38), blurRadius: 4, offset: const Offset(0, 2))]
                      : [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: isSelected ? Colors.black : Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFE6D5C7), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.black87),
                            const SizedBox(width: 4),
                            Text(restaurant.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF5F0E5) : Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                              border: isSelected ? Border.all() : null,
                            ),
                            child: Text(
                              restaurant.cuisine,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.black : Colors.grey[800],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF5F0E5) : Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                              border: isSelected ? Border.all() : null,
                            ),
                            child: Text(
                              restaurant.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.black : Colors.grey[800],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        restaurant.priceRange,
                        style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.grey[800]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(restaurant.description, style: TextStyle(fontSize: 14, color: isSelected ? Colors.black87 : Colors.grey[700])),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
