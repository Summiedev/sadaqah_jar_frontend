import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations.dart';
import '../../services/backend_api.dart';
import 'verification_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _register = true;
  bool _loading = false;
  String? _googleError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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

              const SizedBox(height: 10),

              const Text(
                'Create your quiet gateway',
                style: TextStyle(fontSize: 28, height: 1.1, fontWeight: FontWeight.w800, color: kInk),
              ),

              const SizedBox(height: 15),
              FadeScaleTransition(
                beginScale: 0.98,
                child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: kPaper,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kLine),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: Offset(0, 2))],
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
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: MizanMotion.normal,
                switchInCurve: MizanMotion.gentle,
                switchOutCurve: MizanMotion.gentle,
                child: _register
                    ? _RegisterForm(onDone: _onAuthSuccess)
                    : _SigninForm(onSuccess: _onAuthSuccess),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: Divider(color: kClay)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(fontSize: 10, letterSpacing: 2.5, color: kBronze, fontWeight: FontWeight.w700)),
                  ),
                  Expanded(child: Divider(color: kClay)),
                ],
              ),
              const SizedBox(height: 12),
              if (_googleError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kDangerBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kDangerBorder),
                  ),
                    child: Text(
                      _googleError!,
                      style: const TextStyle(color: kDanger, fontSize: 13),
                  ),
                ),
              _GoogleButton(onTap: _continueWithGoogle, isLoading: _loading),
              const SizedBox(height: 10),
              const Text(
                'Data is stored locally and privately on this device.',
                textAlign: TextAlign.center,
                 style: TextStyle(fontSize: 11, color: kMuted, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAuthSuccess() async {
    ref.read(sessionProvider).markAuthenticated();
    final isAdmin = await BackendApi.instance.isCurrentUserAdmin();
    if (!mounted) return;
    context.go(isAdmin ? '/admin' : '/home');
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _loading = true;
      _googleError = null;
    });
    try {
      final googleSignIn = GoogleSignIn(
        clientId: const String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: ''),
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        // user cancelled
        return;
      }
      final idToken = await account.authentication.then((a) => a.idToken);
      if (idToken == null) throw Exception('Failed to obtain Google ID token');

      await BackendApi.instance.googleAuth(idToken: idToken);
      if (!mounted) return;
      await _onAuthSuccess();
    } on BackendApiException catch (e) {
      if (!mounted) return;
      setState(() => _googleError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _googleError = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
          backgroundColor: selected ? Theme.of(context).colorScheme.surface : Colors.transparent,
          foregroundColor: kInk,
          minimumSize: const Size.fromHeight(36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _invitationController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  bool _passwordVisible = false;


  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _invitationController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return EmailValidator.validate(value);
  }

  Future<void> _submit() async {
    // Guard against double-submit: a rapid second tap during the button's
    // AnimatedSwitcher swap frame must not fire a second register call.
    if (_loading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final invitationCode = _invitationController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name.');

      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await BackendApi.instance.register(
        username: name,
        email: email,
        password: password,
      );

      // If an invitation code was supplied, join that household now that the
      // account exists and the session is authenticated. A bad/expired code
      // must surface as an error rather than silently doing nothing.
      if (invitationCode.isNotEmpty) {
        await BackendApi.instance.joinFamilyJar(inviteCode: invitationCode);
      }

      final profile = await BackendApi.instance.getUserProfile();
      if (!mounted) return;


      if (profile.emailVerified) {
        widget.onDone();
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerificationScreen(
              onContinue: widget.onDone,
              onLogin: () {},
            ),
          ),
        );
      }
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
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          label: 'Name',
          hint: 'Your display name',
          controller: _nameController,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: 12),
        _Field(
          label: 'Email',
          hint: 'name@domain.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: 12),
        _Field(
          label: 'Password',
          hint: 'At least 8 characters',
          controller: _passwordController,
          obscureText: !_passwordVisible,
          onToggleVisibility: () => setState(() => _passwordVisible = !_passwordVisible),
          textInputAction: TextInputAction.next,
        ),
    

        const SizedBox(height: 12),
        _Field(
          label: 'Family invitation',
          hint: 'Optional household code',
          controller: _invitationController,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          AnimatedSwitcher(
            key: ValueKey(_errorMessage),
            duration: MizanMotion.fast,
            switchInCurve: MizanMotion.gentle,
            switchOutCurve: MizanMotion.gentle,
            child: Container(
              key: ValueKey(_errorMessage),
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
          ),
        ],
        const SizedBox(height: 16),
        AnimatedSwitcher(
          key: const ValueKey('register-button'),
          duration: MizanMotion.fast,
          switchInCurve: MizanMotion.gentle,
          switchOutCurve: MizanMotion.gentle,
          child: SizedBox(
            key: ValueKey(_loading),
            width: double.infinity,
            height: 52,
            child: _loading
                ? DecoratedBox(
                    decoration: const BoxDecoration(color: kBronze, borderRadius: BorderRadius.all(Radius.circular(16))),
                    child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Theme.of(context).colorScheme.onPrimary))),
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
                    child: const Text('Create account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
          ),
        ),
      ],
    );
  }
}

class _SigninForm extends StatefulWidget {
  const _SigninForm({required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  State<_SigninForm> createState() => _SigninFormState();
}

class _SigninFormState extends State<_SigninForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return EmailValidator.validate(value);
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await BackendApi.instance.login(email: email, password: password);
      await BackendApi.instance.getAccountSnapshot();
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
    return Column(
      key: const ValueKey('signin'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          label: 'Email',
          hint: 'name@domain.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: 12),
        _Field(
          label: 'Password',
          hint: '••••••••',
          controller: _passwordController,
          obscureText: !_passwordVisible,
          onToggleVisibility: () => setState(() => _passwordVisible = !_passwordVisible),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              context.push('/forgot-password');
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              foregroundColor: kMuted,
            ),
            child: const Text('Forgot password?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          AnimatedSwitcher(
            key: ValueKey(_errorMessage),
            duration: MizanMotion.fast,
            switchInCurve: MizanMotion.gentle,
            switchOutCurve: MizanMotion.gentle,
            child: Container(
              key: ValueKey(_errorMessage),
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
          ),
        ],
        const SizedBox(height: 14),
        AnimatedSwitcher(
          key: const ValueKey('signin-button'),
          duration: MizanMotion.fast,
          switchInCurve: MizanMotion.gentle,
          switchOutCurve: MizanMotion.gentle,
          child: SizedBox(
            key: ValueKey(_loading),
            width: double.infinity,
            height: 48,
            child: _loading
                ? DecoratedBox(
                    decoration: const BoxDecoration(color: kBronze, borderRadius: BorderRadius.all(Radius.circular(16))),
                    child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Theme.of(context).colorScheme.onPrimary))),
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
                    child: const Text('Sign in', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.onToggleVisibility,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final VoidCallback? onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    final showToggle = onToggleVisibility != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 2, color: kMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: kClay),
            filled: true,
            fillColor: kClayPale,
            contentPadding: EdgeInsets.symmetric(horizontal: showToggle ? 14 : 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kClay)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kClay)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBronzeLight)),
            suffixIcon: showToggle
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

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap, this.isLoading = false});

  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: kInk,
        side: const BorderSide(color: kLine),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: kPaper,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _GoogleFavicon(),
          const SizedBox(width: 10),
          isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kBronze))
              : const Text('Continue with Google'),
        ],
      ),
    );
  }
}

class _GoogleFavicon extends StatelessWidget {
  const _GoogleFavicon();

  @override
  Widget build(BuildContext context) {
    return Image.network(
      'https://www.google.com/favicon.ico',
      width: 20,
      height: 20,
      cacheWidth: 40,
      cacheHeight: 40,
      errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 20, color: kBronze),
    );
  }
}
