import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  // Factory constructor to return the same instance every time
  factory SupabaseService() {
    return _instance;
  }

  // Private constructor for singleton
  SupabaseService._internal();

  // Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();

  SupabaseClient? _client;

  // Initialize Supabase
  Future<void> initialize() async {
    final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Supabase URL or Anonymous Key not found in .env file');
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey, debug: false);

    _client = Supabase.instance.client;
  }

  // Get the Supabase client
  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase client not initialized. Call initialize() first.');
    }
    return _client!;
  }

  // Check if user is authenticated
  bool get isAuthenticated => client.auth.currentUser != null;

  // Get current user
  User? get currentUser => client.auth.currentUser;

  // Sign up with email and password
  Future<AuthResponse> signUp({required String email, required String password, String? name}) async {
    final AuthResponse response = await client.auth.signUp(email: email, password: password, data: name != null ? {'name': name} : null);

    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({required String email, required String password}) async {
    final AuthResponse response = await client.auth.signInWithPassword(email: email, password: password);

    return response;
  }

  // Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Update user profile
  Future<void> updateProfile({required String userId, String? name, String? avatarUrl}) async {
    final Map<String, dynamic> data = {};

    if (name != null) data['name'] = name;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    if (data.isNotEmpty) {
      await client.from('profiles').upsert({'id': userId, ...data});
    }
  }
}
