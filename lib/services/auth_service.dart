import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/log.dart';
import 'firestore_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthService() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Sign up with email and password
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Create user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      if (userCredential.user != null && displayName.isNotEmpty) {
        await userCredential.user!.updateDisplayName(displayName);
        await userCredential.user!.reload();
        _user = _auth.currentUser;
        try {
          await FirestoreService.instance.ensureUserProfile(
            userCredential.user!.uid,
            displayName: displayName,
            email: email,
          );
        } catch (e) {
          logError('Saving user profile', e);
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Došlo je do greške. Pokušajte ponovo.';
      notifyListeners();
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      _user = _auth.currentUser;
      if (_user != null) {
        try {
          await FirestoreService.instance.ensureUserProfile(
            _user!.uid,
            displayName: _user!.displayName,
            email: _user!.email,
          );
        } catch (e) {
          logError('Saving user profile', e);
        }
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Došlo je do greške. Pokušajte ponovo.';
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Greška pri odjavi. Pokušajte ponovo.';
      notifyListeners();
    }
  }

  /// Permanently deletes the account after confirming the password.
  /// Returns null on success, otherwise a message for the user.
  Future<String?> deleteAccount(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return 'Niste prijavljeni.';
    try {
      _isLoading = true;
      notifyListeners();
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      await FirestoreService.instance.deleteUserData(
        user.uid,
        displayName: user.displayName,
      );
      await user.delete();
      _user = null;
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (_) {
      return 'Brisanje naloga nije uspjelo. Pokušajte ponovo.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email.trim());

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Došlo je do greške. Pokušajte ponovo.';
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get user-friendly error messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Lozinka je preslaba.';
      case 'email-already-in-use':
        return 'Nalog sa ovim podacima već postoji.';
      case 'invalid-email':
        return 'Neispravni podaci za prijavu.';
      case 'user-disabled':
        return 'Ovaj nalog je onemogućen.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Korisničko ime ili lozinka nisu ispravni.';
      case 'too-many-requests':
        return 'Previše pokušaja. Pokušajte ponovo malo kasnije.';
      case 'operation-not-allowed':
        return 'Prijava trenutno nije omogućena.';
      case 'network-request-failed':
        return 'Nema internet konekcije. Provjerite vezu i pokušajte ponovo.';
      default:
        return 'Došlo je do greške. Pokušajte ponovo.';
    }
  }
}
