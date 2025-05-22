import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../services/gemini_service.dart';
import '../services/supabase_service.dart';
import '../models.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key, required this.tripPreferences, required this.itineraryId});
  final TripPreferences tripPreferences;
  final String itineraryId;

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

enum SortOption { recommended, highestRated, priceHighToLow, priceLowToHigh, nameAZ, nameZA }

class _RecommendationScreenState extends State<RecommendationScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _recommendationsFuture;
  final GeminiService _geminiService = GeminiService();
  final SupabaseService _supabaseService = SupabaseService();
  final Set<String> _selectedAttractions = {};
  final Set<String> _selectedRestaurants = {};

  SortOption _attractionSortOption = SortOption.recommended;
  SortOption _restaurantSortOption = SortOption.recommended;

  Map<String, List<String>> _editedPreferences = {};
  List<AttractionRecommendation> _allAttractions = [];
  List<RestaurantRecommendation> _allRestaurants = [];
  List<AttractionRecommendation> _displayedAttractions = [];
  List<RestaurantRecommendation> _displayedRestaurants = [];

  bool _isAttractionSortVisible = false;
  bool _isRestaurantSortVisible = false;
  bool _isLoadingMoreAttractions = false;
  bool _isLoadingMoreRestaurants = false;
  bool _isProcessingPreferences = false;

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = _geminiService.getRecommendations(widget.tripPreferences, widget.itineraryId);

    _tabController = TabController(length: 2, vsync: this);
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

  Future<void> _loadMoreAttractions() async {
    if (_isLoadingMoreAttractions) return;

    setState(() {
      _isLoadingMoreAttractions = true;
    });

    try {
      final response = await _supabaseService.supabase.from('itineraries').select('preferences').eq('id', widget.itineraryId).single();
      final preferencesData = response['preferences'];

      // Create a TripPreferences object from the fetched data
      final currentPreferences = TripPreferences(
        destination: preferencesData['destination'],
        startDate: preferencesData['startDate'] != null ? DateTime.parse(preferencesData['startDate']) : null,
        endDate: preferencesData['endDate'] != null ? DateTime.parse(preferencesData['endDate']) : null,
        adults: preferencesData['adults'] ?? 1,
        children: preferencesData['children'] ?? 0,
        infants: preferencesData['infants'] ?? 0,
        pets: preferencesData['pets'] ?? 0,
        tripTypes: List<String>.from(preferencesData['tripTypes'] ?? []),
        travelStyles: List<String>.from(preferencesData['travelStyles'] ?? []),
        activities: List<String>.from(preferencesData['activities'] ?? []),
        diningPreferences: List<String>.from(preferencesData['diningPreferences'] ?? []),
        considerations: List<String>.from(preferencesData['considerations'] ?? []),
        specialRequests: preferencesData['specialRequests'] ?? '',
      );

      final moreAttractions = await _geminiService.getMoreAttractions(currentPreferences, widget.itineraryId);

      if (!mounted) return;

      setState(() {
        _allAttractions.addAll(moreAttractions);
        _displayedAttractions = List.from(_allAttractions);
        _sortAttractions();
        _isLoadingMoreAttractions = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load more attractions: ${e.toString()}'), backgroundColor: Colors.red));
      }

      if (mounted) {
        setState(() {
          _isLoadingMoreAttractions = false;
        });
      }
    }
  }

  Future<void> _loadMoreRestaurants() async {
    if (_isLoadingMoreRestaurants) return;

    setState(() {
      _isLoadingMoreRestaurants = true;
    });

    try {
      final response = await _supabaseService.supabase.from('itineraries').select('preferences').eq('id', widget.itineraryId).single();
      final preferencesData = response['preferences'];

      // Create a TripPreferences object from the fetched data
      final currentPreferences = TripPreferences(
        destination: preferencesData['destination'],
        startDate: preferencesData['startDate'] != null ? DateTime.parse(preferencesData['startDate']) : null,
        endDate: preferencesData['endDate'] != null ? DateTime.parse(preferencesData['endDate']) : null,
        adults: preferencesData['adults'] ?? 1,
        children: preferencesData['children'] ?? 0,
        infants: preferencesData['infants'] ?? 0,
        pets: preferencesData['pets'] ?? 0,
        tripTypes: List<String>.from(preferencesData['tripTypes'] ?? []),
        travelStyles: List<String>.from(preferencesData['travelStyles'] ?? []),
        activities: List<String>.from(preferencesData['activities'] ?? []),
        diningPreferences: List<String>.from(preferencesData['diningPreferences'] ?? []),
        considerations: List<String>.from(preferencesData['considerations'] ?? []),
        specialRequests: preferencesData['specialRequests'] ?? '',
      );

      final moreRestaurants = await _geminiService.getMoreRestaurants(currentPreferences, widget.itineraryId);

      if (!mounted) return;

      setState(() {
        _allRestaurants.addAll(moreRestaurants);
        _displayedRestaurants = List.from(_allRestaurants);
        _sortRestaurants();
        _isLoadingMoreRestaurants = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load more restaurants: ${e.toString()}'), backgroundColor: Colors.red));
      }

      if (mounted) {
        setState(() {
          _isLoadingMoreRestaurants = false;
        });
      }
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

            _tabController ??= TabController(length: 2, vsync: this);

            return Column(
              children: [
                Container(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [Tab(text: 'Attractions', icon: Icon(Icons.place)), Tab(text: 'Restaurants', icon: Icon(Icons.restaurant))],
                  ),
                ),
                Expanded(child: TabBarView(controller: _tabController, children: [_buildAttractionsTab(), _buildRestaurantsTab()])),
              ],
            );
          } else {
            return const Center(child: Text('No recommendations found. Try adjusting your preferences.'));
          }
        },
      ),
    );
  }

  Widget _buildLoadingDots() {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // We use a faded background circle to maintain the space
          Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.1))),
          // Animated loading indicator with custom color
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreAttractionsButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: Row(
        children: [
          // Edit Parameters button
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showTripParametersDialog(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFFE6D5C7),
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.tune, size: 20), SizedBox(width: 8), Text('Edit Parameters')],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Discover More button
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoadingMoreAttractions ? null : _loadMoreAttractions,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF40C9A2),
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: const Color(0xFF40C9A2).withValues(alpha: 0.9),
                disabledForegroundColor: Colors.black.withValues(alpha: 0.8),
              ),
              child:
                  _isLoadingMoreAttractions
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [_buildLoadingDots(), const SizedBox(width: 8), const Text('Discovering...')],
                      )
                      : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.explore, size: 20), SizedBox(width: 8), Text('Discover More')],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreRestaurantsButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: Row(
        children: [
          // Edit Parameters button
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showTripParametersDialog(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFFE6D5C7),
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.tune, size: 20), SizedBox(width: 8), Text('Edit Parameters')],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Discover More Restaurants button
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoadingMoreRestaurants ? null : _loadMoreRestaurants,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF40C9A2),
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                // Ensure the button doesn't visually change too much when disabled
                disabledBackgroundColor: const Color(0xFF40C9A2).withValues(alpha: 0.9),
                disabledForegroundColor: Colors.black.withValues(alpha: 0.8),
              ),
              child:
                  _isLoadingMoreRestaurants
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated dots
                          _buildLoadingDots(),
                          const SizedBox(width: 8),
                          const Text('Discovering...'),
                        ],
                      )
                      : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.restaurant_menu, size: 20), SizedBox(width: 8), Text('Discover More')],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttractionsTab() {
    return Stack(
      children: [
        ListView(
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
                        Icon(
                          _isAttractionSortVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 18,
                          color: Colors.grey[800],
                        ),
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

            const SizedBox(height: 4),

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
                  onTap: () async {
                    setState(() {
                      if (isSelected) {
                        _selectedAttractions.remove(attraction.name);
                      } else {
                        _selectedAttractions.add(attraction.name);
                      }
                    });
                    await _supabaseService.updateItinerarySelections(
                      itineraryId: widget.itineraryId,
                      selectedAttractions:
                          _allAttractions.where((a) => _selectedAttractions.contains(a.name)).map((a) => a.toJson()).toList(),
                      selectedRestaurants:
                          _allRestaurants.where((r) => _selectedRestaurants.contains(r.name)).map((r) => r.toJson()).toList(),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image carousel
                      if (attraction.imageUrls.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          child: CarouselSlider(
                            options: CarouselOptions(
                              height: 250.0,
                              viewportFraction: 1.0,
                              enableInfiniteScroll: attraction.imageUrls.length > 1,
                              padEnds: false,
                            ),
                            items:
                                attraction.imageUrls.map((url) {
                                  return Builder(
                                    builder: (context) {
                                      return Image.network(
                                        url,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 250,
                                            color: Colors.grey[300],
                                            child: Center(child: Icon(Icons.place, size: 48, color: Colors.grey[600])),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            height: 250,
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE6D5C7)),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                }).toList(),
                          ),
                        )
                      else
                        Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: Center(child: Icon(Icons.place, size: 48, color: Colors.grey[600])),
                        ),

                      Padding(
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
                            Text(
                              attraction.description,
                              style: TextStyle(fontSize: 14, color: isSelected ? Colors.black87 : Colors.grey[700]),
                            ),
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
                    ],
                  ),
                ),
              );
            }),
            Padding(padding: const EdgeInsets.only(bottom: 16.0), child: _buildLoadMoreAttractionsButton()),
          ],
        ),
      ],
    );
  }

  Widget _buildRestaurantsTab() {
    return Stack(
      children: [
        ListView(
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
                        Icon(
                          _isRestaurantSortVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 18,
                          color: Colors.grey[800],
                        ),
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

            const SizedBox(height: 4),

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
                  onTap: () async {
                    setState(() {
                      if (isSelected) {
                        _selectedRestaurants.remove(restaurant.name);
                      } else {
                        _selectedRestaurants.add(restaurant.name);
                      }
                    });
                    await _supabaseService.updateItinerarySelections(
                      itineraryId: widget.itineraryId,
                      selectedAttractions:
                          _allAttractions.where((a) => _selectedAttractions.contains(a.name)).map((a) => a.toJson()).toList(),
                      selectedRestaurants:
                          _allRestaurants.where((r) => _selectedRestaurants.contains(r.name)).map((r) => r.toJson()).toList(),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image carousel
                      if (restaurant.imageUrls.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          child: CarouselSlider(
                            options: CarouselOptions(
                              height: 250.0,
                              viewportFraction: 1.0,
                              enableInfiniteScroll: restaurant.imageUrls.length > 1,
                              padEnds: false,
                            ),
                            items:
                                restaurant.imageUrls.map((url) {
                                  return Builder(
                                    builder: (context) {
                                      return Image.network(
                                        url,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 250,
                                            color: Colors.grey[300],
                                            child: Center(child: Icon(Icons.restaurant, size: 48, color: Colors.grey[600])),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            height: 250,
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE6D5C7)),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                }).toList(),
                          ),
                        )
                      else
                        Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: Center(child: Icon(Icons.restaurant, size: 48, color: Colors.grey[600])),
                        ),

                      Padding(
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
                            Text(
                              restaurant.description,
                              style: TextStyle(fontSize: 14, color: isSelected ? Colors.black87 : Colors.grey[700]),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            Padding(padding: const EdgeInsets.only(bottom: 16.0), child: _buildLoadMoreRestaurantsButton()),
          ],
        ),
      ],
    );
  }

  Future<void> _showTripParametersDialog() async {
    setState(() {
      _isProcessingPreferences = true;
    });

    try {
      final response = await _supabaseService.supabase.from('itineraries').select('preferences').eq('id', widget.itineraryId).single();
      final currentPreferences = response['preferences'];

      // Initialize edited preferences with the fetched preferences
      setState(() {
        _editedPreferences = {
          'tripTypes': List<String>.from(currentPreferences['tripTypes'] ?? []),
          'travelStyles': List<String>.from(currentPreferences['travelStyles'] ?? []),
          'activities': List<String>.from(currentPreferences['activities'] ?? []),
          'diningPreferences': List<String>.from(currentPreferences['diningPreferences'] ?? []),
          'considerations': List<String>.from(currentPreferences['considerations'] ?? []),
        };
        _isProcessingPreferences = false;
      });

      // Show the dialog with the current preferences
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return Dialog(
                  backgroundColor: Colors.grey[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Center(
                          child: Text(
                            'Trip Parameters',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),

                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 24),

                                // Trip Types
                                Text('Trip Types', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                _buildChipGroup(
                                  allOptions: _getTripTypeOptions(),
                                  selectedOptions: _editedPreferences['tripTypes']!,
                                  onSelectionChanged: (value) {
                                    setDialogState(() {
                                      if (_editedPreferences['tripTypes']!.contains(value)) {
                                        _editedPreferences['tripTypes']!.remove(value);
                                      } else {
                                        _editedPreferences['tripTypes']!.add(value);
                                      }
                                    });
                                  },
                                ),

                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 24),

                                // Travel Styles
                                Text(
                                  'Travel Styles',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                _buildChipGroup(
                                  allOptions: _getTravelStyleOptions(),
                                  selectedOptions: _editedPreferences['travelStyles']!,
                                  onSelectionChanged: (value) {
                                    setDialogState(() {
                                      if (_editedPreferences['travelStyles']!.contains(value)) {
                                        _editedPreferences['travelStyles']!.remove(value);
                                      } else {
                                        _editedPreferences['travelStyles']!.add(value);
                                      }
                                    });
                                  },
                                ),

                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 24),

                                // Activities
                                Text('Activities', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                _buildChipGroup(
                                  allOptions: _getActivityOptions(),
                                  selectedOptions: _editedPreferences['activities']!,
                                  onSelectionChanged: (value) {
                                    setDialogState(() {
                                      if (_editedPreferences['activities']!.contains(value)) {
                                        _editedPreferences['activities']!.remove(value);
                                      } else {
                                        _editedPreferences['activities']!.add(value);
                                      }
                                    });
                                  },
                                ),

                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 24),

                                // Dining Preferences
                                Text(
                                  'Dining Preferences',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                _buildChipGroup(
                                  allOptions: _getDiningOptions(),
                                  selectedOptions: _editedPreferences['diningPreferences']!,
                                  onSelectionChanged: (value) {
                                    setDialogState(() {
                                      if (_editedPreferences['diningPreferences']!.contains(value)) {
                                        _editedPreferences['diningPreferences']!.remove(value);
                                      } else {
                                        _editedPreferences['diningPreferences']!.add(value);
                                      }
                                    });
                                  },
                                ),

                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 24),

                                // Special Considerations
                                Text(
                                  'Special Considerations',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                _buildChipGroup(
                                  allOptions: _getConsiderationOptions(),
                                  selectedOptions: _editedPreferences['considerations']!,
                                  onSelectionChanged: (value) {
                                    setDialogState(() {
                                      if (_editedPreferences['considerations']!.contains(value)) {
                                        _editedPreferences['considerations']!.remove(value);
                                      } else {
                                        _editedPreferences['considerations']!.add(value);
                                      }
                                    });
                                  },
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed:
                                  _isProcessingPreferences
                                      ? null
                                      : () async {
                                        setDialogState(() {
                                          _isProcessingPreferences = true;
                                        });

                                        final navigator = Navigator.of(context);
                                        await _updateTripPreferences();

                                        if (!mounted) return;

                                        navigator.pop();
                                        setState(() {
                                          _isProcessingPreferences = false;
                                        });
                                      },
                              child:
                                  _isProcessingPreferences
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                        ),
                                      )
                                      : const Text('Save Changes'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }
    } catch (e) {
      setState(() {
        _isProcessingPreferences = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load preferences: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Widget to build a group of selectable chips
  Widget _buildChipGroup({
    required List<String> allOptions,
    required List<String> selectedOptions,
    required Function(String) onSelectionChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          allOptions.map((option) {
            final bool isSelected = selectedOptions.contains(option);
            return GestureDetector(
              onTap: () => onSelectionChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF5F0E5) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? Colors.black : Colors.transparent, width: isSelected ? 1.0 : 0),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.grey[800],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  List<String> _getTripTypeOptions() {
    return ['Leisure', 'Romantic', 'Trending', 'Adventure', 'Wellness', 'Family', 'Cultural', 'Scenic', 'Business'];
  }

  List<String> _getTravelStyleOptions() {
    return ['Fast-paced', 'Balanced', 'Slow/Relaxed', 'Guided', 'Self-Guided', 'Flexible'];
  }

  List<String> _getActivityOptions() {
    return [
      'City Sightseeing',
      'Museums & Arts',
      'Nature & Outdoors',
      'Adventure Activities',
      'Local Culture',
      'Shopping & Markets',
      'Beaches & Waterfront',
      'Nightlife & Entertainment',
      'Festivals & Events',
      'Relaxation',
      'Sports & Recreation',
      'Photography & Scenic Views',
    ];
  }

  List<String> _getDiningOptions() {
    return [
      'Local Cuisine',
      'Fine Dining',
      'Casual Eateries',
      'Street Food',
      'Unique Dining',
      'Vegetarian/Vegan',
      'Cafe & Bakeries',
      'Hidden Gems',
      'Food Tours & Classes',
    ];
  }

  List<String> _getConsiderationOptions() {
    return ['Accessibility', 'Child-Friendly', 'Dietary Restrictions', 'Mobility Limits', 'Sensory Sensitivity', 'Communication Needs'];
  }

  Future<void> _updateTripPreferences() async {
    try {
      final response = await _supabaseService.supabase.from('itineraries').select('preferences').eq('id', widget.itineraryId).single();
      final currentPreferences = response['preferences'];
      final updatedPreferences = <String, dynamic>{...currentPreferences};

      updatedPreferences['tripTypes'] = _editedPreferences['tripTypes'];
      updatedPreferences['travelStyles'] = _editedPreferences['travelStyles'];
      updatedPreferences['activities'] = _editedPreferences['activities'];
      updatedPreferences['diningPreferences'] = _editedPreferences['diningPreferences'];
      updatedPreferences['considerations'] = _editedPreferences['considerations'];

      // Update itinerary in Supabase
      await _supabaseService.supabase.from('itineraries').update({'preferences': updatedPreferences}).eq('id', widget.itineraryId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip parameters updated successfully!', style: TextStyle(color: Colors.black)),
            backgroundColor: Color(0xFFE6D5C7),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update trip parameters: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}
