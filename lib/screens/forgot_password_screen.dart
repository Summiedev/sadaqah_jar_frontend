import 'dart:async';

import 'package:flutter/material.dart';

import '../services/backend_api.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.onBack,
    required this.onResetPassword,
  });

  final VoidCallback onBack;
  final void Function(String? token) onResetPassword;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _message;
  String? _errorMessage;
  int _cooldownSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _emailController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Enter a valid email address.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _message = null;
    });

    try {
      await BackendApi.instance.forgotPassword(email: email);
      if (!mounted) return;
      setState(() {
        _message = 'If an account exists for that email, reset instructions have been sent.';
        _cooldownSeconds = 30;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_cooldownSeconds <= 1) {
          timer.cancel();
          setState(() => _cooldownSeconds = 0);
        } else {
          setState(() => _cooldownSeconds -= 1);
        }
      });
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
                child: _HintGlow(size: 170, color: const Color(0xFF9A734F).withValues(alpha: 0.24)),
              ),
              Positioned(
                bottom: 80,
                left: -44,
                child: _HintGlow(size: 150, color: const Color(0xFF6A7F4B).withValues(alpha: 0.16)),
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
                        'Forgot password',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF362C26),
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'We will send reset instructions if the email belongs to an account.',
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
                            const Icon(Icons.mark_email_read_outlined, size: 44, color: Color(0xFF8B6842)),
                            const SizedBox(height: 14),
                            const Text(
                              'Enter your email address',
                              style: TextStyle(
                                color: Color(0xFF3F352E),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _loading || _cooldownSeconds > 0 ? null : _submit(),
                              decoration: InputDecoration(
                                labelText: 'Email address',
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
                            if (_errorMessage != null) ...[
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
                              const SizedBox(height: 10),
                            ],
                            if (_message != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF3E0),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFC9D8B4)),
                                ),
                                child: Text(
                                  _message!,
                                  style: const TextStyle(color: Color(0xFF4F6C34)),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            ElevatedButton(
                              onPressed: _loading || _cooldownSeconds > 0 ? null : _submit,
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
                                  : Text(
                                      _cooldownSeconds > 0 ? 'Wait $_cooldownSeconds s' : 'Send reset instructions',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _cooldownSeconds > 0 ? null : () => widget.onResetPassword(null),
                              child: const Text('I already have a reset token'),
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

class _HintGlow extends StatelessWidget {
  const _HintGlow({required this.size, required this.color});

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

