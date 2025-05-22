// ============================================================================
// TRIP PREFERENCES MODEL
// ============================================================================

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

  factory TripPreferences.fromJson(Map<String, dynamic> json) {
    return TripPreferences(
      destination: json['destination'] as String,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      adults: json['adults'] as int,
      children: json['children'] as int,
      infants: json['infants'] as int,
      pets: json['pets'] as int,
      tripTypes: List<String>.from(json['tripTypes'] ?? []),
      travelStyles: List<String>.from(json['travelStyles'] ?? []),
      activities: List<String>.from(json['activities'] ?? []),
      diningPreferences: List<String>.from(json['diningPreferences'] ?? []),
      considerations: List<String>.from(json['considerations'] ?? []),
      specialRequests: json['specialRequests'] as String,
    );
  }

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

  // Helper methods
  int? get tripDurationInDays {
    if (startDate != null && endDate != null) {
      return endDate!.difference(startDate!).inDays + 1;
    }
    return null;
  }

  int get totalTravelers => adults + children + infants;
  bool get hasFamilyMembers => children > 0 || infants > 0;
  bool get hasPets => pets > 0;
}

// ============================================================================
// RECOMMENDATION MODELS
// ============================================================================

class AttractionRecommendation {
  AttractionRecommendation({
    required this.name,
    required this.description,
    required this.timeNeeded,
    required this.category,
    required this.priceRange,
    required this.rating,
    this.imageUrls = const [],
  });

  factory AttractionRecommendation.fromJson(Map<String, dynamic> json) {
    return AttractionRecommendation(
      name: json['name'] as String,
      description: json['description'] as String,
      timeNeeded: json['timeNeeded'] as String,
      category: json['category'] as String,
      priceRange: json['priceRange'] as String,
      rating: (json['rating'] as num).toDouble(),
      imageUrls: json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : [],
    );
  }

  final String name;
  final String description;
  final String timeNeeded;
  final String category;
  final String priceRange;
  final double rating;
  List<String> imageUrls;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'timeNeeded': timeNeeded,
      'category': category,
      'priceRange': priceRange,
      'rating': rating,
      'imageUrls': imageUrls,
    };
  }

  // Helper methods
  int get priceLevelInt => priceRange.length;
  bool get isFree => priceRange.toLowerCase().contains('free') || priceRange == '\$';
  bool get isExpensive => priceRange.length >= 3;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AttractionRecommendation && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class RestaurantRecommendation {
  RestaurantRecommendation({
    required this.name,
    required this.description,
    required this.cuisine,
    required this.category,
    required this.priceRange,
    required this.rating,
    this.imageUrls = const [],
  });

  factory RestaurantRecommendation.fromJson(Map<String, dynamic> json) {
    return RestaurantRecommendation(
      name: json['name'] as String,
      description: json['description'] as String,
      cuisine: json['cuisine'] as String,
      category: json['category'] as String,
      priceRange: json['priceRange'] as String,
      rating: (json['rating'] as num).toDouble(),
      imageUrls: json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : [],
    );
  }

  final String name;
  final String description;
  final String cuisine;
  final String category;
  final String priceRange;
  final double rating;
  List<String> imageUrls;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'cuisine': cuisine,
      'category': category,
      'priceRange': priceRange,
      'rating': rating,
      'imageUrls': imageUrls,
    };
  }

  // Helper methods
  int get priceLevelInt => priceRange.length;
  bool get isBudgetFriendly => priceRange.length <= 2;
  bool get isFineDining => priceRange.length >= 3;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RestaurantRecommendation && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

// ============================================================================
// SCHEDULED ITINERARY MODELS (for generateFinalItinerary method)
// ============================================================================

class ScheduledItinerary {
  ScheduledItinerary({
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.dailySchedules,
    this.overview,
    this.tips,
    this.totalEstimatedCost,
    this.transportationNotes,
  });

  factory ScheduledItinerary.fromJson(Map<String, dynamic> json) {
    return ScheduledItinerary(
      title: json['title'] as String,
      destination: json['destination'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      dailySchedules: (json['dailySchedules'] as List).map((day) => DailySchedule.fromJson(day as Map<String, dynamic>)).toList(),
      overview: json['overview'] as String?,
      tips: json['tips'] != null ? List<String>.from(json['tips']) : null,
      totalEstimatedCost: json['totalEstimatedCost'] as String?,
      transportationNotes: json['transportationNotes'] as String?,
    );
  }

  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final List<DailySchedule> dailySchedules;
  final String? overview;
  final List<String>? tips;
  final String? totalEstimatedCost;
  final String? transportationNotes;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'dailySchedules': dailySchedules.map((day) => day.toJson()).toList(),
      'overview': overview,
      'tips': tips,
      'totalEstimatedCost': totalEstimatedCost,
      'transportationNotes': transportationNotes,
    };
  }

  // Helper methods
  int get durationInDays => endDate.difference(startDate).inDays + 1;
  bool get isMultiDay => durationInDays > 1;

  List<ScheduledActivity> get allActivities {
    return dailySchedules.expand((day) => day.activities).toList();
  }

  List<ScheduledActivity> get allRestaurants {
    return allActivities.where((activity) => activity.type == ActivityType.restaurant).toList();
  }

  List<ScheduledActivity> get allAttractions {
    return allActivities.where((activity) => activity.type == ActivityType.attraction).toList();
  }
}

class DailySchedule {
  DailySchedule({required this.date, required this.dayNumber, required this.activities, this.theme, this.notes});

  factory DailySchedule.fromJson(Map<String, dynamic> json) {
    return DailySchedule(
      date: DateTime.parse(json['date'] as String),
      dayNumber: json['dayNumber'] as int,
      activities: (json['activities'] as List).map((activity) => ScheduledActivity.fromJson(activity as Map<String, dynamic>)).toList(),
      theme: json['theme'] as String?,
      notes: json['notes'] as String?,
    );
  }

  final DateTime date;
  final int dayNumber;
  final List<ScheduledActivity> activities;
  final String? theme;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'dayNumber': dayNumber,
      'activities': activities.map((activity) => activity.toJson()).toList(),
      'theme': theme,
      'notes': notes,
    };
  }

  // Helper methods
  List<ScheduledActivity> get meals {
    return activities.where((activity) => activity.type == ActivityType.restaurant).toList();
  }

  List<ScheduledActivity> get sightseeing {
    return activities.where((activity) => activity.type == ActivityType.attraction).toList();
  }

  String get formattedDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class ScheduledActivity {
  ScheduledActivity({
    required this.name,
    required this.type,
    required this.startTime,
    this.endTime,
    this.description,
    this.location,
    this.estimatedCost,
    this.duration,
    this.notes,
    this.transportationToNext,
  });

  factory ScheduledActivity.fromJson(Map<String, dynamic> json) {
    return ScheduledActivity(
      name: json['name'] as String,
      type: ActivityType.fromString(json['type'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      estimatedCost: json['estimatedCost'] as String?,
      duration: json['duration'] as String?,
      notes: json['notes'] as String?,
      transportationToNext: json['transportationToNext'] as String?,
    );
  }

  final String name;
  final ActivityType type;
  final String startTime;
  final String? endTime;
  final String? description;
  final String? location;
  final String? estimatedCost;
  final String? duration;
  final String? notes;
  final String? transportationToNext;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.toString(),
      'startTime': startTime,
      'endTime': endTime,
      'description': description,
      'location': location,
      'estimatedCost': estimatedCost,
      'duration': duration,
      'notes': notes,
      'transportationToNext': transportationToNext,
    };
  }

  // Helper methods
  bool get hasTimeRange => endTime != null;

  String get timeDisplay {
    if (endTime != null) {
      return '$startTime - $endTime';
    }
    return startTime;
  }
}

enum ActivityType {
  attraction,
  restaurant,
  transportation,
  accommodation,
  other;

  static ActivityType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'attraction':
        return ActivityType.attraction;
      case 'restaurant':
        return ActivityType.restaurant;
      case 'transportation':
        return ActivityType.transportation;
      case 'accommodation':
        return ActivityType.accommodation;
      default:
        return ActivityType.other;
    }
  }

  @override
  String toString() {
    return name;
  }

  String get displayName {
    switch (this) {
      case ActivityType.attraction:
        return 'Attraction';
      case ActivityType.restaurant:
        return 'Restaurant';
      case ActivityType.transportation:
        return 'Transportation';
      case ActivityType.accommodation:
        return 'Accommodation';
      case ActivityType.other:
        return 'Other';
    }
  }
}
