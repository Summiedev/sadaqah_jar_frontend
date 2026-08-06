import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../services/backend_api.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _isStrongPassword(String value) {
    return value.length >= 8 && RegExp(r'[A-Za-z]').hasMatch(value) && RegExp(r'\d').hasMatch(value);
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final token = _tokenController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (token.isEmpty) {
      setState(() => _errorMessage = 'Enter the reset token from your email.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    if (!_isStrongPassword(password)) {
      setState(() => _errorMessage = 'Password must be at least 8 characters and include a letter and a number.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await BackendApi.instance.resetPassword(token: token, newPassword: password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset. Please sign in.')),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('BackendApiException(', '').replaceFirst(')', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: widget.onBack,
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.zero,
                      foregroundColor: kMuted,
                    ),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Reset password',
                style: TextStyle(fontSize: 28, height: 1.1, fontWeight: FontWeight.w800, color: kInk),
              ),
              const SizedBox(height: 10),
              const Text(
                'Paste your reset token and choose a stronger password for your account.',
                style: TextStyle(fontSize: 14, color: kMuted, height: 1.45),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kClayPale,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kClay),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_reset_outlined, size: 38, color: kBronze),
                    const SizedBox(height: 14),
                    const Text(
                      'Choose a new password',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      label: 'Reset token',
                      hint: 'Paste token from email',
                      controller: _tokenController,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      label: 'New password',
                      hint: 'At least 8 characters',
                      controller: _passwordController,
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      label: 'Confirm password',
                      hint: 'Re-enter password',
                      controller: _confirmController,
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use at least 8 characters with one letter and one number.',
                      style: TextStyle(fontSize: 12, color: kBronzeDark),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kDangerBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kDangerBorder),
                        ),
                        child: Text(_errorMessage!, style: const TextStyle(color: kDanger, fontSize: 13)),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _loading
                        ? SizedBox(
                            height: 48,
                            child: DecoratedBox(
                              decoration: const BoxDecoration(color: kBronze, borderRadius: BorderRadius.all(Radius.circular(16))),
                              child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Theme.of(context).colorScheme.onPrimary))),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBronze,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text('Reset password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.hint, this.controller, this.obscureText = false});

  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 2, color: kMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: kMutedLight),
            filled: true,
            fillColor: kClayPale,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kClay)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kClay)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBronzeLight)),
          ),
        ),
      ],
    );
  }
}
