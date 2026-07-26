import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../services/backend_api.dart';

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

  Future<void> _resendVerification() async {
    setState(() { _state = VerificationState.pending; _message = 'Sending verification email...'; });
    try {
      await BackendApi.instance.resendVerificationEmail();
      if (!mounted) return;
      setState(() {
        _message = 'Verification email sent. Check your inbox and tap the link.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _state = VerificationState.failed;
        _message = error.toString().replaceFirst('BackendApiException(', '').replaceFirst(')', '');
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
    final isVerified = _state == VerificationState.verified;
    final isFailed = _state == VerificationState.failed;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: kPaper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => context.pop(),
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
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kClayPale,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: kClay),
                ),
                child: Icon(
                  isVerified
                      ? Icons.verified_outlined
                      : isFailed
                          ? Icons.error_outline
                          : Icons.mark_email_read_outlined,
                  size: 48,
                  color: kBronze,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                isVerified ? 'Email verified' : isFailed ? 'Verification failed' : 'Check your email',
                style: const TextStyle(fontSize: 26, height: 1.1, fontWeight: FontWeight.w800, color: kInk),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _message,
                style: const TextStyle(fontSize: 14, color: kMuted, height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              if (isVerified)
                ElevatedButton(
                  onPressed: widget.onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBronze,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                )
              else if (isFailed)
                Column(
                  children: [
                    TextButton(
                      onPressed: widget.onLogin,
                      style: TextButton.styleFrom(foregroundColor: kMuted),
                      child: const Text('Back to login', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _resendVerification,
                      style: TextButton.styleFrom(foregroundColor: kBronze),
                      child: const Text('Request a new verification email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _resendVerification,
                      style: TextButton.styleFrom(foregroundColor: kBronze),
                      child: const Text('Resend verification email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Didn\'t receive the email? Check your spam folder.',
                      style: TextStyle(color: kBronzeDark, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
