import 'dart:io' show Platform;

import 'package:beerpongapp/util/localization_extensions.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const bool _kAppleSignInEnabled = true;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignIn = true;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final up = Provider.of<UserProvider>(context, listen: false);
      if (_isSignIn) {
        await up.signInWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
      } else {
        await up.registerWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          _usernameCtrl.text.trim(),
        );
      }
      // Router redirect handles navigation automatically.
    } on auth.FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _friendlyError(e.code));
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = context.loc.loginErrorGeneric);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await Provider.of<UserProvider>(context, listen: false).signIn();
    } on auth.FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _friendlyError(e.code));
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = context.loc.loginErrorGoogle);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _appleSignIn() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await Provider.of<UserProvider>(context, listen: false).signInWithApple();
    } on auth.FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _friendlyError(e.code));
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = context.loc.loginErrorApple);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = context.loc.loginErrorEmailFirst);
      return;
    }
    try {
      await Provider.of<UserProvider>(context, listen: false)
          .resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.loginResetEmailSent)),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = context.loc.loginErrorResetFailed);
      }
    }
  }

  String _friendlyError(String code) => switch (code) {
        'user-not-found' => context.loc.loginErrUserNotFound,
        'wrong-password' ||
        'invalid-credential' =>
          context.loc.loginErrWrongPassword,
        'email-already-in-use' => context.loc.loginErrEmailInUse,
        'weak-password' => context.loc.loginErrWeakPassword,
        'invalid-email' => context.loc.loginErrInvalidEmail,
        'too-many-requests' => context.loc.loginErrTooManyRequests,
        _ => context.loc.loginErrAuthFailed,
      };

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while the initial session is being restored.
    final userProvider = context.watch<UserProvider>();
    if (userProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0F11),
        body: Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0F11),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildFormCard(),
              const SizedBox(height: 28),
              _buildDivider(),
              const SizedBox(height: 24),
              _buildSocialButtons(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFF0AE1D), Colors.amber],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.sports_bar, size: 40, color: Colors.black),
        ),
        const SizedBox(height: 20),
        const Text(
          'BEERPONG',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 3,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Colors.amber, Color(0xFFF0AE1D)]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.loc.loginTagline,
          style: const TextStyle(
            color: Color(0xFFBDBDBD),
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildToggle(),
            const SizedBox(height: 24),
            // Username field — only shown in Register mode.
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: !_isSignIn
                  ? Column(
                      children: [
                        _buildField(
                          controller: _usernameCtrl,
                          label: context.loc.loginFieldUsername,
                          icon: Icons.person_outline,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? context.loc.loginValidateUsername
                              : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            _buildField(
              controller: _emailCtrl,
              label: context.loc.loginFieldEmail,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@'))
                  ? context.loc.loginValidateEmail
                  : null,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _passwordCtrl,
              label: context.loc.loginFieldPassword,
              icon: Icons.lock_outline,
              obscure: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) => (v == null || v.length < 6)
                  ? context.loc.loginValidatePassword
                  : null,
            ),
            if (_isSignIn) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : _forgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.amber,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text(context.loc.loginForgotPassword,
                      style: const TextStyle(fontSize: 13)),
                ),
              ),
            ] else
              const SizedBox(height: 20),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor:
                      Colors.amber.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        _isSignIn ? context.loc.loginBtnSignIn : context.loc.loginBtnCreateAccount,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F36),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _toggleOption(context.loc.loginToggleSignIn, _isSignIn,
              () => setState(() {
                    _isSignIn = true;
                    _errorMessage = null;
                  })),
          _toggleOption(context.loc.loginToggleRegister, !_isSignIn,
              () => setState(() {
                    _isSignIn = false;
                    _errorMessage = null;
                  })),
        ],
      ),
    );
  }

  Widget _toggleOption(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? Colors.amber : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.grey,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF2C2F36),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.amber, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle:
            const TextStyle(color: Colors.redAccent, fontSize: 11),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFF2C2F36), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            context.loc.loginOrContinueWith,
            style: const TextStyle(color: Color(0xFF757575), fontSize: 12),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFF2C2F36), thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    final showApple = _kAppleSignInEnabled && (Platform.isIOS || Platform.isMacOS);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _socialButton(
          onTap: _loading ? null : _googleSignIn,
          backgroundColor: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                        text: 'G',
                        style: TextStyle(color: Color(0xFF4285F4))),
                    TextSpan(
                        text: 'o',
                        style: TextStyle(color: Color(0xFFEA4335))),
                    TextSpan(
                        text: 'o',
                        style: TextStyle(color: Color(0xFFFBBC05))),
                    TextSpan(
                        text: 'g',
                        style: TextStyle(color: Color(0xFF4285F4))),
                    TextSpan(
                        text: 'l',
                        style: TextStyle(color: Color(0xFF34A853))),
                    TextSpan(
                        text: 'e',
                        style: TextStyle(color: Color(0xFFEA4335))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.loc.loginContinueGoogle,
                style: const TextStyle(
                  color: Color(0xFF1F1F1F),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (showApple) ...[
          const SizedBox(height: 12),
          _socialButton(
            onTap: _loading ? null : _appleSignIn,
            backgroundColor: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.apple, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  context.loc.loginContinueApple,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _socialButton({
    required VoidCallback? onTap,
    required Color backgroundColor,
    required Widget child,
  }) {
    return SizedBox(
      height: 52,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}
