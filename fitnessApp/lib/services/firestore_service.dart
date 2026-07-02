import 'package:FitnessApp/models/UserProfile_model.dart';
import 'package:FitnessApp/models/session_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:FitnessApp/services/csv_login_service.dart';
import 'package:FitnessApp/services/csv_health_service.dart';

class StorageService {
  static StorageService? _instance;
  // SharedPreferences? _prefs;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  CollectionReference get _sessionsRef =>
      _firestore.collection('users').doc(_uid).collection('sessions');

  // Future<File> get _sessionsFile async {
  //   final dir = await getApplicationDocumentsDirectory();
  //   return File('${dir.path}/sessions.json');
  // }

  // Future<List<Session>> loadSessions() async {
  //   try {
  //     final file = await _sessionsFile;
  //     if (!await file.exists()) return [];
  //     final data = jsonDecode(await file.readAsString()) as List<dynamic>;
  //     return data
  //         .map((s) => Session.fromJson(s as Map<String, dynamic>))
  //         .toList();
  //   } catch (_) {
  //     return [];
  //   }
  // }
  Future<void> deleteSession(String sessionId) async {
    await _sessionsRef.doc(sessionId).delete();
  }

  Future<List<Session>> getSessions() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Session.fromJson(doc.data(), doc.id))
        .toList();
  }

  // Future<void> saveSessions(List<Session> sessions) async {
  //   final file = await _sessionsFile;
  //   await file.writeAsString(
  //       jsonEncode(sessions.map((s) => s.toJson()).toList()));
  // }
  Future<void> saveSession(Session session) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(session.id); // use your session.id here

    await docRef.set(session.toJson());
  }

  // Future<void> saveUserProfile(UserProfile user) async {
  //   FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(user.uid)
  //       .set(user.toJson());
  // }
  Future<void> saveUserProfile(UserProfile user) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userprofile')
        .doc('profile')
        .set(user.toJson());
  }

  // Future<UserProfile?> getUserProfile() async {
  //   final uid = _auth.currentUser!.uid;
  //   final doc = await FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(uid)
  //       .get();
  //   if (!doc.exists) return null;

  //   return UserProfile.fromJson(doc.data()!);
  // }
  // Future<UserProfile?> getUserProfile() async {
  //   final uid = FirebaseAuth.instance.currentUser!.uid;
  //
  //   final doc = await FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(uid)
  //       .collection('userprofile')
  //       .doc('profile')
  //       .get();
  //
  //   if (!doc.exists) {
  //     print("Doc doesn't exit");
  //     return null;
  //   }
  //   // print(doc.data());
  //
  //   var user = UserProfile.fromJson(doc.data()!);
  //   print("User $user");
  //   return user;
  // }

  Future<UserProfile?> getUserProfile() async {
    // First check whether a CSV user is logged in
    final csvUserId = await CsvLoginService.getLoggedInUser();

    if (csvUserId != null) {
      final csvProfile =
      await CsvHealthService().getProfileByUserId(csvUserId);

      if (csvProfile == null) return null;

      return UserProfile(
        uid: csvProfile.userId,
        name: csvProfile.userId,
        age: csvProfile.age.toString(),
        height: csvProfile.height,
        weight: csvProfile.weight,
        gender: csvProfile.gender,
      );
    }

    // Normal Firebase user
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('userprofile')
        .doc('profile')
        .get();

    if (!doc.exists) {
      return null;
    }

    return UserProfile.fromJson(doc.data()!);
  }
}
