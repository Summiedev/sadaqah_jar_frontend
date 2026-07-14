import 'package:flutter/material.dart';

import '../services/backend_api.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegister;
  final VoidCallback onLogin;
  final VoidCallback onBack;
  const RegisterScreen({
    super.key,
    required this.onRegister,
    required this.onLogin,
    required this.onBack,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  bool _usernameEdited = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _deriveUsername(String email) {
    final localPart = email.contains('@') ? email.split('@').first : email;
    final cleaned = localPart.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    return cleaned.isEmpty ? 'user' : cleaned;
  }

  String _suggestUsername(String username) {
    final match = RegExp(r'^(.*?)(\d+)?$').firstMatch(username);
    final root = match?.group(1)?.isNotEmpty == true ? match!.group(1)! : username;
    final suffix = int.tryParse(match?.group(2) ?? '') ?? 1;
    return '$root${suffix + 1}';
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    final email = _emailController.text.trim();
    final username = _usernameController.text.trim().isEmpty ? _deriveUsername(email) : _usernameController.text.trim();

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await BackendApi.instance.register(
        username: username,
        email: email,
        password: _passwordController.text,
      );
      await BackendApi.instance.getAccountSnapshot();
      if (!mounted) return;
      widget.onRegister();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (error is BackendApiException && error.statusCode == 409 && error.code == 'username_taken') {
          final suggestion = _suggestUsername(username);
          _usernameController.text = suggestion;
          _usernameEdited = true;
          _errorMessage = 'That username is taken. Try $suggestion or choose a different one.';
        } else {
          _errorMessage = error.toString().replaceFirst('BackendApiException(', '').replaceFirst(')', '');
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  InputDecoration _fieldDecoration({required String hint, Widget? suffixIcon}) {
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
              colors: [Color(0xFFF7F3E9), Color(0xFFE6D9C1), Color(0xFFD3C0A6)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                left: -26,
                child: _RegisterGlow(size: 170, color: const Color(0xFF9A734F).withValues(alpha: 0.24)),
              ),
              Positioned(
                bottom: 70,
                right: -56,
                child: _RegisterGlow(size: 180, color: const Color(0xFF6A7F4B).withValues(alpha: 0.18)),
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
                        'Create your account',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF362C26),
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Set up your profile, join the jar, and start turning small actions into a daily habit.',
                        style: TextStyle(
                          fontSize: 15.5,
                          color: Color(0xFF6B5A4A),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F2E8).withValues(alpha: 0.9),
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
                                color: const Color(0xFF314035),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.park_outlined, color: Color(0xFFF0D9B4)),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Choose a username that feels personal. You can update your profile later.',
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
                              'Username',
                              style: TextStyle(
                                color: Color(0xFF8A673F),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => _usernameEdited = true,
                              decoration: _fieldDecoration(hint: 'your-username'),
                            ),
                            const SizedBox(height: 18),
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
                              onChanged: (value) {
                                setState(() {
                                  if (!_usernameEdited) {
                                    _usernameController.text = _deriveUsername(value);
                                    _usernameController.selection = TextSelection.collapsed(offset: _usernameController.text.length);
                                  }
                                });
                              },
                              decoration: _fieldDecoration(hint: 'email@example.com'),
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
                              textInputAction: TextInputAction.next,
                              decoration: _fieldDecoration(
                                hint: 'Create a password',
                                suffixIcon: const Icon(Icons.visibility_off_outlined, color: Color(0xFFAA987F), size: 20),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Confirm password',
                              style: TextStyle(
                                color: Color(0xFF8A673F),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _confirmController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _loading ? null : _submit(),
                              decoration: _fieldDecoration(
                                hint: 'Re-enter your password',
                                suffixIcon: const Icon(Icons.visibility_off_outlined, color: Color(0xFFAA987F), size: 20),
                              ),
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
                                      'Create account',
                                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
                                    ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account? ',
                                  style: TextStyle(color: Color(0xFF3A312A), fontSize: 14.5),
                                ),
                                GestureDetector(
                                  onTap: widget.onLogin,
                                  child: const Text(
                                    'Login',
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

class _RegisterGlow extends StatelessWidget {
  const _RegisterGlow({required this.size, required this.color});

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

