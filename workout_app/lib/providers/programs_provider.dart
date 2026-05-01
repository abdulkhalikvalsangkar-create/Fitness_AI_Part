import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/blueprint_models.dart';
import '../services/built_in_programs.dart';
import '../services/storage_service.dart';

class ProgramsNotifier extends AsyncNotifier<List<ProgramBlueprint>> {
  @override
  Future<List<ProgramBlueprint>> build() async {
    var programs = await StorageService.instance.loadPrograms();
    if (programs.isEmpty) {
      programs = List<ProgramBlueprint>.from(builtInPrograms);
      await StorageService.instance.savePrograms(programs);
    }
    return programs;
  }

  Future<void> addProgram(ProgramBlueprint program) async {
    state = await AsyncValue.guard(() async {
      final programs = <ProgramBlueprint>[...?state.value, program];
      await StorageService.instance.savePrograms(programs);
      return programs;
    });
  }

  Future<void> updateProgram(ProgramBlueprint program) async {
    state = await AsyncValue.guard(() async {
      final programs = <ProgramBlueprint>[
        for (final p in state.value ?? []) p.id == program.id ? program : p,
      ];
      await StorageService.instance.savePrograms(programs);
      return programs;
    });
  }

  Future<void> deleteProgram(String programId) async {
    state = await AsyncValue.guard(() async {
      final programs = <ProgramBlueprint>[
        for (final p in state.value ?? [])
          if (p.id != programId) p,
      ];
      await StorageService.instance.savePrograms(programs);
      return programs;
    });
  }

  /// Merges imported programs (by id) into existing, then saves.
  Future<void> upsertPrograms(Map<String, ProgramBlueprint> imported) async {
    state = await AsyncValue.guard(() async {
      final existing = Map<String, ProgramBlueprint>.fromEntries(
        (state.value ?? []).map((p) => MapEntry(p.id, p)),
      );
      existing.addAll(imported);
      final programs = existing.values.toList();
      await StorageService.instance.savePrograms(programs);
      return programs;
    });
  }

  ProgramBlueprint createNewProgram() {
    return ProgramBlueprint(
      id: const Uuid().v4(),
      name: 'New Program',
      sessions: const [],
      lastEdited: DateTime.now(),
    );
  }
}

final programsProvider =
    AsyncNotifierProvider<ProgramsNotifier, List<ProgramBlueprint>>(
        ProgramsNotifier.new);
