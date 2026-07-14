import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _register = true;
  bool _biometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F4ED),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton.icon(
                onPressed: () => context.pop(),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.zero,
                  foregroundColor: const Color(0xFF6D5B4D),
                ),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              const Text(
                'ACCOUNT CREATION',
                style: TextStyle(fontSize: 10, letterSpacing: 2.8, color: Color(0xFFB38964), fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create your quiet gateway',
                style: TextStyle(fontSize: 30, height: 1.05, fontWeight: FontWeight.w700, color: Color(0xFF2F241E)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Minimal details only. Nothing unnecessary. Keep your privacy intact while you set up your companion.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF6D5B4D)),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1E7DB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE3D3C3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SegmentButton(
                        selected: _register,
                        label: 'Create account',
                        onTap: () => setState(() => _register = true),
                      ),
                    ),
                    Expanded(
                      child: _SegmentButton(
                        selected: !_register,
                        label: 'Sign in',
                        onTap: () => setState(() => _register = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _register
                    ? _RegisterForm(
                        biometricEnabled: _biometricEnabled,
                        onToggleBiometric: () => setState(() => _biometricEnabled = !_biometricEnabled),
                      )
                    : const _SigninForm(),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFFE2D0BE))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(fontSize: 9, letterSpacing: 2.5, color: Color(0xFFB8A28E), fontWeight: FontWeight.w700)),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE2D0BE))),
                ],
              ),
              const SizedBox(height: 12),
              _GoogleButton(onTap: () => context.go('/home')),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6D5B4D),
                  side: const BorderSide(color: Color(0xFFE2D0BE)),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                child: const Text('Skip for now'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Data is stored locally and privately on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Color(0xFFB8A28E)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.selected, required this.label, required this.onTap});

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: selected ? Colors.white : Colors.transparent,
          foregroundColor: const Color(0xFF2F241E),
          minimumSize: const Size.fromHeight(36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({required this.biometricEnabled, required this.onToggleBiometric});

  final bool biometricEnabled;
  final VoidCallback onToggleBiometric;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Field(label: 'Name', hint: 'Your display name'),
        SizedBox(height: 12),
        const _Field(label: 'Email', hint: 'name@domain.com', keyboardType: TextInputType.emailAddress),
        SizedBox(height: 12),
        const _Field(label: 'Password', hint: '••••••••', obscureText: true),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E9DE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2D0BE)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: const Color(0xFFF9F4ED), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2D0BE))),
                child: const Icon(Icons.fingerprint, size: 18, color: Color(0xFF8B6842)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Biometric setup', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2F241E))),
                    SizedBox(height: 3),
                    Text('Enable Face ID or Touch ID unlock', style: TextStyle(fontSize: 9, color: Color(0xFF6D5B4D))),
                  ],
                ),
              ),
              Switch.adaptive(value: biometricEnabled, onChanged: (_) => onToggleBiometric(), activeThumbColor: const Color(0xFF8B6842)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _Field(label: 'Family invitation', hint: 'Optional household code'),
      ],
    );
  }
}

class _SigninForm extends StatelessWidget {
  const _SigninForm();

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: ValueKey('signin'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(label: 'Email', hint: 'name@domain.com', keyboardType: TextInputType.emailAddress),
        SizedBox(height: 12),
        _Field(label: 'Password', hint: '••••••••', obscureText: true),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.hint, this.keyboardType, this.obscureText = false});

  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 2, color: Color(0xFFB8A28E), fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFB8A28E)),
            filled: true,
            fillColor: const Color(0xFFF3E9DE),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2D0BE))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2D0BE))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFB38964))),
          ),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2F241E),
        side: const BorderSide(color: Color(0xFFE2D0BE)),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      child: const Text('Continue with Google'),
    );
  }
}
