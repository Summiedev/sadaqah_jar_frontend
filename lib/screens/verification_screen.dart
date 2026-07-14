import 'dart:async';

import 'package:flutter/material.dart';

import '../services/backend_api.dart';

enum VerificationState { pending, verified, failed }

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.onContinue,
    required this.onLogin,
    this.verificationToken,
  });

  final VoidCallback onContinue;
  final VoidCallback onLogin;
  final String? verificationToken;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  VerificationState _state = VerificationState.pending;
  String _message = 'Check your inbox and tap the verification link.';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.verificationToken != null && widget.verificationToken!.isNotEmpty) {
      _verifyFromToken();
    } else {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkVerification());
    _checkVerification();
  }

  Future<void> _checkVerification() async {
    try {
      final verified = await BackendApi.instance.isEmailVerified();
      if (!mounted) return;
      if (verified) {
        _timer?.cancel();
        setState(() {
          _state = VerificationState.verified;
          _message = 'Your email is verified. You can continue.';
        });
      } else {
        setState(() {
          _state = VerificationState.pending;
          _message = 'Check your inbox and tap the verification link.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = VerificationState.pending;
        _message = 'Still waiting for verification. Try again in a moment.';
      });
    }
  }

  Future<void> _verifyFromToken() async {
    setState(() {
      _state = VerificationState.pending;
      _message = 'Verifying your email...';
    });
    try {
      await BackendApi.instance.verifyEmail(token: widget.verificationToken!);
      if (!mounted) return;
      setState(() {
        _state = VerificationState.verified;
        _message = 'Your email is verified. You can continue.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _state = VerificationState.failed;
        _message = error.toString().replaceFirst('BackendApiException(', '').replaceFirst(')', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isVerified = _state == VerificationState.verified;
    final isFailed = _state == VerificationState.failed;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F2E9),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F2E9), Color(0xFFE8DCC7), Color(0xFFD7C3A8)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -44,
              right: -28,
              child: _VerificationGlow(size: 170, color: const Color(0xFF9A734F).withValues(alpha: 0.22)),
            ),
            Positioned(
              bottom: 80,
              left: -44,
              child: _VerificationGlow(size: 150, color: const Color(0xFF6A7F4B).withValues(alpha: 0.14)),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(22, 16, 22, 24 + media.viewInsets.bottom),
                child: SizedBox(
                  height: media.size.height - media.padding.top - media.padding.bottom - 40,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F2E8).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFE6D7C0).withValues(alpha: 0.9)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x22000000), blurRadius: 28, offset: Offset(0, 14)),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E261F),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              isVerified
                                  ? Icons.verified_outlined
                                  : isFailed
                                      ? Icons.error_outline
                                      : Icons.mark_email_read_outlined,
                              size: 46,
                              color: const Color(0xFFF0D9B4),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            isVerified
                                ? 'Email verified'
                                : isFailed
                                    ? 'Verification failed'
                                    : 'Check your email',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF362C26),
                              height: 1.05,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _message,
                            style: const TextStyle(fontSize: 15.5, color: Color(0xFF6B5A4A), height: 1.45),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 22),
                          if (isVerified)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B6842),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
                                elevation: 0,
                              ),
                              onPressed: widget.onContinue,
                              child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            )
                          else if (isFailed)
                            Column(
                              children: [
                                TextButton(
                                  onPressed: widget.onLogin,
                                  child: const Text('Back to login'),
                                ),
                                const Text(
                                  'Resend verification email is not available yet.',
                                  style: TextStyle(color: Color(0xFF8A6A44), fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: null,
                                  child: const Text('Resend verification email'),
                                ),
                                const Text(
                                  'Resend verification email is not available yet.',
                                  style: TextStyle(color: Color(0xFF8A6A44), fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),
                          const Text(
                            'Privacy Policy and Terms of Service',
                            style: TextStyle(color: Color(0xFFB07B3E), fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationGlow extends StatelessWidget {
  const _VerificationGlow({required this.size, required this.color});

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

