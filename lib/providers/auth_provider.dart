import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoggedIn = false;
  String? _userEmail;
  String? _userName;
  User? _firebaseUser;

  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  User? get firebaseUser => _firebaseUser;
  String? _lastAuthError;
  String? get lastAuthError => _lastAuthError;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _firebaseUser = user;
        _isLoggedIn = true;
        _userEmail = user.email;
        _userName = user.displayName ?? user.email?.split('@')[0];
        _saveAuthState();
        notifyListeners();
      } else {
        _isLoggedIn = false;
        _userEmail = null;
        _userName = null;
        _firebaseUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadAuthState() async {
    // Always prefer Firebase as source of truth - wait for auth to initialize
    _firebaseUser = _auth.currentUser;
    if (_firebaseUser != null) {
      _isLoggedIn = true;
      _userEmail = _firebaseUser!.email;
      _userName = _firebaseUser!.displayName ?? _userEmail?.split('@')[0];
      await _saveAuthState();
    } else {
      // Firebase session expired or signed out - clear stale SharedPreferences
      _isLoggedIn = false;
      _userEmail = null;
      _userName = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userNameKey);
    }
    notifyListeners();
  }

  Future<void> _saveAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, _isLoggedIn);
    if (_userEmail != null) await prefs.setString(_userEmailKey, _userEmail!);
    if (_userName != null) await prefs.setString(_userNameKey, _userName!);
  }

  Future<bool> login(String email, String password) async {
    _lastAuthError = null;
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (userCredential.user != null) {
        _firebaseUser = userCredential.user;
        _isLoggedIn = true;
        _userEmail = userCredential.user!.email;
        _userName = userCredential.user!.displayName ?? _userEmail?.split('@')[0];
        await _saveAuthState();
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Login error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
          _lastAuthError = 'Invalid email or password. Please try again.';
          break;
        case 'invalid-email':
          _lastAuthError = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          _lastAuthError = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          _lastAuthError = 'Too many attempts. Please try again later.';
          break;
        case 'invalid-credential':
          _lastAuthError = 'Invalid email or password. Please try again.';
          break;
        default:
          _lastAuthError = e.message ?? 'Login failed. Please try again.';
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      _lastAuthError = 'Login failed. Please check your connection and try again.';
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password, String confirmPassword) async {
    _lastAuthError = null;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _lastAuthError = 'Please fill in all fields.';
      return false;
    }
    if (password != confirmPassword) {
      _lastAuthError = 'Passwords do not match.';
      return false;
    }
    if (password.length < 6) {
      _lastAuthError = 'Password must be at least 6 characters.';
      return false;
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        await userCredential.user!.reload();
        _firebaseUser = _auth.currentUser;
        _isLoggedIn = true;
        _userEmail = userCredential.user!.email;
        _userName = name;
        await _saveAuthState();
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Signup error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'email-already-in-use':
          _lastAuthError = 'This email is already registered. Try logging in.';
          break;
        case 'invalid-email':
          _lastAuthError = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          _lastAuthError = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'operation-not-allowed':
          _lastAuthError = 'Email signup is not enabled. Contact support.';
          break;
        default:
          _lastAuthError = e.message ?? 'Signup failed. Please try again.';
      }
      return false;
    } catch (e) {
      debugPrint('Signup error: $e');
      _lastAuthError = 'Signup failed. Please check your connection and try again.';
      return false;
    }
  }

  Future<void> updateProfile(String name, String email) async {
    try {
      if (_firebaseUser != null) {
        await _firebaseUser!.updateDisplayName(name);
        if (email != _firebaseUser!.email) {
          await _firebaseUser!.verifyBeforeUpdateEmail(email);
        }
        await _firebaseUser!.reload();
        _firebaseUser = _auth.currentUser;
        _userName = name;
        _userEmail = email;
        await _saveAuthState();
        notifyListeners();
      } else {
        // Fallback to SharedPreferences if Firebase not available
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userNameKey, name);
        await prefs.setString(_userEmailKey, email);
        _userName = name;
        _userEmail = email;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userNameKey, name);
      await prefs.setString(_userEmailKey, email);
      _userName = name;
      _userEmail = email;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    _isLoggedIn = false;
    _userEmail = null;
    _userName = null;
    _firebaseUser = null;
    notifyListeners();
  }
}
