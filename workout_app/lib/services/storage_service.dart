import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blueprint_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session_models.dart';

class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    assert(_prefs != null, 'StorageService.init() must be called first');
    return _prefs!;
  }

  // ── Programs ──────────────────────────────────────────────────────────────

  Future<File> get _programsFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/programs.json');
  }

  Future<List<ProgramBlueprint>> loadPrograms() async {
    try {
      final file = await _programsFile;
      if (!await file.exists()) return [];
      final data = jsonDecode(await file.readAsString()) as List<dynamic>;
      return data
          .map((p) => ProgramBlueprint.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePrograms(List<ProgramBlueprint> programs) async {
    final file = await _programsFile;
    await file
        .writeAsString(jsonEncode(programs.map((p) => p.toJson()).toList()));
  }

  // ── Sessions ──────────────────────────────────────────────────────────────

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

  // ── Preferences ───────────────────────────────────────────────────────────

  String? getString(String key) => prefs.getString(key);
  Future<bool> setString(String key, String value) =>
      prefs.setString(key, value);

  bool? getBool(String key) => prefs.getBool(key);
  Future<bool> setBool(String key, bool value) => prefs.setBool(key, value);

  int? getInt(String key) => prefs.getInt(key);
  Future<bool> setInt(String key, int value) => prefs.setInt(key, value);

  Future<bool> remove(String key) => prefs.remove(key);

  // ── Active session ────────────────────────────────────────────────────────

  Future<File> get _activeSessionFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/active_session.json');
  }

  Future<void> saveActiveSession(Map<String, dynamic> data) async {
    final file = await _activeSessionFile;
    await file.writeAsString(jsonEncode(data));
  }

  Future<Map<String, dynamic>?> loadActiveSession() async {
    try {
      final file = await _activeSessionFile;
      if (!await file.exists()) return null;
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearActiveSession() async {
    final file = await _activeSessionFile;
    if (await file.exists()) await file.delete();
  }
}
