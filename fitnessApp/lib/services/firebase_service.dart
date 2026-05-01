import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId:
            "151714532695-epdeq9hiackpkqeqjqshbh1gfrfcooke.apps.googleusercontent.com",
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final GoogleSignInClientAuthorization googleclientAuth = await googleUser
          .authorizationClient
          .authorizeScopes(['email', 'profile']);

      final GoogleSignInServerAuthorization? googleServerAuth = await googleUser
          .authorizationClient
          .authorizeServer(['email', 'profile']);

      debugPrint('GoogleSignIn user: ${googleUser?.email ?? "<no-user>"}');
      debugPrint(
        'GoogleSignIn serverAuthCode: ${googleServerAuth?.serverAuthCode}',
      );
      debugPrint('GoogleSignIn accessToken: ${googleclientAuth?.accessToken}');
      debugPrint('GoogleSignIn idToken: ${googleAuth?.idToken}');

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleclientAuth.accessToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on Exception catch (e) {
      // ShowToastDialog.closeLoader();
      debugPrint(e.toString());
      debugPrint("Google sign-in error: ${e.toString()}");
    }
    return null;
  }
}

class FireStoreService {}
