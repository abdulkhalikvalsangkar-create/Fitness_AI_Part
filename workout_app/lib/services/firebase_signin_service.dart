import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static bool _isGoogleSignInInitialized = false;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      if (!_isGoogleSignInInitialized) {
        try {
          await googleSignIn.initialize(
            serverClientId:
                "151714532695-epdeq9hiackpkqeqjqshbh1gfrfcooke.apps.googleusercontent.com",
          );
          _isGoogleSignInInitialized = true;
        } catch (e) {
          debugPrint("GoogleSignIn initialize error: $e");
        }
      }
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      final clientAuth = await googleUser.authorizationClient
          .authorizeScopes(['email', 'profile']);
      final String accessToken = clientAuth.accessToken;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e, stackTrace) {
      debugPrint("Google sign-in error: ${e.toString()}");
      debugPrint(stackTrace.toString());
    }
    return null;
  }
}

class FireStoreService {}
