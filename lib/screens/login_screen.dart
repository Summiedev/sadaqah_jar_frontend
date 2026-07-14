import 'package:flutter/material.dart';

import '../services/backend_api.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;
  final VoidCallback onBack;
  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
    required this.onForgotPassword,
    required this.onBack,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await BackendApi.instance.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await BackendApi.instance.getAccountSnapshot();
      if (!mounted) return;
      widget.onLogin();
    } catch (error) {
      if (!mounted) return;
      String errorMsg = error.toString();
      if (errorMsg.contains('TimeoutException') || errorMsg.contains('timed out')) {
        errorMsg = 'Connection timed out. The server may be waking up. Please try again.';
      } else {
        errorMsg = errorMsg.replaceFirst('BackendApiException(', '').replaceFirst(')', '');
      }
      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  InputDecoration _fieldDecoration(BuildContext context, {required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F4EB),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF93816F), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: const Color(0xFFE0D0B8).withValues(alpha: 0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF9A734F), width: 1.4),
      ),
      suffixIcon: suffixIcon,
    );
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
              colors: [Color(0xFFF8F2E7), Color(0xFFE8DDC8), Color(0xFFD8C7B1)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -44,
                right: -28,
                child: _LoginGlow(size: 180, color: const Color(0xFFC78F54).withValues(alpha: 0.26)),
              ),
              Positioned(
                bottom: 96,
                left: -48,
                child: _LoginGlow(size: 140, color: const Color(0xFF7C8A59).withValues(alpha: 0.20)),
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
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF362C26),
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Sign in to continue your streaks, jars, and charitable acts.',
                        style: TextStyle(
                          fontSize: 15.5,
                          color: Color(0xFF6B5A4A),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F2E8).withValues(alpha: 0.88),
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
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E261F),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.lock_outline, color: Color(0xFFF0D9B4)),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Your account keeps your progress in sync across devices.',
                                      style: TextStyle(
                                        color: Color(0xFFF4E8D2),
                                        fontSize: 13.5,
                                        height: 1.35,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Email address',
                              style: TextStyle(
                                color: Color(0xFF8A673F),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: _fieldDecoration(context, hint: 'email@example.com'),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Password',
                              style: TextStyle(
                                color: Color(0xFF8A673F),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _loading ? null : _submit(),
                              decoration: _fieldDecoration(
                                context,
                                hint: 'Enter your password',
                                suffixIcon: const Icon(Icons.visibility_off_outlined, color: Color(0xFFAA987F), size: 20),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: widget.onForgotPassword,
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: Color(0xFF5F7C43),
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0EE),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFF0BCB5)),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9B734F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                elevation: 0,
                              ),
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      'Sign in',
                                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
                                    ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'New here? ',
                                  style: TextStyle(color: Color(0xFF3A312A), fontSize: 14.5),
                                ),
                                GestureDetector(
                                  onTap: widget.onRegister,
                                  child: const Text(
                                    'Create an account',
                                    style: TextStyle(
                                      color: Color(0xFF1E726D),
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF1E726D),
                                    ),
                                  ),
                                ),
                              ],
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

class _LoginGlow extends StatelessWidget {
  const _LoginGlow({required this.size, required this.color});

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
        boxShadow: [BoxShadow(color: color, blurRadius: size * 0.42, spreadRadius: size * 0.04)],
      ),
    );
  }
}

