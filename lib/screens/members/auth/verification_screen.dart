import 'package:church_app/l10n/app_localizations.dart';
import 'package:church_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() =>
      _VerificationScreenState();
}

class _VerificationScreenState
    extends State<VerificationScreen> {
  final AuthService _authService = AuthService.instance;

  bool _isLoading = false;
  bool _isChecking = false;
  bool _emailSent = true;

  @override
  void initState() {
    super.initState();

    _initializeVerification();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initializeVerification() async {
    final user = _authService.currentUser;

    // No authenticated user.
    if (user == null) {
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );

      return;
    }

    // Reload Firebase user information.
    try {
      await user.reload();
    } catch (_) {
      // We don't block the screen if reload fails.
    }

    final refreshedUser = _authService.currentUser;

    // User is already verified.
    if (refreshedUser?.emailVerified == true) {
      _goToHome();
    }
  }

  // ============================================================
  // RESEND VERIFICATION EMAIL
  // ============================================================

  Future<void> _sendVerificationEmail() async {
    if (_isLoading) return;

    final user = _authService.currentUser;

    if (user == null) {
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );

      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.resendVerificationEmail();

      if (!mounted) return;

      setState(() {
        _emailSent = true;
      });

      _showMessage(
        'Verification email sent. Please check your inbox.',
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      _showError(e.message);
    } catch (_) {
      if (!mounted) return;

      _showError(
        'Unable to send the verification email. Please try again.',
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
  // CHECK VERIFICATION
  // ============================================================

  Future<void> _checkVerification() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      final bool verified =
          await _authService.isEmailVerified();

      if (verified) {
        _goToHome();
        return;
      }

      if (!mounted) return;

      _showError(
        'Your email has not been verified yet. Please click the verification link in your email.',
      );
    } catch (_) {
      if (!mounted) return;

      _showError(
        'Unable to check your verification status. Please try again.',
      );
    } finally {
      if (!mounted) {
        setState(() {
        _isChecking = false;
      });
      }

      
    }
  }

  // ============================================================
  // GO TO HOME
  // ============================================================

  void _goToHome() {
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      // Continue to login even if logout encounters an issue.
    }

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  // ============================================================
  // SUCCESS MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final String userEmail =
        _authService.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.black,
          ),
          onPressed: _logout,
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
          ),

          child: Column(
            children: [
              const SizedBox(height: 45),

              // ==================================================
              // EMAIL ICON
              // ==================================================

              Container(
                height: 90,
                width: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF3FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 45,
                  color: Color(0xFF1769E0),
                ),
              ),

              const SizedBox(height: 35),

              // ==================================================
              // TITLE
              // ==================================================

              Text(
                l10n.verifyYourEmail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // DESCRIPTION
              // ==================================================

              Text(
                l10n.verificationDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // EMAIL
              // ==================================================

              Text(
                userEmail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1769E0),
                ),
              ),

              const SizedBox(height: 35),

              // ==================================================
              // INSTRUCTIONS
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 22,
                      color: Color(0xFF1769E0),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Open the verification email we sent you and click the "Verify Email" link. Then return here and tap "I\'ve Verified My Email".',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // RESEND
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _sendVerificationEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF1769E0),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF9BBBEF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.resendVerificationEmail,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // I'VE VERIFIED
              // ==================================================

              TextButton(
                onPressed:
                    _isChecking
                        ? null
                        : _checkVerification,
                child: _isChecking
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Color(0xFF1769E0),
                        ),
                      )
                    : Text(
                        l10n.iHaveVerified,
                        style: const TextStyle(
                          color:
                              Color(0xFF1769E0),
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // EMAIL SENT
              // ==================================================

              if (_emailSent)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFF0F7FF),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color:
                            Color(0xFF1769E0),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.checkYourInbox,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color:
                                Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 40),

              // ==================================================
              // USE ANOTHER ACCOUNT
              // ==================================================

              TextButton(
                onPressed: _logout,
                child: Text(
                  l10n.useAnotherAccount,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}