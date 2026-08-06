import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../services/backend_api.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key, required this.onContinue, required this.onLogin, this.verificationToken});
  final VoidCallback onContinue;
  final VoidCallback onLogin;
  // Retained for old deep links; new verification always uses the OTP form.
  final String? verificationToken;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _code = TextEditingController();
  bool _submitting = false;
  String? _message;

  @override
  void dispose() { _code.dispose(); super.dispose(); }

  String _friendly(Object error) {
    final message = error.toString();
    if (message.contains('401') || message.toLowerCase().contains('token')) return 'That code is invalid or has expired. Request a new code and try again.';
    if (message.contains('429')) return 'Please wait a moment before requesting another code.';
    return 'We could not verify that code. Check it and try again.';
  }

  Future<void> _verify() async {
    final code = _code.text.replaceAll(RegExp(r'\\s'), '');
    if (code.length != 6) { setState(() => _message = 'Enter the six-digit code from your email.'); return; }
    setState(() { _submitting = true; _message = null; });
    try {
      await BackendApi.instance.verifyEmailOtp(code: code);
      if (mounted) widget.onContinue();
    } catch (error) {
      if (mounted) setState(() => _message = _friendly(error));
    } finally { if (mounted) setState(() => _submitting = false); }
  }

  Future<void> _resend() async {
    setState(() { _submitting = true; _message = null; });
    try {
      await BackendApi.instance.resendVerificationEmail();
      if (mounted) setState(() => _message = 'A fresh six-digit code has been sent. Check your inbox.');
    } catch (error) { if (mounted) setState(() => _message = _friendly(error)); }
    finally { if (mounted) setState(() => _submitting = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, size: 16), label: const Text('Back'))),
        const SizedBox(height: 20),
        Container(height: 86, decoration: BoxDecoration(color: kClayPale, borderRadius: BorderRadius.circular(24), border: Border.all(color: kClay)), child: const Icon(Icons.mark_email_read_outlined, color: kBronze, size: 46)),
        const SizedBox(height: 24),
        const Text('Check your email', textAlign: TextAlign.center, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: kInk)),
        const SizedBox(height: 10),
        const Text('We sent a six-digit verification code. Enter it below and you’ll go straight into Mizan.', textAlign: TextAlign.center, style: TextStyle(color: kMuted, height: 1.45)),
        const SizedBox(height: 28),
        TextField(controller: _code, autofocus: true, keyboardType: TextInputType.number, textAlign: TextAlign.center, maxLength: 6, onSubmitted: (_) => _verify(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 10, color: kInk), decoration: InputDecoration(counterText: '', hintText: '000000', filled: true, fillColor: kClayPale, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: kClay)))),
        if (_message != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(_message!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, height: 1.4))),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: _submitting ? null : _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: kBronze,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _submitting
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2))
              : const Text('Verify and continue'),
        ),
        TextButton(onPressed: _submitting ? null : _resend, child: const Text('Didn’t get a code? Send a new one')),
        TextButton(onPressed: widget.onLogin, child: const Text('Use a different account')),
      ]),
    )))),
  );
}
