import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../services/backend_api.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _currentVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _isStrongPassword(String value) {
    return value.length >= 8 && RegExp(r'[A-Za-z]').hasMatch(value) && RegExp(r'\d').hasMatch(value);
  }

  Future<void> _changePassword() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final current = _currentController.text;
    final newPassword = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty) {
      setState(() => _errorMessage = 'Please enter your current password.');
      return;
    }
    if (newPassword.isEmpty) {
      setState(() => _errorMessage = 'Please enter a new password.');
      return;
    }
    if (newPassword != confirm) {
      setState(() => _errorMessage = 'New passwords do not match.');
      return;
    }
    if (!_isStrongPassword(newPassword)) {
      setState(() => _errorMessage = 'Password must be at least 8 characters with a letter and a number.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await BackendApi.instance.changePassword(
        currentPassword: current,
        newPassword: newPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('BackendApiException(', '').replaceFirst(')', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Change password', style: TextStyle(color: kInk)),
        iconTheme: const IconThemeData(color: kInk),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kPaper,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: kLine),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: kSoftBronze,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.lock_outline, color: kBronze, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Update your password',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: kInk,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Use a strong password you haven\'t used elsewhere.',
                                style: TextStyle(fontSize: 12.5, color: kMuted, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _Field(
                      label: 'Current password',
                      controller: _currentController,
                      obscureText: !_currentVisible,
                      onToggleVisibility: () => setState(() => _currentVisible = !_currentVisible),
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      label: 'New password',
                      controller: _newController,
                      obscureText: !_newVisible,
                      onToggleVisibility: () => setState(() => _newVisible = !_newVisible),
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      label: 'Confirm new password',
                      controller: _confirmController,
                      obscureText: !_confirmVisible,
                      onToggleVisibility: () => setState(() => _confirmVisible = !_confirmVisible),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'At least 8 characters with one letter and one number.',
                      style: TextStyle(fontSize: 12, color: kBronzeDark),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kDangerBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kDangerBorder),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: kDanger, fontSize: 13),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: kBronze,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _loading ? null : _changePassword,
                        child: _loading
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                          : Text('Change password', style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700)),
                      ),
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
  const _Field({
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.onToggleVisibility,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, letterSpacing: 2, color: kMuted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(fontSize: 12, color: kMutedLight),
            filled: true,
            fillColor: kClayPale,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kClay)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kClay)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBronzeLight)),
            suffixIcon: onToggleVisibility != null
                ? IconButton(
                    onPressed: onToggleVisibility,
                    icon: Icon(obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: kBronze),
                    tooltip: obscureText ? 'Show password' : 'Hide password',
                  )
                : null,
          ),
        ),
      ],
    );
  }
}