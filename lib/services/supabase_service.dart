import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Factory constructor to return the same instance every time
  factory SupabaseService() {
    return _instance;
  }

  // Private constructor for singleton
  SupabaseService._internal();

  // Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();

  // Get the Supabase client
  SupabaseClient get client {
    return Supabase.instance.client;
  }

  // Check if user is authenticated
  bool get isAuthenticated => Supabase.instance.client.auth.currentUser != null;

  // Get current user
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  // Sign up with email and password
  Future<AuthResponse> signUp({required String email, required String password, String? name}) async {
    final AuthResponse response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'name': name} : null,
    );
    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({required String email, required String password}) async {
    final AuthResponse response = await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
    return response;
  }

  // Sign out
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(email);
  }

  // Update user profile
  Future<void> updateProfile({required String userId, String? name, String? avatarUrl}) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['full_name'] = name;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (data.isNotEmpty) {
      await Supabase.instance.client.from('profiles').upsert({'id': userId, ...data});
    }
  }
}
