import 'package:supabase_flutter/supabase_flutter.dart';
import 'gemini_service.dart';

class SupabaseService {
  // Factory constructor to return the same instance every time
  factory SupabaseService() => _instance;
  SupabaseService._internal();
  static final SupabaseService _instance = SupabaseService._internal();

  // Supabase client shortcut
  SupabaseClient get supabase => Supabase.instance.client;

  /// Are we signed in?
  bool get isAuthenticated => supabase.auth.currentUser != null;

  /// The signed‑in user, if any
  User? get currentUser => supabase.auth.currentUser;

  // ────────────────────────────────────────────────────────────────────────────
  // Auth methods
  Future<AuthResponse> signUp({required String email, required String password, String? name}) {
    return supabase.auth.signUp(email: email, password: password, data: name != null ? {'name': name} : null);
  }

  Future<AuthResponse> signIn({required String email, required String password}) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => supabase.auth.signOut();

  Future<void> resetPassword(String email) => supabase.auth.resetPasswordForEmail(email);

  Future<void> updateProfile({required String userId, String? name, String? avatarUrl}) {
    final data = <String, dynamic>{};
    if (name != null) data['full_name'] = name;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (data.isEmpty) return Future.value();

    return supabase.from('profiles').upsert({'id': userId, ...data});
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Itinerary methods:

  /// Create a new itinerary with only the preferences filled in.
  /// Returns the new row’s `id`.
  Future<String> createItinerary({required TripPreferences preferences, required String title}) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response =
        await supabase
            .from('itineraries')
            .insert({
              'user_id': user.id,
              'title': title,
              'destination': preferences.destination,
              'start_date': preferences.startDate?.toIso8601String(),
              'end_date': preferences.endDate?.toIso8601String(),
              'preferences': preferences.toJson(),
            })
            .select('id')
            .single();

    return response['id'] as String;
  }

  /// Update the selected attractions & restaurants for an existing itinerary.
  Future<void> updateItinerarySelections({
    required String itineraryId,
    required List<Map<String, dynamic>> selectedAttractions,
    required List<Map<String, dynamic>> selectedRestaurants,
  }) async {
    await supabase
        .from('itineraries')
        .update({'selected_attractions': selectedAttractions, 'selected_restaurants': selectedRestaurants})
        .eq('id', itineraryId);
  }

  /// Save the fully finalized itinerary JSON once it’s generated.
  Future<void> finalizeItinerary({required String itineraryId, required Map<String, dynamic> finalizedItinerary}) async {
    await supabase.from('itineraries').update({'finalized_itinerary': finalizedItinerary}).eq('id', itineraryId);
  }
}
