import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../services/places_service.dart';
import '../models.dart';
import 'final_itinerary_screen.dart';
import 'auth/profile_screen.dart';
import 'basic_info.dart';

class ItinerariesListScreen extends StatefulWidget {
  const ItinerariesListScreen({super.key});

  @override
  State<ItinerariesListScreen> createState() => _ItinerariesListScreenState();
}

class _ItinerariesListScreenState extends State<ItinerariesListScreen> with TickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  final PlacesApiService _placesService = PlacesApiService();
  final List<Map<String, dynamic>> _pastTrips = [];
  final List<Map<String, dynamic>> _currentUpcomingTrips = [];
  final Map<String, String> _destinationImages = {};
  List<Map<String, dynamic>> _itineraries = [];
  bool _isLoading = true;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadItineraries();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _placesService.dispose();
    super.dispose();
  }

  Future<void> _loadItineraries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabaseService.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await _supabaseService.supabase
          .from('itineraries')
          .select('id, title, destination, start_date, end_date, finalized_itinerary, created_at')
          .eq('user_id', user.id)
          .not('finalized_itinerary', 'is', null)
          .order('start_date', ascending: false);

      setState(() {
        _itineraries = List<Map<String, dynamic>>.from(response);
        _filterTrips();
        _isLoading = false;
      });

      // Load images for destinations
      _loadDestinationImages();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load itineraries: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  void _filterTrips() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _pastTrips.clear();
    _currentUpcomingTrips.clear();

    for (final itinerary in _itineraries) {
      final endDateStr = itinerary['end_date'] as String?;
      if (endDateStr != null) {
        final endDate = DateTime.parse(endDateStr);
        final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);

        if (endDateOnly.isBefore(today)) {
          _pastTrips.add(itinerary);
        } else {
          _currentUpcomingTrips.add(itinerary);
        }
      }
    }
  }

  Future<void> _loadDestinationImages() async {
    for (final itinerary in _itineraries) {
      final destination = itinerary['destination'] as String;
      if (!_destinationImages.containsKey(destination)) {
        // try {
        //   final imageUrls = await _placesService.getPlaceImageUrls(destination, 'tourist attraction', destination);
        //   if (imageUrls.isNotEmpty && mounted) {
        //     setState(() {
        //       _destinationImages[destination] = imageUrls.first;
        //     });
        //   }
        // } catch (e) {
        //   // Silently fail image loading
        // }
      }
    }
  }

  String _getCountdown(DateTime startDate) {
    final now = DateTime.now();
    final difference = startDate.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return 'Today';
    }
  }

  @override
  Widget build(BuildContext context) {
    _tabController ??= TabController(length: 2, vsync: this);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                        controller: _tabController!,
                        children: [_buildTripsTab(_currentUpcomingTrips, 'No upcoming trips'), _buildTripsTab(_pastTrips, 'No past trips')],
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildCreateButton(),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final year = now.year;

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Trips',
                  style: Theme.of(
                    context,
                  ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 32, color: Colors.black87),
                ),
                Text(
                  '$year',
                  style: Theme.of(
                    context,
                  ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w300, fontSize: 32, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      child: TabBar(
        controller: _tabController!,
        labelColor: Colors.black87,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: const Color(0xFF6B73FF),
        indicatorWeight: 3,
        tabs: const [Tab(text: 'Current & Upcoming'), Tab(text: 'Past Trips')],
      ),
    );
  }

  Widget _buildTripsTab(List<Map<String, dynamic>> trips, String emptyMessage) {
    if (trips.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: _loadItineraries,
      child: ListView.builder(
        padding: const EdgeInsets.all(24.0),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final itinerary = trips[index];
          return _buildItineraryCard(itinerary, index);
        },
      ),
    );
  }

  Widget _buildEmptyState([String? message]) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(60)),
              child: Icon(Icons.map_outlined, size: 60, color: Colors.grey[400]),
            ),
            const SizedBox(height: 32),
            Text(
              message ?? 'No trips yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              message == 'No past trips' ? 'Your completed adventures will appear here' : 'Start planning your first adventure',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItineraryCard(Map<String, dynamic> itinerary, int index) {
    final title = itinerary['title'] as String;
    final destination = itinerary['destination'] as String;
    final startDateStr = itinerary['start_date'] as String?;
    final endDateStr = itinerary['end_date'] as String?;

    DateTime? startDate;
    DateTime? endDate;
    int? duration;

    if (startDateStr != null && endDateStr != null) {
      startDate = DateTime.parse(startDateStr);
      endDate = DateTime.parse(endDateStr);
      duration = endDate.difference(startDate).inDays + 1;
    }

    final isPastTrip = endDate != null && endDate.isBefore(DateTime.now());
    final isUpcoming = startDate != null && startDate.isAfter(DateTime.now());

    // Generate colors for cards (fallback if no image)
    final cardColors = [
      const Color(0xFF6B73FF),
      const Color(0xFF4FC3F7),
      const Color(0xFF81C784),
      const Color(0xFFFFB74D),
      const Color(0xFFFF8A65),
      const Color(0xFFBA68C8),
    ];
    final cardColor = cardColors[index % cardColors.length];

    final imageUrl = _destinationImages[destination];

    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openItinerary(itinerary),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image/gradient header
                Container(
                  height: 160,
                  decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  child: Stack(
                    children: [
                      // Background - image or gradient
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          gradient:
                              imageUrl == null
                                  ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [cardColor, cardColor.withValues(alpha: 0.8)],
                                  )
                                  : null,
                        ),
                        child:
                            imageUrl != null
                                ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 160,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [cardColor, cardColor.withValues(alpha: 0.8)],
                                          ),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                        ),
                                      );
                                    },
                                  ),
                                )
                                : null,
                      ),
                      // Dark overlay for better text readability
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withAlpha(51), Colors.black.withAlpha(102)],
                          ),
                        ),
                      ),
                      // Background pattern (only if no image)
                      if (imageUrl == null)
                        Positioned(right: -20, bottom: -20, child: Icon(Icons.landscape, size: 120, color: Colors.white.withAlpha(25))),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    destination,
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(12)),
                                  child: Text(
                                    isPastTrip
                                        ? 'Past'
                                        : isUpcoming
                                        ? 'Upcoming'
                                        : 'Current',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (startDate != null) ...[
                              if (isUpcoming) ...[
                                // Show countdown for future trips
                                Text(
                                  'STARTS IN',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(204),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  _getCountdown(startDate),
                                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.0),
                                ),
                                Text(
                                  DateFormat('MMM d').format(startDate),
                                  style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ] else ...[
                                // Show normal date for past/current trips
                                Text(
                                  DateFormat('MMM').format(startDate).toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(204),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  '${startDate.day}',
                                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, height: 1.0),
                                ),
                                if (duration != null)
                                  Text(
                                    '$duration day${duration > 1 ? 's' : ''}',
                                    style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (startDate != null && endDate != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF4FC3F7).withAlpha(76), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BasicInfoStepper())),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Future<void> _openItinerary(Map<String, dynamic> itinerary) async {
    try {
      final finalizedItineraryData = itinerary['finalized_itinerary'] as Map<String, dynamic>;
      final scheduledItinerary = ScheduledItinerary.fromJson(finalizedItineraryData);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FinalItineraryScreen(scheduledItinerary: scheduledItinerary, itineraryId: itinerary['id'] as String),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open itinerary: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }
}
