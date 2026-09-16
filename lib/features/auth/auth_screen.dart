import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/session_controller.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/animations.dart';
import '../../services/backend_api.dart';
import 'verification_screen.dart';

String _authErrorMessage(Object error, {required bool signingIn}) {
  if (error is BackendApiException) {
    if (error.statusCode == 401) {
      return signingIn
          ? 'Your email or password is incorrect. Check both and try again.'
          : 'We could not create your account with those details.';
    }
    if (error.statusCode == 409) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (error.statusCode >= 500) {
      return 'Mizan is having trouble right now. Please try again in a moment.';
    }
    if (error.statusCode == 429) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (error.message.isNotEmpty) return error.message;
  }
  return 'Something went wrong. Please check your connection and try again.';
}

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
    final colors = Theme.of(context).colorScheme;
    final tokens = context.colors;
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
                    onPressed: () {
                      // [M9] Do not blindly pop when there may be no route
                      // below (e.g. cold-start deep link into auth). Fall back
                      // to onboarding/welcome when the stack cannot pop.
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/onboarding');
                      }
                    },
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.zero,
                      foregroundColor: tokens.textSecondary,
                    ),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),
              Text(
                _register ? 'Create your first gateway' : 'Welcome back',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _register
                    ? 'A private place for your worship, reflection, and good deeds.'
                    : 'Continue your quiet rhythm, one good step at a time.',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: colors.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.scrim.withValues(
                        alpha:
                            Theme.of(context).brightness == Brightness.dark
                                ? 0.18
                                : 0.05,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
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
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: MizanMotion.normal,
                      switchInCurve: MizanMotion.gentle,
                      switchOutCurve: MizanMotion.gentle,
                      child:
                          _register
                              ? _RegisterForm(onDone: _onAuthSuccess)
                              : _SigninForm(onSuccess: _onAuthSuccess),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: colors.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.5,
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: colors.outlineVariant)),
                ],
              ),
              const SizedBox(height: 14),
              if (_googleError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: tokens.error.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    _googleError!,
                    style: TextStyle(color: tokens.error, fontSize: 13),
                  ),
                ),
              _GoogleButton(onTap: _continueWithGoogle, isLoading: _loading),
              const SizedBox(height: 10),
              Text(
                'Your account keeps your progress available across your devices.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: tokens.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAuthSuccess() async {
    // [H5] Authentication success and role resolution are SEPARATE concerns.
    // The user is logged in the moment markAuthenticated() runs. A role
    // lookup that fails (offline, 5xx, timeout) must NOT turn a successful
    // login into a fake login failure, nor block navigation to the standard
    // home experience.
    ref.read(sessionProvider).markAuthenticated();

    // Default unknown role to a standard user. Never default unknown -> admin.
    var isAdmin = false;
    try {
      isAdmin = await BackendApi.instance.isCurrentUserAdmin();
    } catch (_) {
      // Role resolution failed (offline/server issue). Safely fall back to a
      // normal user experience. Admin navigation only happens after positive
      // verification of the admin role.
      isAdmin = false;
    }
    if (!mounted) return;
    context.go(isAdmin ? '/admin' : '/home');
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _loading = true;
      _googleError = null;
    });
    try {
      final serverClientId = const String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
        defaultValue: '',
      );
      final googleSignIn = GoogleSignIn(
        serverClientId: serverClientId.isEmpty ? null : serverClientId,
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
      setState(() => _googleError = _authErrorMessage(e, signingIn: true));
    } catch (e) {
      if (!mounted) return;
      setState(
        () =>
            _googleError =
                'Google sign-in could not be completed. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: selected ? colors.surface : Colors.transparent,
          foregroundColor: colors.onSurface,
          minimumSize: const Size.fromHeight(36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
        familyCode: invitationCode,
      );

      final profile = await BackendApi.instance.getUserProfile();
      if (!mounted) return;

      if (profile.emailVerified) {
        widget.onDone();
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (_) => VerificationScreen(
                  onContinue: widget.onDone,
                  onLogin: () {},
                ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _authErrorMessage(error, signingIn: false);
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
    final colors = context.colors;
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
          onToggleVisibility:
              () => setState(() => _passwordVisible = !_passwordVisible),
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
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.error.withValues(alpha: 0.45)),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: colors.error, fontSize: 13),
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
            child:
                _loading
                    ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    )
                    : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Create account',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
        _errorMessage = _authErrorMessage(error, signingIn: true);
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
    final colors = context.colors;
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
          onToggleVisibility:
              () => setState(() => _passwordVisible = !_passwordVisible),
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
              foregroundColor: colors.textSecondary,
            ),
            child: const Text(
              'Forgot password?',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
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
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.error.withValues(alpha: 0.45)),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: colors.error, fontSize: 13),
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
            child:
                _loading
                    ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    )
                    : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
    final colors = Theme.of(context).colorScheme;
    final showToggle = onToggleVisibility != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            filled: true,
            fillColor: colors.surfaceContainerHighest,
            contentPadding: EdgeInsets.symmetric(
              horizontal: showToggle ? 14 : 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
            suffixIcon:
                showToggle
                    ? IconButton(
                      onPressed: onToggleVisibility,
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: colors.primary,
                      ),
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
    final colors = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: isLoading ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.onSurface,
        side: BorderSide(color: colors.outlineVariant),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colors.surface,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _GoogleFavicon(),
          const SizedBox(width: 10),
          isLoading
              ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              )
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
      errorBuilder:
          (_, __, ___) =>
              Icon(Icons.g_mobiledata, size: 20, color: context.colors.primary),
    );
  }
}
