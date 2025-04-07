import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key, required this.tripPreferences});
  final TripPreferences tripPreferences;

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

enum SortOption { recommended, highestRated, priceHighToLow, priceLowToHigh, nameAZ, nameZA }

class _RecommendationScreenState extends State<RecommendationScreen> {
  final GeminiService _geminiService = GeminiService();
  late Future<Map<String, dynamic>> _recommendationsFuture;

  final Set<String> _selectedAttractions = {};
  final Set<String> _selectedRestaurants = {};

  SortOption _attractionSortOption = SortOption.recommended;
  SortOption _restaurantSortOption = SortOption.recommended;

  bool _isAttractionSortVisible = false;
  bool _isRestaurantSortVisible = false;

  List<AttractionRecommendation> _allAttractions = [];
  List<RestaurantRecommendation> _allRestaurants = [];

  List<AttractionRecommendation> _displayedAttractions = [];
  List<RestaurantRecommendation> _displayedRestaurants = [];

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = _geminiService.getRecommendations(widget.tripPreferences);
  }

  void _sortAttractions() {
    setState(() {
      switch (_attractionSortOption) {
        case SortOption.recommended:
          _displayedAttractions = List.from(_allAttractions);
        case SortOption.highestRated:
          _displayedAttractions.sort((a, b) => b.rating.compareTo(a.rating));
        case SortOption.priceHighToLow:
          _displayedAttractions.sort((a, b) => b.priceRange.length.compareTo(a.priceRange.length));
        case SortOption.priceLowToHigh:
          _displayedAttractions.sort((a, b) => a.priceRange.length.compareTo(b.priceRange.length));
        case SortOption.nameAZ:
          _displayedAttractions.sort((a, b) => a.name.compareTo(b.name));
        case SortOption.nameZA:
          _displayedAttractions.sort((a, b) => b.name.compareTo(a.name));
      }
    });
  }

  void _sortRestaurants() {
    setState(() {
      switch (_restaurantSortOption) {
        case SortOption.recommended:
          _displayedRestaurants = List.from(_allRestaurants);
        case SortOption.highestRated:
          _displayedRestaurants.sort((a, b) => b.rating.compareTo(a.rating));
        case SortOption.priceHighToLow:
          _displayedRestaurants.sort((a, b) => b.priceRange.length.compareTo(a.priceRange.length));
        case SortOption.priceLowToHigh:
          _displayedRestaurants.sort((a, b) => a.priceRange.length.compareTo(b.priceRange.length));
        case SortOption.nameAZ:
          _displayedRestaurants.sort((a, b) => a.name.compareTo(b.name));
        case SortOption.nameZA:
          _displayedRestaurants.sort((a, b) => b.name.compareTo(a.name));
      }
    });
  }

  String _getSortOptionText(SortOption option) {
    switch (option) {
      case SortOption.recommended:
        return 'Recommended';
      case SortOption.highestRated:
        return 'Highest Rated';
      case SortOption.priceHighToLow:
        return 'Price: High to Low';
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SortOption.nameAZ:
        return 'Name: A to Z';
      case SortOption.nameZA:
        return 'Name: Z to A';
    }
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
            _allAttractions = recommendations['attractions'] ?? [];
            _allRestaurants = recommendations['restaurants'] ?? [];

            if (_displayedAttractions.isEmpty) {
              _displayedAttractions = List.from(_allAttractions);
            }
            if (_displayedRestaurants.isEmpty) {
              _displayedRestaurants = List.from(_allRestaurants);
            }

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
                        _buildAttractionsTab(),

                        // Restaurants Tab
                        _buildRestaurantsTab(),
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

  Widget _buildAttractionsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Sort button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAttractionSortVisible = !_isAttractionSortVisible;
                    if (_isAttractionSortVisible) {
                      _isRestaurantSortVisible = false;
                    }
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort, size: 18, color: Colors.grey[800]),
                    const SizedBox(width: 8),
                    Text(
                      'Sort: ${_getSortOptionText(_attractionSortOption)}',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                    ),
                    const SizedBox(width: 4),
                    Icon(_isAttractionSortVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: Colors.grey[800]),
                  ],
                ),
              ),

              // Dropdown options
              if (_isAttractionSortVisible)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        SortOption.values.map((option) {
                          final bool isSelected = option == _attractionSortOption;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _attractionSortOption = option;
                                _isAttractionSortVisible = false;
                                _sortAttractions();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFF5F0E5) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSelected ? Colors.black : Colors.transparent, width: isSelected ? 1.0 : 0),
                              ),
                              child: Text(
                                _getSortOptionText(option),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.black : Colors.grey[800],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // Spacing between sort filter and first item
        const SizedBox(height: 4),

        // Attraction items
        ..._displayedAttractions.map((attraction) {
          final bool isSelected = _selectedAttractions.contains(attraction.name);

          return Container(
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
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedAttractions.remove(attraction.name);
                  } else {
                    _selectedAttractions.add(attraction.name);
                  }
                });
              },
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
        }),
      ],
    );
  }

  Widget _buildRestaurantsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        // Sort filter at the top that scrolls away
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Sort button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isRestaurantSortVisible = !_isRestaurantSortVisible;
                    if (_isRestaurantSortVisible) {
                      _isAttractionSortVisible = false;
                    }
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort, size: 18, color: Colors.grey[800]),
                    const SizedBox(width: 8),
                    Text(
                      'Sort: ${_getSortOptionText(_restaurantSortOption)}',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                    ),
                    const SizedBox(width: 4),
                    Icon(_isRestaurantSortVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: Colors.grey[800]),
                  ],
                ),
              ),

              // Dropdown options
              if (_isRestaurantSortVisible)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        SortOption.values.map((option) {
                          final bool isSelected = option == _restaurantSortOption;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _restaurantSortOption = option;
                                _isRestaurantSortVisible = false;
                                _sortRestaurants();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFF5F0E5) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSelected ? Colors.black : Colors.transparent, width: isSelected ? 1.0 : 0),
                              ),
                              child: Text(
                                _getSortOptionText(option),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.black : Colors.grey[800],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // Spacing between sort filter and first item
        const SizedBox(height: 4),

        // Restaurant items
        ..._displayedRestaurants.map((restaurant) {
          final bool isSelected = _selectedRestaurants.contains(restaurant.name);

          return Container(
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
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedRestaurants.remove(restaurant.name);
                  } else {
                    _selectedRestaurants.add(restaurant.name);
                  }
                });
              },
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
        }),
      ],
    );
  }
}
