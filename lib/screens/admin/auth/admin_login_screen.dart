import 'package:flutter/material.dart';

import 'package:church_app/services/auth_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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
  // ADMIN LOGIN
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
      // ----------------------------------------------------------
      // Sign in with Firebase Authentication
      // ----------------------------------------------------------

      await AuthService.instance.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // ----------------------------------------------------------
      // Check email verification
      // ----------------------------------------------------------

      final bool verified =
          await AuthService.instance.isEmailVerified();

      if (!mounted) return;

      if (!verified) {
        await AuthService.instance.logout();

        if (!mounted) return;

        _showError(
          'Please verify your email address before accessing the admin portal.',
        );

        return;
      }

      // ----------------------------------------------------------
      // Check admin role
      // ----------------------------------------------------------

      final bool admin =
          await AuthService.instance.isAdmin();

      if (!mounted) return;

      if (!admin) {
        await AuthService.instance.logout();

        if (!mounted) return;

        _showError(
          'Access denied. This account does not have administrator permissions.',
        );

        return;
      }

      // ----------------------------------------------------------
      // ADMIN LOGIN SUCCESSFUL
      // ----------------------------------------------------------

      Navigator.pushReplacementNamed(
        context,
        '/admin/dashboard',
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F8),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 460,
            ),

            child: Card(
              elevation: 4,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                ),

              child: Padding(
                padding: const EdgeInsets.all(36),

                child: Form(
                  key: _formKey,

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                    children: [
                      // ==================================================
                      // LOGO
                      // ==================================================

                      Center(
                        child: Container(
                          width: 90,
                          height: 90,

                          decoration:
                              const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF350044),
                          ),

                          child: const Center(
                            child: Text(
                              'RHIC',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ==================================================
                      // TITLE
                      // ==================================================

                      const Text(
                        'Admin Portal',
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF350044),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Sign in to manage the RHIC platform.',
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ==================================================
                      // EMAIL
                      // ==================================================

                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _emailController,

                        keyboardType:
                            TextInputType.emailAddress,

                        textInputAction:
                            TextInputAction.next,

                        autocorrect: false,

                        decoration:
                            _inputDecoration(
                          hint: 'Enter admin email',
                          icon: Icons.email_outlined,
                        ),

                        validator: (value) {
                          final email =
                              value?.trim() ?? '';

                          if (email.isEmpty) {
                            return 'Please enter your email address.';
                          }

                          final emailRegex =
                              RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );

                          if (!emailRegex
                              .hasMatch(email)) {
                            return 'Please enter a valid email address.';
                            }

                          return null;
                        },
                      ),

                      const SizedBox(height: 22),

                      // ==================================================
                      // PASSWORD
                      // ==================================================

                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller:
                            _passwordController,

                        obscureText:
                            _obscurePassword,

                        textInputAction:
                            TextInputAction.done,

                        autocorrect: false,

                        decoration:
                            _inputDecoration(
                          hint: 'Enter your password',
                          icon: Icons.lock_outline,
                        ).copyWith(
                          suffixIcon:
                              IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },

                            icon: Icon(
                              _obscurePassword
                                  ? Icons
                                      .visibility_off_outlined
                                  : Icons
                                      .visibility_outlined,
                              color:
                                  Colors.black54,
                            ),
                          ),
                        ),

                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Please enter your password.';
                          }

                          return null;
                        },

                        onFieldSubmitted: (_) {
                          if (!_isLoading) {
                            _login();
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // FORGOT PASSWORD
                      // ==================================================

                      Align(
                        alignment:
                            Alignment.centerRight,

                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : _forgotPassword,

                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              color:
                                  Color(0xFF6B238E),
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // LOGIN BUTTON
                      // ==================================================

                      SizedBox(
                        height: 58,

                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : _login,

                          style:
                              ElevatedButton.
                              styleFrom(
                            backgroundColor:
                                const Color(0xFF350044),

                            foregroundColor:
                                Colors.white,

                            disabledBackgroundColor:
                                const Color(
                              0xFF350044,
                            ).withValues(
                              alpha: 0.6,
                            ),

                            elevation: 0,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                            ),
                          ),

                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,

                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // SECURITY MESSAGE
                      // ==================================================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: const [
                          Icon(
                            Icons
                                .admin_panel_settings_outlined,
                            size: 18,
                            color: Colors.black45,
                          ),

                          SizedBox(width: 7),

                          Text(
                            'Authorized administrators only',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<void> _forgotPassword() async {
    final email =
        _emailController.text.trim();

    if (email.isEmpty) {
      _showError(
        'Enter your admin email address first.',
      );
      return;
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      _showError(
        'Please enter a valid email address.',
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      await AuthService.instance
          .sendPasswordResetEmail(
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
            behavior:
                SnackBarBehavior.floating,
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

    } finally {

      if (mounted) {

        setState(() {

          _isLoading = false;

        });

      }

    }

  }

  // ============================================================

  // INPUT DECORATION

  // ============================================================

  InputDecoration _inputDecoration({

    required String hint,

    required IconData icon,

  }) {

    return InputDecoration(

      hintText: hint,

      hintStyle: const TextStyle(

        color: Color(0xFF999999),

      ),

      prefixIcon: Icon(

        icon,

        color: Colors.black54,

      ),

      filled: true,

      fillColor: const Color(0xFFF4F2F5),

      contentPadding:

          const EdgeInsets.symmetric(

        horizontal: 18,

        vertical: 18,

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

        borderSide: const BorderSide(

          color: Color(0xFFE2E0E3),

        ),

      ),

      focusedBorder:

          OutlineInputBorder(

        borderRadius:

            BorderRadius.circular(12),

        borderSide: const BorderSide(

          color: Color(0xFF6B238E),

          width: 1.5,

        ),

      ),

      errorBorder:

          OutlineInputBorder(

        borderRadius:

            BorderRadius.circular(12),

        borderSide: const BorderSide(

          color: Colors.red,

        ),

      ),

      focusedErrorBorder:

          OutlineInputBorder(

        borderRadius:

            BorderRadius.circular(12),

        borderSide: const BorderSide(

          color: Colors.red,

          width: 1.2,

        ),

      ),

    );

  }

}