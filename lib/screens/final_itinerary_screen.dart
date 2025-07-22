import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import 'itineraries_list_screen.dart';

class FinalItineraryScreen extends StatefulWidget {
  const FinalItineraryScreen({super.key, required this.scheduledItinerary, required this.itineraryId});

  final ScheduledItinerary scheduledItinerary;
  final String itineraryId;

  @override
  State<FinalItineraryScreen> createState() => _FinalItineraryScreenState();
}

class _FinalItineraryScreenState extends State<FinalItineraryScreen> {
  int _selectedDayIndex = 0;
  bool _showFullSchedule = false;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedDayIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(child: _showFullSchedule ? _buildFullScheduleView() : _buildMainView()),
    );
  }

  Widget _buildMainView() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(child: Column(children: [_buildTripInfoCard(), _buildDayCards(), const SizedBox(height: 100)])),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 24),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ItinerariesListScreen()));
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip Info',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  widget.scheduledItinerary.destination,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: IconButton(icon: const Icon(Icons.share_rounded, size: 28), onPressed: _shareItinerary),
          ),
        ],
      ),
    );
  }

  Widget _buildTripInfoCard() {
    final startDate = widget.scheduledItinerary.startDate;
    final endDate = widget.scheduledItinerary.endDate;
    final duration = widget.scheduledItinerary.durationInDays;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.scheduledItinerary.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF6B73FF).withAlpha(25), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.calendar_today, color: Color(0xFF6B73FF), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    Text(
                      '$duration day${duration > 1 ? 's' : ''} trip',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.scheduledItinerary.overview != null) ...[
            const SizedBox(height: 20),
            Text(
              widget.scheduledItinerary.overview!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700], height: 1.5),
            ),
          ],
          if (widget.scheduledItinerary.totalEstimatedCost != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF4FC3F7).withAlpha(25), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.attach_money, color: Color(0xFF4FC3F7), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Cost',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                      Text(
                        widget.scheduledItinerary.totalEstimatedCost!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Daily Schedule',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          ...widget.scheduledItinerary.dailySchedules.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            return _buildDayCard(day, index);
          }),
        ],
      ),
    );
  }

  Widget _buildDayCard(DailySchedule day, int index) {
    final dayColors = [
      const Color(0xFF6B73FF), // Blue
      const Color(0xFF81C784), // Green
      const Color(0xFF4FC3F7), // Light Blue
      const Color(0xFFFFB74D), // Orange
      const Color(0xFFFF8A65), // Coral
      const Color(0xFFBA68C8), // Purple
      const Color(0xFF42A5F5), // Medium Blue
      const Color(0xFF66BB6A), // Light Green
      const Color(0xFF26C6DA), // Cyan
      const Color(0xFFFFA726), // Amber
      const Color(0xFFEF5350), // Red
      const Color(0xFF9575CD), // Light Purple
      const Color(0xFF5C6BC0), // Indigo
      const Color(0xFF4CAF50), // Green
      const Color(0xFF29B6F6), // Sky Blue
      const Color(0xFFFF7043), // Deep Orange
    ];
    final dayColor = dayColors[index % dayColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _selectedDayIndex = index;
              _showFullSchedule = true;
            });
            // Sync the page controller when entering full schedule view
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageController?.hasClients == true) {
                _pageController!.jumpToPage(_selectedDayIndex);
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                // Day header
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [dayColor, dayColor.withValues(alpha: 0.8)],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEE').format(day.date).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                          ),
                          Text(
                            DateFormat('MMM').format(day.date).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                          ),
                          Text(
                            '${day.date.day}',
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, height: 1.0),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Day ${day.dayNumber}',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            if (day.theme != null)
                              Text(day.theme!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                '${day.activities.length} activities planned',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children:
                        day.activities.map((activity) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _getActivityTypeColor(activity.type),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  activity.startTime,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    activity.name,
                                    style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullScheduleView() {
    final selectedDay = widget.scheduledItinerary.dailySchedules[_selectedDayIndex];

    return Column(children: [_buildScheduleHeader(selectedDay), Expanded(child: _buildSwipeableScheduleContent())]);
  }

  Widget _buildSwipeableScheduleContent() {
    _pageController ??= PageController(initialPage: _selectedDayIndex);

    return PageView.builder(
      controller: _pageController!,
      itemCount: widget.scheduledItinerary.dailySchedules.length,
      onPageChanged: (index) {
        setState(() {
          _selectedDayIndex = index;
        });
      },
      itemBuilder: (context, index) {
        final day = widget.scheduledItinerary.dailySchedules[index];
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          itemCount: day.activities.length,
          itemBuilder: (context, activityIndex) {
            final activity = day.activities[activityIndex];
            final isLast = activityIndex == day.activities.length - 1;
            return _buildActivityItem(activity, isLast);
          },
        );
      },
    );
  }

  Widget _buildScheduleHeader(DailySchedule day) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 24),
            onPressed: () {
              setState(() {
                _showFullSchedule = false;
              });
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  DateFormat('EEEE MMM d').format(day.date),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // Day navigation
          if (_selectedDayIndex > 0)
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 28),
              onPressed: () {
                setState(() {
                  _selectedDayIndex--;
                });
                _pageController?.animateToPage(_selectedDayIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              },
            ),
          if (_selectedDayIndex < widget.scheduledItinerary.dailySchedules.length - 1)
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 28),
              onPressed: () {
                setState(() {
                  _selectedDayIndex++;
                });
                _pageController?.animateToPage(_selectedDayIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ScheduledActivity activity, bool isLast) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const Padding(padding: EdgeInsets.only(top: 8.0)),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: _getActivityTypeColor(activity.type), borderRadius: BorderRadius.circular(6)),
              ),
              if (!isLast) Container(width: 2, height: 80, color: Colors.grey[300]),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: _getActivityTypeColor(activity.type), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_outlined, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(activity.startTime, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      if (activity.endTime != null) ...[
                        Text(
                          ' - ${activity.endTime}',
                          style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Activity card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getActivityTypeColor(activity.type).withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              activity.type.displayName.toUpperCase(),
                              style: TextStyle(
                                color: _getActivityTypeColor(activity.type),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (activity.estimatedCost != null)
                            Expanded(
                              child: Text(
                                activity.estimatedCost!,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w600),
                                textAlign: TextAlign.right,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activity.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      if (activity.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          activity.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700], height: 1.4),
                        ),
                      ],
                      if (activity.location != null || activity.duration != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (activity.location != null) ...[
                              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  activity.location!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                ),
                              ),
                            ],
                            if (activity.duration != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.schedule_outlined, size: 14, color: Colors.grey[500]),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _getDisplayDuration(activity.duration!),
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Duration notes directly below the duration
                                    if (_getDurationNotes(activity.duration!) != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _getDurationNotes(activity.duration!)!,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (activity.transportationToNext != null && !isLast) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Icon(Icons.directions_outlined, size: 14, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  activity.transportationToNext!,
                                  style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Color _getActivityTypeColor(ActivityType type) {
    switch (type) {
      case ActivityType.attraction:
        return const Color(0xFF6B73FF);
      case ActivityType.restaurant:
        return const Color(0xFFFF8A65);
      case ActivityType.transportation:
        return const Color(0xFFBA68C8);
      case ActivityType.accommodation:
        return const Color(0xFF81C784);
      case ActivityType.other:
        return const Color(0xFF78909C);
    }
  }

  String _getDisplayDuration(String duration) {
    // Check if duration contains parentheses (notes)
    if (duration.contains('(') && duration.contains(')')) {
      // Extract the main duration part before the parentheses
      final mainDuration = duration.split('(')[0].trim();
      return '$mainDuration*';
    }
    return duration;
  }

  String? _getDurationNotes(String duration) {
    // Extract notes from within parentheses
    if (duration.contains('(') && duration.contains(')')) {
      final startIndex = duration.indexOf('(') + 1;
      final endIndex = duration.lastIndexOf(')');
      if (startIndex < endIndex) {
        return duration.substring(startIndex, endIndex).trim();
      }
    }
    return null;
  }

  void _shareItinerary() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sharing feature coming soon!'), backgroundColor: Color.fromARGB(255, 0, 0, 0)));
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }
}
