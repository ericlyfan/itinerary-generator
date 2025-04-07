import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

// Create an instance of SupabaseService
final supabaseService = SupabaseService();

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _avatarUrl;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = supabaseService.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email;

        // Load name from user metadata if available
        if (user.userMetadata != null && user.userMetadata!.containsKey('name')) {
          _nameController.text = user.userMetadata!['name'] as String;
        }

        // Load avatar if available
        if (user.userMetadata != null && user.userMetadata!.containsKey('avatar_url')) {
          _avatarUrl = user.userMetadata!['avatar_url'] as String;
        }
      });

      // Try to fetch additional profile data from profiles table
      try {
        final data = await supabaseService.client.from('profiles').select().eq('id', user.id).single();

        setState(() {
          if (data['name'] != null && _nameController.text.isEmpty) {
            _nameController.text = data['name'] as String;
          }
          if (data['avatar_url'] != null && _avatarUrl == null) {
            _avatarUrl = data['avatar_url'] as String;
          }
        });
      } catch (e) {
        // Profile might not exist yet, that's okay
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabaseService.currentUser;
      if (user != null) {
        await supabaseService.updateProfile(userId: user.id, name: _nameController.text.trim());

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );

    if (shouldSignOut != true) return;

    try {
      await supabaseService.signOut();
      if (!mounted) return;
      Navigator.pop(context); // Go back to previous screen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error signing out: ${e.toString()}')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFE6D5C7),
                backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child:
                    _avatarUrl == null
                        ? Text(
                          _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 40, color: Colors.black87),
                        )
                        : null,
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement avatar upload
                },
                child: const Text('Change Profile Picture'),
              ),
              const SizedBox(height: 16),

              // Email display (non-editable)
              if (_userEmail != null) ...[
                Text(_userEmail!, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700])),
                const SizedBox(height: 24),
              ],

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Update profile button
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
                        )
                        : const Text('Update Profile'),
              ),
              const SizedBox(height: 16),

              // Sign out button
              OutlinedButton(
                onPressed: _signOut,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
