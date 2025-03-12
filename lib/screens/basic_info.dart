import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../services/api_services.dart';

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
    const OptionData(name: 'Family', description: 'Fun activities for adults and children.', icon: Icons.family_restroom),
    const OptionData(name: 'Cultural', description: 'Local traditions and historical sites.', icon: Icons.museum),
    const OptionData(name: 'Wellness', description: 'Mindfulness, relaxation and spa treatments.', icon: Icons.self_improvement),
    const OptionData(name: 'Scenic', description: 'Beautiful landscapes and photo spots.', icon: Icons.landscape),
    const OptionData(name: 'Business', description: 'Professional meetings and networking.', icon: Icons.business_center),
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

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  // STEP 1: Where, When, Who
  Widget _buildFirstStep() {
    return SingleChildScrollView(
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
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip Type Section
          Text('Trip Type', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
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
                            isSelected
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
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
                            isSelected
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
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
      // TODO: return _buildThirdStep();
      case 3:
      // Step 4: Special accommodations, requests
      // TODO: return _buildFourthStep();
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
                              });
                            } else {
                              // TODO: Submit the data or navigate away.
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
