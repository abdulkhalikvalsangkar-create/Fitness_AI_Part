import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_models.dart';
import '../services/storage_service.dart';

class HistoryNotifier extends AsyncNotifier<List<Session>> {
  @override
  Future<List<Session>> build() async {
    // final sessions = await StorageService.instance.loadSessions();
    final sessions = await StorageService.instance.getSessions();
    // Sort newest first
    sessions.sort((a, b) => b.date.compareTo(a.date));
    return sessions;
  }

  Future<void> addSession(Session session) async {
    state = await AsyncValue.guard(() async {
      final sessions = <Session>[session, ...?state.value];
      sessions.sort((a, b) => b.date.compareTo(a.date));
      // await StorageService.instance.saveSessions(sessions);
      await StorageService.instance.saveSession(session);
      return sessions;
    });
  }

  Future<void> updateSession(Session session) async {
    state = await AsyncValue.guard(() async {
      final sessions = <Session>[
        for (final s in state.value ?? []) s.id == session.id ? session : s,
      ];
      // await StorageService.instance.saveSessions(sessions);
      await StorageService.instance.saveSession(session);
      return sessions;
    });
  }

  Future<void> deleteSession(String sessionId) async {
    state = await AsyncValue.guard(() async {
      await StorageService.instance.deleteSession(sessionId);
      final sessions = <Session>[
        for (final s in state.value ?? [])
          if (s.id != sessionId) s,
      ];
      // await StorageService.instance.saveSessions(sessions);
      return sessions;
    });
  }

  /// Merges imported sessions (by id) into existing, then saves.
  // Future<void> upsertSessions(List<Session> imported) async {
  //   state = await AsyncValue.guard(() async {
  //     final existing = Map<String, Session>.fromEntries(
  //       (state.value ?? []).map((s) => MapEntry(s.id, s)),
  //     );
  //     for (final s in imported) {
  //       existing[s.id] = s;
  //     }
  //     final sessions = existing.values.toList()
  //       ..sort((a, b) => b.date.compareTo(a.date));
  //     await StorageService.instance.saveSessions(sessions);
  //     return sessions;
  //   });
  // }
  Future<void> upsertSessions(List<Session> imported) async {
    final firestore = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final batch = firestore.batch();

    final collection =
        firestore.collection('users').doc(uid).collection('sessions');

    for (final s in imported) {
      final doc = collection.doc(s.id);
      batch.set(doc, s.toJson());
    }

    await batch.commit();
  }
}

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<Session>>(HistoryNotifier.new);
