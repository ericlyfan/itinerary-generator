import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

final supabaseService = SupabaseService();

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _requestSent = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await supabaseService.resetPassword(_emailController.text.trim());

      if (mounted) {
        setState(() {
          _requestSent = true;
          _isLoading = false;
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again later.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24.0), child: _requestSent ? _buildSuccessMessage() : _buildResetForm()),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          // Title and instructions
          Text('Reset Password', style: Theme.of(context).textTheme.displayMedium, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Text(
            'Enter your email address and we\'ll send you a link to reset your password if it exists in our system.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Error message
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(_errorMessage, style: TextStyle(color: Colors.red[800])),
            ),
          if (_errorMessage.isNotEmpty) const SizedBox(height: 16),

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'Enter your registered email',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              // Simple email validation
              if (!value.contains('@') || !value.contains('.')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Reset password button
          ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
                    )
                    : const Text('Send Reset Link'),
          ),
          const SizedBox(height: 16),

          // Back to sign in button
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Sign In')),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        const SizedBox(height: 32),

        // Success icon
        Icon(Icons.mark_email_read, size: 80, color: Theme.of(context).primaryColor),
        const SizedBox(height: 24),

        // Success message
        Text('Check Your Email', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 16),

        // Email sent to
        Text('We\'ve sent a password recovery link to:', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),

        // Display the email
        Text(
          _emailController.text.trim(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
          child: const Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please check your email and follow the instructions to reset your password.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text('If you don\'t see the email in your inbox, please check your spam folder.', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Back to sign in button
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          child: const Text('Back to Sign In'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
