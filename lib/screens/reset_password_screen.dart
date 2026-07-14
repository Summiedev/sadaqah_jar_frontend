import 'package:flutter/material.dart';

import '../services/backend_api.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.onBack,
    required this.onSuccess,
    this.initialToken,
  });

  final VoidCallback onBack;
  final VoidCallback onSuccess;
  final String? initialToken;

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
  void initState() {
    super.initState();
    if (widget.initialToken != null && widget.initialToken!.isNotEmpty) {
      _tokenController.text = widget.initialToken!;
    }
  }

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
      setState(() {
        _errorMessage = 'Password must be at least 8 characters and include a letter and a number.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await BackendApi.instance.resetPassword(token: token, newPassword: password);
      if (!mounted) return;
      widget.onSuccess();
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
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8F2E9), Color(0xFFE7DBC5), Color(0xFFD9C8AE)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -44,
                right: -28,
                child: _ResetGlow(size: 170, color: const Color(0xFF9A734F).withValues(alpha: 0.24)),
              ),
              Positioned(
                bottom: 80,
                left: -44,
                child: _ResetGlow(size: 150, color: const Color(0xFF6A7F4B).withValues(alpha: 0.16)),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(22, 12, 22, 24 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2A231D)),
                            onPressed: widget.onBack,
                          ),
                          const Spacer(),
                          Text(
                            'Mizan',
                            style: TextStyle(
                              color: const Color(0xFF6E5336).withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Reset password',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF362C26),
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Paste your reset token and choose a stronger password for your account.',
                        style: TextStyle(fontSize: 15.5, color: Color(0xFF6B5A4A), height: 1.45),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F2E8).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFE6D7C0).withValues(alpha: 0.9)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x22000000), blurRadius: 28, offset: Offset(0, 14)),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(Icons.lock_reset_outlined, size: 44, color: Color(0xFF8B6842)),
                            const SizedBox(height: 14),
                            const Text(
                              'Choose a new password',
                              style: TextStyle(
                                color: Color(0xFF3F352E),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _tokenController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Reset token',
                                filled: true,
                                fillColor: const Color(0xFFF7F1E7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: const Color(0xFFE0D0B8).withValues(alpha: 0.7)),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(18)),
                                  borderSide: BorderSide(color: Color(0xFF9A734F), width: 1.4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'New password',
                                filled: true,
                                fillColor: const Color(0xFFF7F1E7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: const Color(0xFFE0D0B8).withValues(alpha: 0.7)),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(18)),
                                  borderSide: BorderSide(color: Color(0xFF9A734F), width: 1.4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _confirmController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _loading ? null : _submit(),
                              decoration: InputDecoration(
                                labelText: 'Confirm password',
                                filled: true,
                                fillColor: const Color(0xFFF7F1E7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: const Color(0xFFE0D0B8).withValues(alpha: 0.7)),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(18)),
                                  borderSide: BorderSide(color: Color(0xFF9A734F), width: 1.4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Use at least 8 characters with one letter and one number.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF8A6A44)),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0EE),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFF0BCB5)),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B6842),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Reset password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Privacy Policy and Terms of Service',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: const Color(0xFF7E6B58).withValues(alpha: 0.88), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetGlow extends StatelessWidget {
  const _ResetGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: size * 0.38, spreadRadius: size * 0.04)],
      ),
    );
  }
}

