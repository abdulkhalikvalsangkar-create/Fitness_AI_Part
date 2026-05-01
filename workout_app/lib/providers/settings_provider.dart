import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weight.dart';
import '../services/storage_service.dart';

class RemoteBackupSettings {
  final String endpoint;
  final String apiKey;

  const RemoteBackupSettings({this.endpoint = '', this.apiKey = ''});

  RemoteBackupSettings copyWith({String? endpoint, String? apiKey}) =>
      RemoteBackupSettings(
        endpoint: endpoint ?? this.endpoint,
        apiKey: apiKey ?? this.apiKey,
      );
}

class AppSettings {
  final WeightUnit weightUnit;
  final String? activeProgramId;
  final bool showBodyweight;
  final bool keepScreenAwake;
  final int firstDayOfWeek; // DateTime.monday=1 ... DateTime.sunday=7
  final bool notesExpandedByDefault;
  final RemoteBackupSettings remoteBackup;

  const AppSettings({
    this.weightUnit = WeightUnit.kilograms,
    this.activeProgramId,
    this.showBodyweight = true,
    this.keepScreenAwake = false,
    this.firstDayOfWeek = DateTime.sunday,
    this.notesExpandedByDefault = false,
    this.remoteBackup = const RemoteBackupSettings(),
  });

  AppSettings copyWith({
    WeightUnit? weightUnit,
    String? activeProgramId,
    bool? showBodyweight,
    bool? keepScreenAwake,
    int? firstDayOfWeek,
    bool? notesExpandedByDefault,
    RemoteBackupSettings? remoteBackup,
    bool clearActiveProgramId = false,
  }) {
    return AppSettings(
      weightUnit: weightUnit ?? this.weightUnit,
      activeProgramId: clearActiveProgramId
          ? null
          : (activeProgramId ?? this.activeProgramId),
      showBodyweight: showBodyweight ?? this.showBodyweight,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      notesExpandedByDefault:
          notesExpandedByDefault ?? this.notesExpandedByDefault,
      remoteBackup: remoteBackup ?? this.remoteBackup,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final s = StorageService.instance;
    final unitStr = s.getString('weightUnit');
    return AppSettings(
      weightUnit: unitStr == 'pounds' ? WeightUnit.pounds : WeightUnit.kilograms,
      activeProgramId: s.getString('activeProgramId'),
      showBodyweight: s.getBool('showBodyweight') ?? true,
      keepScreenAwake: s.getBool('keepScreenAwake') ?? false,
      firstDayOfWeek: s.getInt('firstDayOfWeek') ?? DateTime.sunday,
      notesExpandedByDefault: s.getBool('notesExpandedByDefault') ?? false,
      remoteBackup: RemoteBackupSettings(
        endpoint: s.getString('remoteBackupEndpoint') ?? '',
        apiKey: s.getString('remoteBackupApiKey') ?? '',
      ),
    );
  }

  Future<void> setWeightUnit(WeightUnit unit) async {
    await StorageService.instance.setString('weightUnit', unit.name);
    state = state.copyWith(weightUnit: unit);
  }

  Future<void> setActiveProgram(String? programId) async {
    if (programId == null) {
      await StorageService.instance.remove('activeProgramId');
      state = state.copyWith(clearActiveProgramId: true);
    } else {
      await StorageService.instance.setString('activeProgramId', programId);
      state = state.copyWith(activeProgramId: programId);
    }
  }

  Future<void> setShowBodyweight(bool value) async {
    await StorageService.instance.setBool('showBodyweight', value);
    state = state.copyWith(showBodyweight: value);
  }

  Future<void> setKeepScreenAwake(bool value) async {
    await StorageService.instance.setBool('keepScreenAwake', value);
    state = state.copyWith(keepScreenAwake: value);
  }

  Future<void> setFirstDayOfWeek(int day) async {
    await StorageService.instance.setInt('firstDayOfWeek', day);
    state = state.copyWith(firstDayOfWeek: day);
  }

  Future<void> setNotesExpandedByDefault(bool value) async {
    await StorageService.instance.setBool('notesExpandedByDefault', value);
    state = state.copyWith(notesExpandedByDefault: value);
  }

  Future<void> setRemoteBackup(RemoteBackupSettings rb) async {
    await StorageService.instance.setString('remoteBackupEndpoint', rb.endpoint);
    await StorageService.instance.setString('remoteBackupApiKey', rb.apiKey);
    state = state.copyWith(remoteBackup: rb);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
