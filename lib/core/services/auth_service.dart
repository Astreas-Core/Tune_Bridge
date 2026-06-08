import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:tune_bridge/core/services/firebase_sync_service.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/core/di.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _log = Logger();

  AuthService() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        getIt<FirebaseSyncService>().startSync();
      } else {
        getIt<FirebaseSyncService>().stopSync();
      }
    });
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _log.i("User signed in: ${credential.user?.uid}");
      return credential.user;
    } on FirebaseAuthException catch (e) {
      _log.e("Firebase auth error: ${e.message}");
      throw Exception(e.message ?? 'Authentication failed');
    } catch (e) {
      _log.e("Sign in error: $e");
      throw Exception('An unexpected error occurred');
    }
  }

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _log.i("User created: ${credential.user?.uid}");
      return credential.user;
    } on FirebaseAuthException catch (e) {
      _log.e("Firebase auth error: ${e.message}");
      throw Exception(e.message ?? 'Registration failed');
    } catch (e) {
      _log.e("Registration error: $e");
      throw Exception('An unexpected error occurred');
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled the sign-in flow
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      _log.i("User signed in with Google: ${userCredential.user?.uid}");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      _log.e("Google Sign-In Firebase error: ${e.message}");
      throw Exception(e.message ?? 'Google Sign-In failed');
    } catch (e) {
      _log.e("Google Sign-In error: $e");
      throw Exception('An unexpected error occurred during Google Sign-In');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      // Wipe local storage so new user doesn't see old data
      await getIt<LocalLibraryService>().clearAll();
      _log.i("User signed out and local storage cleared");
    } catch (e) {
      _log.e("Sign out error: $e");
    }
  }
}
