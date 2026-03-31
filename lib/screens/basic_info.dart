import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'recommendation_screen.dart';
import '../services/places_service.dart';
import '../services/local_storage_service.dart';
import '../models.dart';

class BasicInfoStepper extends StatefulWidget {
  const BasicInfoStepper({super.key});

  @override
  State<BasicInfoStepper> createState() => _BasicInfoStepperState();
}

class OptionData {
  const OptionData({required this.name, required this.description, required this.icon});

  final String name;
  final String description;
  final IconData icon;
}

class _BasicInfoStepperState extends State<BasicInfoStepper> {
  int _currentStep = 0;
  static const int totalSteps = 4;
  final ScrollController _step1ScrollController = ScrollController();
  final ScrollController _step2ScrollController = ScrollController();
  final ScrollController _step3ScrollController = ScrollController();
  final ScrollController _step4ScrollController = ScrollController();

  // For Step 1
  bool _isLocationExpanded = true;
  bool _isDateExpanded = false;
  bool _isGuestsExpanded = false;
  List<String> _placeSuggestions = [];

  final TextEditingController _locationController = TextEditingController();
  final PlacesApiService _placesApiService = PlacesApiService();
  final List<String> popularSuggestions = [
    'Paris, France',
    'Tokyo, Japan',
    'New York, USA',
    'Seoul, South Korea',
    'Bali, Indonesia',
    'Istanbul, Turkey',
    'Barcelona, Spain',
  ];

  DateTime? _startDate;
  DateTime? _endDate;
  int _adults = 1;
  int _children = 0;
  int _infants = 0;
  int _pets = 0;

  // For Step 2
  final List<OptionData> tripTypeOptions = [
    const OptionData(name: 'Leisure', description: 'Casual sightseeing and peaceful relaxation.', icon: Icons.beach_access),
    const OptionData(name: 'Romantic', description: 'Intimate experiences and moments for couples.', icon: Icons.favorite),
    const OptionData(name: 'Trending', description: 'Popular and highly-rated destinations.', icon: Icons.local_fire_department),
    const OptionData(name: 'Adventure', description: 'Thrilling nature excursions and adventures.', icon: Icons.forest),
    const OptionData(name: 'Wellness', description: 'Mindfulness, relaxation and spa treatments.', icon: Icons.self_improvement),
    const OptionData(name: 'Family', description: 'Fun activities for adults and children.', icon: Icons.family_restroom),
    const OptionData(name: 'Cultural', description: 'Local traditions and historical sites.', icon: Icons.museum),
    const OptionData(name: 'Scenic', description: 'Beautiful landscapes and photo spots.', icon: Icons.landscape),
    const OptionData(name: 'Business', description: 'Sightseeing between meetings and networking events', icon: Icons.business_center),
  ];

  final List<OptionData> travelStyleOptions = [
    const OptionData(name: 'Fast-paced', description: 'Action-packed days with full schedules.', icon: Icons.flash_on),
    const OptionData(name: 'Balanced', description: 'Mix of activities and downtime.', icon: Icons.balance),
    const OptionData(name: 'Slow/Relaxed', description: 'Unhurried pace with plenty of free time.', icon: Icons.hourglass_empty),
    const OptionData(name: 'Guided', description: 'Expert-led tours and planned excursions.', icon: Icons.group),
    const OptionData(name: 'Self-Guided', description: 'Independent exploration on your terms.', icon: Icons.explore),
    const OptionData(name: 'Flexible', description: 'Blend of structure and spontaneity.', icon: Icons.sync),
  ];

  final List<String> selectedTripTypes = [];
  final List<String> selectedTravelStyles = [];

  void _resetScrollPosition() {
    // Schedule this for after the frame is built to ensure controllers are attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (_currentStep) {
        case 0:
          if (_step1ScrollController.hasClients) {
            _step1ScrollController.jumpTo(0);
          }
        case 1:
          if (_step2ScrollController.hasClients) {
            _step2ScrollController.jumpTo(0);
          }
        case 2:
          if (_step3ScrollController.hasClients) {
            _step3ScrollController.jumpTo(0);
          }
        case 3:
          if (_step4ScrollController.hasClients) {
            _step4ScrollController.jumpTo(0);
          }
      }
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _specialRequestsController.dispose();
    _step1ScrollController.dispose();
    _step2ScrollController.dispose();
    _step3ScrollController.dispose();
    _step4ScrollController.dispose();
    super.dispose();
  }

  // STEP 1: Where, When, Who
  Widget _buildFirstStep() {
    return SingleChildScrollView(
      controller: _step1ScrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== WHERE SECTION =====
          Card(
            elevation: 2,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: [
                const SizedBox(height: 12),
                ListTile(
                  title: Text(
                    _isLocationExpanded ? 'Where to?' : 'Where',
                    style:
                        _isLocationExpanded
                            ? Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)
                            : Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                  trailing:
                      !_isLocationExpanded && _locationController.text.trim().isNotEmpty
                          ? Text(_locationController.text.trim(), style: const TextStyle(color: Colors.black))
                          : const Text('Add destination', style: TextStyle(color: Colors.black)),
                  onTap: () {
                    setState(() {
                      _isLocationExpanded = !_isLocationExpanded;
                      if (_isLocationExpanded) {
                        _isDateExpanded = false;
                        _isGuestsExpanded = false;
                      }
                    });
                  },
                ),
                if (_isLocationExpanded)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            hintText: 'Search destinations',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (input) async {
                            if (input.isNotEmpty) {
                              try {
                                // Fetch live suggestions from your API service
                                final suggestions = await _placesApiService.fetchPlaceSuggestions(input);
                                setState(() {
                                  _placeSuggestions = suggestions;
                                });
                              } catch (e) {
                                setState(() {
                                  _placeSuggestions = [];
                                });
                              }
                            } else {
                              setState(() {
                                _placeSuggestions = [];
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        // Determine which suggestions to show:
                        Builder(
                          builder: (context) {
                            final List<String> suggestionsToShow = _placeSuggestions.isNotEmpty ? _placeSuggestions : popularSuggestions;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(0),
                              itemCount: suggestionsToShow.length,
                              itemBuilder: (context, index) {
                                final suggestion = suggestionsToShow[index];
                                return ListTile(
                                  leading: const Icon(Icons.location_on),
                                  title: Text(suggestion),
                                  dense: true,
                                  onTap: () {
                                    setState(() {
                                      _locationController.text = suggestion;
                                      _placeSuggestions = [];
                                      _isLocationExpanded = false;
                                      _isDateExpanded = true;
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          /// ===== WHEN SECTION =====
          Card(
            elevation: 2,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: [
                const SizedBox(height: 12),
                ListTile(
                  title: Text(
                    _isDateExpanded ? "When's the trip?" : 'When',
                    style:
                        _isDateExpanded
                            ? Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)
                            : Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                  trailing:
                      !_isDateExpanded
                          ? Text(
                            (_startDate != null && _endDate != null)
                                ? '${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}'
                                : 'Add dates',
                            style: const TextStyle(color: Colors.black),
                          )
                          : null,
                  onTap: () {
                    setState(() {
                      _isDateExpanded = !_isDateExpanded;
                      if (_isDateExpanded) {
                        _isLocationExpanded = false;
                        _isGuestsExpanded = false;
                      }
                    });
                  },
                ),
                if (_isDateExpanded)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 400,
                      child: SfDateRangePicker(
                        minDate: DateTime.now(),
                        maxDate: DateTime(2100),
                        navigationDirection: DateRangePickerNavigationDirection.vertical,
                        navigationMode: DateRangePickerNavigationMode.scroll,
                        selectionMode: DateRangePickerSelectionMode.range,
                        initialSelectedRange: (_startDate != null && _endDate != null) ? PickerDateRange(_startDate, _endDate) : null,
                        onSelectionChanged: (args) {
                          if (args.value is PickerDateRange) {
                            final PickerDateRange range = args.value;
                            setState(() {
                              _startDate = range.startDate;
                              _endDate = range.endDate ?? range.startDate;
                            });
                          }
                        },
                        headerStyle: const DateRangePickerHeaderStyle(textAlign: TextAlign.center, backgroundColor: Colors.white),
                        backgroundColor: Colors.white,
                        selectionColor: Colors.black,
                        startRangeSelectionColor: Colors.black87,
                        endRangeSelectionColor: Colors.black87,
                        rangeSelectionColor: Colors.grey.withValues(alpha: 0.4),
                        todayHighlightColor: Colors.transparent,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ===== WHO SECTION =====
          Card(
            elevation: 2,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 12),
                ListTile(
                  title: Text(
                    _isGuestsExpanded ? "Who's Coming?" : 'Who',
                    style:
                        _isGuestsExpanded
                            ? Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)
                            : Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                  trailing:
                      !_isGuestsExpanded
                          ? ((_adults + _children + _infants + _pets) > 0
                              ? Text(
                                '${_adults + _children} guests, $_infants infants, $_pets pets',
                                style: const TextStyle(color: Colors.black),
                              )
                              : const Text('Add guests', style: TextStyle(color: Colors.black)))
                          : null,
                  onTap: () {
                    setState(() {
                      _isGuestsExpanded = !_isGuestsExpanded;
                      if (_isGuestsExpanded) {
                        _isLocationExpanded = false;
                        _isDateExpanded = false;
                      }
                    });
                  },
                ),

                if (_isGuestsExpanded)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildGuestSelector('Adults', 'Ages 13+', _adults, (value) => setState(() => _adults = value)),
                        const Divider(),
                        _buildGuestSelector('Children', 'Ages 2-12', _children, (value) => setState(() => _children = value)),
                        const Divider(),
                        _buildGuestSelector('Infants', 'Under 2', _infants, (value) => setState(() => _infants = value)),
                        const Divider(),
                        _buildGuestSelector('Pets', 'Cats, dogs, etc.', _pets, (value) => setState(() => _pets = value)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for guest selection
  Widget _buildGuestSelector(String title, String subtitle, int value, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded),
              iconSize: 28,
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Text('$value', style: const TextStyle(fontSize: 16)),
            IconButton(icon: const Icon(Icons.add_circle_rounded), iconSize: 28, onPressed: () => onChanged(value + 1)),
          ],
        ),
      ],
    );
  }

  /// STEP 2: Trip Type & Travel Style
  Widget _buildSecondStep() {
    return SingleChildScrollView(
      controller: _step2ScrollController,
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip Type Section
          Text('Trip Type', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          Text(
            'What kind of experience are you looking for?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
          GridView.count(
            padding: const EdgeInsets.only(top: 12),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children:
                tripTypeOptions.map((option) {
                  final bool isSelected = selectedTripTypes.contains(option.name);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedTripTypes.remove(option.name);
                        } else {
                          selectedTripTypes.add(option.name);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF5F0E5) : Colors.white, // Beige background when selected
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? Colors.black : Colors.grey[400]!, width: isSelected ? 2.0 : 1.0),
                        boxShadow:
                            isSelected ? [BoxShadow(color: Colors.black.withAlpha(38), blurRadius: 4, offset: const Offset(0, 2))] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(option.icon, size: 24, color: isSelected ? Colors.black : Colors.grey[700]),
                          const SizedBox(height: 4),
                          Text(
                            option.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(
                              option.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, color: isSelected ? Colors.black87 : Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),

          // Travel Style Section
          Text('Travel Style', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          Text('How do you prefer to explore?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
          GridView.count(
            padding: const EdgeInsets.only(top: 12),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children:
                travelStyleOptions.map((option) {
                  final bool isSelected = selectedTravelStyles.contains(option.name);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedTravelStyles.remove(option.name);
                        } else {
                          selectedTravelStyles.add(option.name);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF5F0E5) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? Colors.black : Colors.grey[400]!, width: isSelected ? 2.0 : 1.0),
                        boxShadow:
                            isSelected ? [BoxShadow(color: Colors.black.withAlpha(38), blurRadius: 4, offset: const Offset(0, 2))] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(option.icon, size: 24, color: isSelected ? Colors.black : Colors.grey[700]),
                          const SizedBox(height: 4),
                          Text(
                            option.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(
                              option.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, color: isSelected ? Colors.black87 : Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // STEP 3: Activities and Dining Preferences
  final List<OptionData> activityOptions = [
    const OptionData(name: 'City Sightseeing', description: 'Historical sites, landmarks, monuments', icon: Icons.location_city),
    const OptionData(name: 'Museums & Arts', description: 'Galleries, exhibitions, theater', icon: Icons.museum),
    const OptionData(name: 'Nature & Outdoors', description: 'Parks, hiking, wildlife viewing', icon: Icons.forest),
    const OptionData(name: 'Adventure Activities', description: 'Thrilling experiences, water sports', icon: Icons.directions_bike_rounded),
    const OptionData(name: 'Local Culture', description: 'Traditional experiences, local customs', icon: Icons.public_rounded),
    const OptionData(name: 'Shopping & Markets', description: 'Boutiques, markets, souvenir hunting', icon: Icons.shopping_bag_rounded),
    const OptionData(name: 'Beaches & Waterfront', description: 'Coastal activities, seaside relaxation', icon: Icons.waves_rounded),
    const OptionData(name: 'Nightlife & Entertainment', description: 'Bars, clubs, evening activities', icon: Icons.nightlife),
    const OptionData(name: 'Festivals & Events', description: 'Local celebrations, concerts', icon: Icons.festival),
    const OptionData(name: 'Relaxation', description: 'Spas, leisurely activities', icon: Icons.spa),
    const OptionData(name: 'Sports & Recreation', description: 'Sporting events, recreational activities', icon: Icons.sports_basketball),
    const OptionData(name: 'Photography & Scenic Views', description: 'Viewpoints, photo opportunities', icon: Icons.photo_camera),
  ];

  final List<OptionData> diningOptions = [
    const OptionData(name: 'Local Cuisine', description: 'Regional specialties, authentic dishes', icon: Icons.restaurant_menu_rounded),
    const OptionData(name: 'Fine Dining', description: 'Upscale restaurants, gourmet experiences', icon: Icons.restaurant),
    const OptionData(name: 'Casual Eateries', description: 'Relaxed atmosphere, everyday dining', icon: Icons.tapas_rounded),
    const OptionData(name: 'Street Food', description: 'Food stalls, markets, quick bites', icon: Icons.takeout_dining_rounded),
    const OptionData(name: 'Unique Dining', description: 'Themed restaurants, unusual settings', icon: Icons.dinner_dining),
    const OptionData(name: 'Vegetarian/Vegan', description: 'Plant-based options and specialties', icon: Icons.emoji_nature),
    const OptionData(name: 'Cafe & Bakeries', description: 'Cozy coffee shops and artisanal bakeries', icon: Icons.local_cafe_rounded),
    const OptionData(name: 'Hidden Gems', description: 'Local favorites off the tourist path', icon: Icons.star),
    const OptionData(name: 'Food Tours & Classes', description: 'Cooking classes, guided tastings', icon: Icons.menu_book),
  ];

  final List<String> selectedActivities = [];
  final List<String> selectedDiningOptions = [];

  Widget _buildThirdStep() {
    return SingleChildScrollView(
      controller: _step3ScrollController,
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activities Section
          Text('Activities', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          Text('What activities are you interested in?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
          GridView.count(
            padding: const EdgeInsets.only(top: 12),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children:
                activityOptions.map((option) {
                  final bool isSelected = selectedActivities.contains(option.name);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedActivities.remove(option.name);
                        } else {
                          selectedActivities.add(option.name);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF5F0E5) : Colors.white, // Beige background when selected
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? Colors.black : Colors.grey[400]!, width: isSelected ? 2.0 : 1.0),
                        boxShadow:
                            isSelected ? [BoxShadow(color: Colors.black.withAlpha(38), blurRadius: 4, offset: const Offset(0, 2))] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(option.icon, size: 24, color: isSelected ? Colors.black : Colors.grey[700]),
                          const SizedBox(height: 4),
                          Text(
                            option.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(
                              option.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, color: isSelected ? Colors.black87 : Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),

          // Dining Preferences Section
          Text('Dining Preferences', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          Text('What dining options do you prefer?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
          GridView.count(
            padding: const EdgeInsets.only(top: 12),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children:
                diningOptions.map((option) {
                  final bool isSelected = selectedDiningOptions.contains(option.name);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedDiningOptions.remove(option.name);
                        } else {
                          selectedDiningOptions.add(option.name);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF5F0E5) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? Colors.black : Colors.grey[400]!, width: isSelected ? 2.0 : 1.0),
                        boxShadow:
                            isSelected ? [BoxShadow(color: Colors.black.withAlpha(38), blurRadius: 4, offset: const Offset(0, 2))] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(option.icon, size: 24, color: isSelected ? Colors.black : Colors.grey[700]),
                          const SizedBox(height: 4),
                          Text(
                            option.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(
                              option.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, color: isSelected ? Colors.black87 : Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // Step 4: Special Accommodations & Requests
  final List<OptionData> specialConsiderations = [
    const OptionData(name: 'Accessibility', description: 'Wheelchair-friendly routes and venues', icon: Icons.accessible),
    const OptionData(name: 'Child-Friendly', description: 'Activities suitable for young travelers', icon: Icons.child_care),
    const OptionData(name: 'Dietary Restrictions', description: 'Special food needs and allergies', icon: Icons.restaurant_menu),
    const OptionData(name: 'Mobility Limits', description: 'Limited walking or low-intensity activities', icon: Icons.directions_walk),
    const OptionData(name: 'Sensory Sensitivity', description: 'Quieter venues with less stimulation', icon: Icons.volume_mute),
    const OptionData(name: 'Communication Needs', description: 'Support for hearing, speech, or language differences', icon: Icons.hearing),
  ];

  final List<String> selectedAccommodations = [];
  final TextEditingController _specialRequestsController = TextEditingController();

  Widget _buildFourthStep() {
    return SingleChildScrollView(
      controller: _step4ScrollController,
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Special Accommodations Section
          Text('Special Considerations', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          Text(
            'Do you have any specific accommodation needs?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
          GridView.count(
            padding: const EdgeInsets.only(top: 12),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children:
                specialConsiderations.map((option) {
                  final bool isSelected = selectedAccommodations.contains(option.name);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedAccommodations.remove(option.name);
                        } else {
                          selectedAccommodations.add(option.name);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF5F0E5) : Colors.white, // Beige background when selected
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? Colors.black : Colors.grey[400]!, width: isSelected ? 2.0 : 1.0),
                        boxShadow:
                            isSelected ? [BoxShadow(color: Colors.black.withAlpha(38), blurRadius: 4, offset: const Offset(0, 2))] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(option.icon, size: 24, color: isSelected ? Colors.black : Colors.grey[700]),
                          const SizedBox(height: 4),
                          Text(
                            option.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(
                              option.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, color: isSelected ? Colors.black87 : Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),

          // Special Requests Section
          Text('Special Requests', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          Text(
            'Any additional information or requests you would like to share?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: TextField(
              controller: _specialRequestsController,
              maxLines: 8,
              minLines: 8,
              decoration: const InputDecoration(
                hintText: 'E.g., specific dietary needs, travel concerns, birthday celebration, anniversary trip, etc.',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Content for each step
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        // Step 1: Where, When, Who
        return _buildFirstStep();
      case 1:
        // Step 2: Trip type, travel style
        return _buildSecondStep();
      case 2:
        // Step 3: Budget, Activities, Dining
        return _buildThirdStep();
      case 3:
        // Step 4: Special accommodations, requests
        return _buildFourthStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // Minimal progress bar
  Widget _buildProgressBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final color = index <= _currentStep ? Colors.black : Colors.grey[300];
        return Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), height: 3, color: color));
      }),
    );
  }

  void _handleFinish() {
    _submitAndNavigate();
  }

  Future<void> _submitAndNavigate() async {
    final TripPreferences preferences = TripPreferences(
      destination: _locationController.text,
      startDate: _startDate,
      endDate: _endDate,
      adults: _adults,
      children: _children,
      infants: _infants,
      pets: _pets,
      tripTypes: selectedTripTypes,
      travelStyles: selectedTravelStyles,
      activities: selectedActivities,
      diningPreferences: selectedDiningOptions,
      considerations: selectedAccommodations,
      specialRequests: _specialRequestsController.text,
    );

    String itineraryId;
    try {
      itineraryId = await LocalStorageService().createItinerary(preferences: preferences, title: 'Trip to ${preferences.destination}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text('Failed to save preferences: $e', style: const TextStyle(color: Colors.black))),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RecommendationScreen(tripPreferences: preferences, itineraryId: itineraryId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastStep = _currentStep == (totalSteps - 1);
    final bool isFirstStep = _currentStep == 0;

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 80),

          // Progress bar
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildProgressBar()),
          const SizedBox(height: 16),

          // Step content
          Expanded(child: Padding(padding: const EdgeInsets.all(16.0), child: _buildStepContent())),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 42.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () {
                    if (isFirstStep) {
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        _currentStep--;
                      });
                    }
                  },
                  child: const Text('Back'),
                ),

                ElevatedButton(
                  onPressed:
                      (isFirstStep && _locationController.text.trim().isEmpty)
                          ? null
                          : () {
                            if (!isLastStep) {
                              setState(() {
                                _currentStep++;
                                _resetScrollPosition();
                              });
                            } else {
                              _handleFinish();
                            }
                          },
                  child: Text(isLastStep ? 'Finish' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
