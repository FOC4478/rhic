import 'package:flutter/material.dart';
import 'package:church_app/l10n/app_localizations.dart';
import 'package:church_app/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please agree to the Terms of Service to continue.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String firstName =
          _firstNameController.text.trim();

      final String lastName =
          _lastNameController.text.trim();

      final String email =
          _emailController.text.trim().toLowerCase();

      final String password =
          _passwordController.text;

      await AuthService.instance.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/verification',
        arguments: {
          'email': email,
        },
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
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
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFAAAAAA),
        fontSize: 15,
      ),
      filled: true,
      fillColor: const Color(0xFFF3F3F3),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
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
        borderSide: const BorderSide(
          color: Color(0xFF5B126D),
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }

  // ============================================================
  // PASSWORD VALIDATION
  // ============================================================

  String? _validatePassword(
    String? value,
    AppLocalizations l10n,
  ) {
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }

    if (value.length < 8) {
      return l10n.passwordTooShort;
    }

    return null;
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
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              26,
              28,
              26,
              24,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // ==================================================
                // BACK BUTTON
                // ==================================================

                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () => Navigator.pop(context),

                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 21,
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // RHIC LOGO
                // ==================================================

                Center(
                  child: Image.asset(
                    'assets/images/coza_logo.png',
                    width: 115,
                    height: 115,
                    fit: BoxFit.contain,

                    errorBuilder: (_, __, ___) {
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

                const SizedBox(height: 25),

                // ==================================================
                // TITLE
                // ==================================================

                Text(
                  l10n.createAccount,

                  style: const TextStyle(
                    color: Color(0xFF5B126D),
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 42),

                // ==================================================
                // FIRST + LAST NAME
                // ==================================================

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    // FIRST NAME
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          _label(l10n.firstName),

                          TextFormField(
                            controller:
                                _firstNameController,

                            textInputAction:
                                TextInputAction.next,

                            textCapitalization:
                                TextCapitalization.words,

                            decoration:
                                _inputDecoration(
                              hint:
                                  l10n.enterFirstName,
                            ),

                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return l10n
                                    .firstNameRequired;
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 18),

                    // LAST NAME
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          _label(l10n.lastName),

                          TextFormField(
                            controller:
                                _lastNameController,

                            textInputAction:
                                TextInputAction.next,

                            textCapitalization:
                                TextCapitalization.words,

                            decoration:
                                _inputDecoration(
                              hint:
                                  l10n.enterLastName,
                            ),

                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return l10n
                                    .lastNameRequired;
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ==================================================
                // EMAIL
                // ==================================================

                _label(l10n.email),

                TextFormField(
                  controller: _emailController,

                  keyboardType:
                      TextInputType.emailAddress,

                  textInputAction:
                      TextInputAction.next,

                  autocorrect: false,

                  decoration: _inputDecoration(
                    hint: l10n.enterEmailAddress,
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return l10n.emailRequired;
                    }

                    final emailRegex = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    );

                    if (!emailRegex
                        .hasMatch(value.trim())) {
                      return l10n.invalidEmail;
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 28),

                // ==================================================
                // PASSWORD
                // ==================================================

                _label(l10n.password),

                TextFormField(
                  controller: _passwordController,

                  obscureText: _obscurePassword,

                  textInputAction:
                      TextInputAction.done,

                  autocorrect: false,

                  enableSuggestions: false,

                  decoration: _inputDecoration(
                    hint: l10n.enterPassword,

                    suffixIcon: IconButton(
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

                        color: Colors.black54,
                      ),
                    ),
                  ),

                  validator: (value) =>
                      _validatePassword(
                    value,
                    l10n,
                  ),
                ),

                const SizedBox(height: 34),

                // ==================================================
                // TERMS
                // ==================================================

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    SizedBox(
                      width: 24,
                      height: 24,

                      child: Checkbox(
                        value: _agreeToTerms,

                        activeColor:
                            const Color(0xFF5B126D),

                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _agreeToTerms =
                                      value ?? false;
                                });
                              },
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [

                            TextSpan(
                              text:
                                  l10n.agreeToTerms,

                              style:
                                  const TextStyle(
                                color:
                                    Colors.black87,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),

                            TextSpan(
                              text:
                                  l10n.termsOfService,

                              style:
                                  const TextStyle(
                                color:
                                    Color(0xFF298AC5),
                                fontSize: 14,
                                height: 1.4,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),

                            TextSpan(
                              text:
                                  l10n.ofUsingRhicApp,

                              style:
                                  const TextStyle(
                                color:
                                    Colors.black87,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),

                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ==================================================
                // CONTINUE BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 58,

                  child: ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _continue,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF3D004D),

                      disabledBackgroundColor:
                          const Color(0xFF3D004D)
                              .withValues(
                        alpha: 0.65,
                      ),

                      foregroundColor:
                          Colors.white,

                      elevation: 0,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          30,
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
                        : Text(
                            l10n.continueText,

                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 36),

                // ==================================================
                // LOGIN
                // ==================================================

                Center(
                  child: Wrap(
                    alignment:
                        WrapAlignment.center,

                    children: [

                      Text(
                        l10n.alreadyHaveAccount,

                        style:
                            const TextStyle(
                          fontSize: 14,
                          color:
                              Colors.black87,
                        ),
                      ),

                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                Navigator
                                    .pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              },

                        child: Text(
                          ' ${l10n.login}',

                          style:
                              const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}