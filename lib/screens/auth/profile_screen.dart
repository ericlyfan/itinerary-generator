import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../landing_screen.dart';

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
    if (user == null) return;

    setState(() {
      _userEmail = user.email;
    });

    String? nameFromDb;
    try {
      final data = await supabaseService.client.from('profiles').select().eq('id', user.id).single();
      nameFromDb = data['full_name'] as String?;
      if (data['avatar_url'] != null) {
        _avatarUrl = data['avatar_url'] as String;
      }
    } catch (_) {}

    final nameFromMeta = user.userMetadata?['name'] as String?;
    final avatarFromMeta = user.userMetadata?['avatar_url'] as String?;
    final displayName = nameFromDb ?? nameFromMeta;
    if (displayName != null && displayName.isNotEmpty) {
      _nameController.text = displayName;
    }
    if (_avatarUrl == null && avatarFromMeta != null) {
      _avatarUrl = avatarFromMeta;
    }

    if (mounted) setState(() {});
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.black),
                SizedBox(width: 8),
                Text('Profile updated successfully', style: TextStyle(color: Colors.black)),
              ],
            ),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text('Error updating profile: ${e.toString()}', style: const TextStyle(color: Colors.black))),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LandingScreen()), (route) => false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text('Error signing out: ${e.toString()}', style: const TextStyle(color: Colors.black))),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
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
              const SizedBox(height: 16),
              if (_userEmail != null) ...[
                Text(_userEmail!, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700])),
                const SizedBox(height: 24),
              ],
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
