import 'package:flutter/material.dart';

import 'package:church_app/l10n/app_localizations.dart';
import 'package:church_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await AuthService.instance.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final user = credential.user;

      if (user == null) {
        throw const AuthException(
          'Unable to log you in. Please try again.',
          code: 'login-failed',
        );
      }

      // ----------------------------------------------------------
      // CHECK EMAIL VERIFICATION
      // ----------------------------------------------------------

      final bool verified =
          await AuthService.instance.isEmailVerified();

      if (!mounted) return;

      if (!verified) {
        Navigator.pushReplacementNamed(
          context,
          '/verification',
          arguments: {
            'email': user.email ?? _emailController.text.trim(),
          },
        );

        return;
      }

      // ----------------------------------------------------------
      // LOGIN SUCCESSFUL
      // ----------------------------------------------------------

      Navigator.pushReplacementNamed(
        context,
        '/home',
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      _showError(e.message);
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Something went wrong. Please try again.',
      );
    } finally {
  if (mounted) {
    setState(() {
      _isLoading = false;
    });
  }
}
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  // ============================================================
  // PASSWORD RESET
  // ============================================================

  Future<void> _forgotPassword() async {
    final l10n = AppLocalizations.of(context)!;

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError(l10n.emailRequired);
      return;
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      _showError(l10n.invalidEmail);
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      await AuthService.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Password reset instructions have been sent to your email.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } on AuthException catch (e) {
      if (!mounted) return;

      _showError(e.message);
    } catch (_) {
      if (!mounted) return;

      _showError(
        'Unable to send password reset email. Please try again.',
      );
    }finally {
  if (mounted) {
    setState(() {
      _isLoading = false;
    });
  }
}
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 26,
          ),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const SizedBox(height: 45),

                // =================================================
                // LANGUAGE
                // =================================================

                Align(
                  alignment: Alignment.topRight,
                  child: const _LanguageSelector(),
                ),

                const SizedBox(height: 65),

                // =================================================
                // LOGO
                // =================================================

                Center(
                  child: Image.asset(
                    'assets/images/coza_logo.png',
                    width: 115,
                    height: 115,
                    fit: BoxFit.contain,

                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Container(
                        width: 115,
                        height: 115,

                        decoration:
                            const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF087F75),
                        ),

                        child: const Center(
                          child: Text(
                            'RHIC',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // =================================================
                // WELCOME
                // =================================================

                Text(
                  l10n.welcomeBack,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 30),

                // =================================================
                // EMAIL
                // =================================================

                Text(
                  l10n.email,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 9),

                TextFormField(
                  controller: _emailController,

                  keyboardType:
                      TextInputType.emailAddress,

                  textInputAction:
                      TextInputAction.next,

                  autocorrect: false,

                  decoration: _inputDecoration(
                    hint: l10n.enterEmail,
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return l10n.emailRequired;
                    }

                    final emailRegex = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    );

                    if (!emailRegex.hasMatch(
                      value.trim(),
                    )) {
                      return l10n.invalidEmail;
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 28),

                // =================================================
                // PASSWORD
                // =================================================

                Text(
                  l10n.password,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 9),

                TextFormField(
                  controller: _passwordController,

                  obscureText: _obscurePassword,

                  textInputAction:
                      TextInputAction.done,

                  autocorrect: false,

                  decoration:
                      _inputDecoration(
                    hint: l10n.enterPassword,
                  ).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },

                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,

                        color: Colors.black54,
                      ),
                    ),
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return l10n.passwordRequired;
                    }

                    if (value.length < 8) {
                      return l10n.passwordTooShort;
                    }

                    return null;
                  },

                  onFieldSubmitted: (_) {
                    if (!_isLoading) {
                      _login();
                    }
                  },
                ),

                // =================================================
                // FORGOT PASSWORD
                // =================================================

                Align(
                  alignment:
                      Alignment.centerRight,

                  child: TextButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _forgotPassword,

                    child: Text(
                      l10n.forgotPassword,

                      style: const TextStyle(
                        color: Color(0xFF6B238E),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 45),

                // =================================================
                // LOGIN BUTTON
                // =================================================

                SizedBox(
                  width: double.infinity,
                  height: 73,

                  child: ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _login,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF350044),

                      disabledBackgroundColor:
                          const Color(0xFF350044)
                              .withValues(
                        alpha: 0.6,
                      ),

                      foregroundColor:
                          Colors.white,

                      elevation: 0,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          38,
                        ),
                      ),
                    ),

                    child: _isLoading
                        ? const SizedBox(
                            width: 25,
                            height: 25,

                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.login,

                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 42),

                // =================================================
                // SIGN UP
                // =================================================

                Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),

                      children: [
                        TextSpan(
                          text:
                              '${l10n.dontHaveAccount} ',
                        ),

                        WidgetSpan(
                          child: GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () {
                                    Navigator
                                        .pushReplacementNamed(
                                      context,
                                      '/registration',
                                    );
                                  },

                            child: Text(
                              l10n.signUp,

                              style:
                                  const TextStyle(
                                color: Colors.black,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(
        color: Color(0xFF999999),
      ),

      filled: true,

      fillColor: const Color(0xFFF2F2F2),

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 21,
      ),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: Color(0xFFE3E3E3),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: Color(0xFF6B238E),
          width: 1.5,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: Colors.red,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: Colors.red,
          width: 1.2,
        ),
      ),
    );
  }
}

// ================================================================
// LANGUAGE SELECTOR
// ================================================================

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        const Text(
          '🇺🇸',
          style: TextStyle(
            fontSize: 28,
          ),
        ),

        const SizedBox(width: 8),

        const Text(
          'EN',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),

        const Icon(
          Icons.arrow_drop_down,
          size: 25,
        ),
      ],
    );
  }
}