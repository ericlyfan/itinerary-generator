import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class BasicInfoStepper extends StatefulWidget {
  const BasicInfoStepper({super.key});

  @override
  State<BasicInfoStepper> createState() => _BasicInfoStepperState();
}

class _BasicInfoStepperState extends State<BasicInfoStepper> {
  int _currentStep = 0;
  static const int totalSteps = 4;

  // For Step 1 (Where, When, Who)
  final TextEditingController _locationController = TextEditingController();
  bool _isLocationExpanded = true;
  bool _isDateExpanded = false;
  bool _isGuestsExpanded = false;

  DateTime? _startDate;
  DateTime? _endDate;
  int _adults = 1;
  int _children = 0;
  int _infants = 0;
  int _pets = 0;

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
                      !_isLocationExpanded
                          ? (_locationController.text.trim().isNotEmpty
                              ? Text(
                                _locationController.text.trim(),
                                style: const TextStyle(color: Colors.black),
                              )
                              : const Text(
                                'Add destination',
                                style: TextStyle(color: Colors.black),
                              ))
                          : null,
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
                        ),
                        const SizedBox(height: 10),
                        // Mock search results - would be dynamic in a real app
                        const ListTile(
                          leading: Icon(Icons.location_on),
                          title: Text('Paris, France'),
                          dense: true,
                        ),
                        const ListTile(
                          leading: Icon(Icons.location_on),
                          title: Text('Barcelona, Spain'),
                          dense: true,
                        ),
                        const ListTile(
                          leading: Icon(Icons.location_on),
                          title: Text('Tokyo, Japan'),
                          dense: true,
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
                        initialSelectedRange:
                            (_startDate != null && _endDate != null)
                                ? PickerDateRange(_startDate, _endDate)
                                : null,
                        onSelectionChanged: (args) {
                          if (args.value is PickerDateRange) {
                            final PickerDateRange range = args.value;
                            setState(() {
                              _startDate = range.startDate;
                              _endDate = range.endDate ?? range.startDate;
                            });
                          }
                        },
                        headerStyle: const DateRangePickerHeaderStyle(
                          textAlign: TextAlign.center,
                          backgroundColor: Colors.white,
                        ),
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
                        _buildGuestSelector(
                          'Adults',
                          'Ages 13+',
                          _adults,
                          (value) => setState(() => _adults = value),
                        ),
                        const Divider(),
                        _buildGuestSelector(
                          'Children',
                          'Ages 2-12',
                          _children,
                          (value) => setState(() => _children = value),
                        ),
                        const Divider(),
                        _buildGuestSelector(
                          'Infants',
                          'Under 2',
                          _infants,
                          (value) => setState(() => _infants = value),
                        ),
                        const Divider(),
                        _buildGuestSelector(
                          'Pets',
                          'Cats, dogs, etc.',
                          _pets,
                          (value) => setState(() => _pets = value),
                        ),
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
            IconButton(
              icon: const Icon(Icons.add_circle_rounded),
              iconSize: 28,
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }

  /// Content for each step
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        // Step 1: Basic Info
        return _buildFirstStep();
      case 1:
        return const Center(
          child: Text(
            'Step 2: Trip Type & Travel Style\n\n'
            'Trip Type, Travel Style, etc.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        );
      case 2:
        return const Center(
          child: Text(
            'Step 3: Activities, Dining, Budget\n\n'
            'Activities, Dining Style, Budget, etc.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        );
      case 3:
        return const Center(
          child: Text(
            'Step 4: Special Accommodations & Requests\n\n'
            'Accommodations, requests, text field, etc.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        );
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
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 3,
            color: color,
          ),
        );
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
                  onPressed: () {
                    if (!isLastStep) {
                      setState(() {
                        _currentStep++;
                      });
                    } else {
                      // TODO: Submit the data or navigate away
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
