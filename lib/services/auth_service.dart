import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

  bool get isLoggedIn => _auth.currentUser != null;

  // ============================================================
  // AUTH STATE
  // ============================================================

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============================================================
  // REGISTER
  // ============================================================

  Future<UserCredential> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String language = 'en',
  }) async {
    final String cleanFirstName = firstName.trim();
    final String cleanLastName = lastName.trim();
    final String cleanEmail = email.trim().toLowerCase();

    if (cleanFirstName.isEmpty) {
      throw const AuthException(
        'Please enter your first name.',
        code: 'invalid-first-name',
      );
    }

    if (cleanLastName.isEmpty) {
      throw const AuthException(
        'Please enter your last name.',
        code: 'invalid-last-name',
      );
    }

    if (cleanEmail.isEmpty) {
      throw const AuthException(
        'Please enter your email address.',
        code: 'invalid-email',
      );
    }

    if (!_isValidEmail(cleanEmail)) {
      throw const AuthException(
        'Please enter a valid email address.',
        code: 'invalid-email',
      );
    }

    if (password.length < 8) {
      throw const AuthException(
        'Password must be at least 8 characters.',
        code: 'weak-password',
      );
    }

    try {
      // ----------------------------------------------------------
      // Create account in Firebase Authentication
      // ----------------------------------------------------------

      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        throw const AuthException(
          'Unable to create your account. Please try again.',
          code: 'registration-failed',
        );
      }

      // ----------------------------------------------------------
      // Update Firebase Auth display name
      // ----------------------------------------------------------

      await user.updateDisplayName(
        '$cleanFirstName $cleanLastName',
      );

      // ----------------------------------------------------------
      // Create the user's profile in Firestore
      // ----------------------------------------------------------

      await _firestore.collection('users').doc(user.uid).set(
        {
          'uid': user.uid,
          'firstName': cleanFirstName,
          'lastName': cleanLastName,
          'fullName': '$cleanFirstName $cleanLastName',
          'email': cleanEmail,
          'language': language,
          'emailVerified': user.emailVerified,
          'role': 'member',
          'accountStatus': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // ----------------------------------------------------------
      // Send verification email
      // ----------------------------------------------------------

      await user.sendEmailVerification();

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } on FirebaseException catch (e) {
      throw AuthException(
        _handleFirestoreException(e),
        code: e.code,
      );
    }
  }

 
 
  // ============================================================
  // LOGIN
  // ============================================================

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final String cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      throw const AuthException(
        'Please enter your email address.',
        code: 'invalid-email',
      );
    }

    if (!_isValidEmail(cleanEmail)) {
      throw const AuthException(
        'Please enter a valid email address.',
        code: 'invalid-email',
      );
    }

    if (password.isEmpty) {
      throw const AuthException(
        'Please enter your password.',
        code: 'empty-password',
      );
    }

    try {
      final UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        throw const AuthException(
          'Unable to log you in. Please try again.',
          code: 'login-failed',
        );
      }

      // ----------------------------------------------------------
      // Refresh Firebase user information
      // ----------------------------------------------------------

      await user.reload();

      final User? refreshedUser = _auth.currentUser;

      if (refreshedUser == null) {
        throw const AuthException(
          'Unable to load your account.',
          code: 'user-not-found',
        );
      }

      // ----------------------------------------------------------
      // Keep Firestore verification status updated
      // ----------------------------------------------------------

      await _firestore
          .collection('users')
          .doc(refreshedUser.uid)
          .set(
        {
          'emailVerified': refreshedUser.emailVerified,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } on FirebaseException catch (e) {
      throw AuthException(
        _handleFirestoreException(e),
        code: e.code,
      );
    }
  }

  // ============================================================
  // CHECK EMAIL VERIFICATION
  // ============================================================

  Future<bool> isEmailVerified() async {
  final User? user = _auth.currentUser;

  if (user == null) {
    throw const AuthException(
      'No user is currently signed in.',
      code: 'not-authenticated',
    );
  }

  try {
    await user.reload();

    final User? refreshedUser = _auth.currentUser;

    if (refreshedUser == null) {
      throw const AuthException(
        'Unable to refresh your account.',
        code: 'user-not-found',
      );
    }

    return refreshedUser.emailVerified;
  } on FirebaseAuthException catch (e) {
    throw _handleFirebaseAuthException(e);
  }
}

  // ============================================================
  // RESEND VERIFICATION EMAIL
  // ============================================================

  Future<void> resendVerificationEmail() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'No account is currently signed in.',
        code: 'not-authenticated',
      );
    }

    try {
      await user.reload();

      final User? refreshedUser = _auth.currentUser;

      if (refreshedUser == null) {
        throw const AuthException(
          'Unable to find your account.',
          code: 'user-not-found',
        );
      }

      if (refreshedUser.emailVerified) {
        throw const AuthException(
          'Your email address has already been verified.',
          code: 'already-verified',
        );
      }

      await refreshedUser.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // ============================================================
  // PASSWORD RESET
  // ============================================================

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    final String cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      throw const AuthException(
        'Please enter your email address.',
        code: 'invalid-email',
      );
    }

    if (!_isValidEmail(cleanEmail)) {
      throw const AuthException(
        'Please enter a valid email address.',
        code: 'invalid-email',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(
        email: cleanEmail,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ============================================================
  // GET USER PROFILE
  // ============================================================

  Future<Map<String, dynamic>?> getUserProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> document =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

      if (!document.exists) {
        return null;
      }

      return document.data();
    } on FirebaseException catch (e) {
      throw AuthException(
        _handleFirestoreException(e),
        code: e.code,
      );
    }
  }

  // ============================================================
// CHECK ADMIN ROLE
// ============================================================

Future<bool> isAdmin() async {
  final User? user = _auth.currentUser;

  if (user == null) {
    return false;
  }

  try {
    final DocumentSnapshot<Map<String, dynamic>> document =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

    if (!document.exists) {
      return false;
    }

    final Map<String, dynamic>? data = document.data();

    return data?['role'] == 'admin';
  } on FirebaseException catch (e) {
    throw AuthException(
      _handleFirestoreException(e),
      code: e.code,
    );
  }
}

  // ============================================================
  // UPDATE LANGUAGE
  // ============================================================

  Future<void> updateLanguage(String language) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(
      {
        'language': language,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'You are not logged in.',
        code: 'not-authenticated',
      );
    }

    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    String? newFullName;

    if (firstName != null && firstName.trim().isNotEmpty) {
      updates['firstName'] = firstName.trim();
    }

    if (lastName != null && lastName.trim().isNotEmpty) {
      updates['lastName'] = lastName.trim();
    }

    if (firstName != null && lastName != null) {
      newFullName =
          '${firstName.trim()} ${lastName.trim()}';

      updates['fullName'] = newFullName;
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(
      updates,
      SetOptions(merge: true),
    );

    if (newFullName != null) {
      await user.updateDisplayName(newFullName);
    }
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  Future<void> deleteAccount() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'You are not logged in.',
        code: 'not-authenticated',
      );
    }

    try {
      // Delete Firestore profile first.
      await _firestore
          .collection('users')
          .doc(user.uid)
          .delete();

      // Delete Firebase Authentication account.
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } on FirebaseException catch (e) {
      throw AuthException(
        _handleFirestoreException(e),
        code: e.code,
      );
    }
  }

  // ============================================================
  // EMAIL VALIDATION
  // ============================================================

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailRegex.hasMatch(email);
  }

  // ============================================================
  // FIREBASE AUTH ERROR HANDLER
  // ============================================================

  AuthException _handleFirebaseAuthException(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'email-already-in-use':
        return const AuthException(
          'An account with this email already exists.',
          code: 'email-already-in-use',
        );

      case 'invalid-email':
        return const AuthException(
          'The email address is invalid.',
          code: 'invalid-email',
        );

      case 'weak-password':
        return const AuthException(
          'Your password is too weak. Use at least 8 characters.',
          code: 'weak-password',
        );

      case 'user-not-found':
        return const AuthException(
          'No account is registered with this email address.',
          code: 'user-not-found',
        );

      case 'wrong-password':
      case 'invalid-credential':
        return const AuthException(
          'The email or password is incorrect.',
          code: 'invalid-credential',
        );

      case 'user-disabled':
        return const AuthException(
          'This account has been disabled.',
          code: 'user-disabled',
        );

      case 'too-many-requests':
        return const AuthException(
          'Too many attempts. Please wait a while and try again.',
          code: 'too-many-requests',
        );

      case 'network-request-failed':
        return const AuthException(
          'Network error. Please check your internet connection.',
          code: 'network-request-failed',
        );

      case 'operation-not-allowed':
        return const AuthException(
          'Email and password authentication is not enabled.',
          code: 'operation-not-allowed',
        );

      case 'requires-recent-login':
        return const AuthException(
          'Please log in again before performing this action.',
          code: 'requires-recent-login',
        );

      default:
        return AuthException(
          e.message ?? 'Authentication failed. Please try again.',
          code: e.code,
        );
    }
  }

  // ============================================================
  // FIRESTORE ERROR HANDLER
  // ============================================================

  String _handleFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action.';

      case 'unavailable':
        return 'The service is temporarily unavailable. Please try again.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      default:
        return e.message ??
            'Unable to access your account data.';
    }
  }
}

// ================================================================
// CUSTOM AUTH EXCEPTION
// ================================================================

class AuthException implements Exception {
  final String message;
  final String code;

  const AuthException(
    this.message, {
    required this.code,
  });

  @override
  String toString() => message;
}