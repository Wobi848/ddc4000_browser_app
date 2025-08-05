import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ddc_preset.dart';

class PresetService {
  static const String _presetsKey = 'ddc_presets';
  static const String _autoloadKey = 'ddc_autoload_preset';

  static PresetService? _instance;
  static PresetService get instance => _instance ??= PresetService._();
  PresetService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<DDCPreset>> getAllPresets() async {
    await init();
    final presetsJson = _prefs!.getStringList(_presetsKey) ?? [];
    
    return presetsJson
        .map((json) => DDCPreset.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.lastUsed?.compareTo(a.lastUsed ?? DateTime(1970)) ?? 0);
  }

  Future<void> savePreset(DDCPreset preset) async {
    await init();
    final presets = await getAllPresets();
    
    // Remove existing preset with same name or IP
    presets.removeWhere((p) => p.name == preset.name || 
                             (p.ip == preset.ip && p.protocol == preset.protocol));
    
    // Add new preset
    presets.insert(0, preset);
    
    // Keep only last 20 presets
    if (presets.length > 20) {
      presets.removeRange(20, presets.length);
    }
    
    await _savePresets(presets);
  }

  Future<void> deletePreset(String name) async {
    await init();
    final presets = await getAllPresets();
    presets.removeWhere((p) => p.name == name);
    await _savePresets(presets);
  }

  Future<void> updateLastUsed(String name) async {
    await init();
    final presets = await getAllPresets();
    final index = presets.indexWhere((p) => p.name == name);
    
    if (index != -1) {
      presets[index] = presets[index].copyWith(lastUsed: DateTime.now());
      await _savePresets(presets);
    }
  }

  Future<void> setAutoloadPreset(String? presetName) async {
    await init();
    if (presetName == null) {
      await _prefs!.remove(_autoloadKey);
    } else {
      await _prefs!.setString(_autoloadKey, presetName);
    }
  }

  Future<String?> getAutoloadPreset() async {
    await init();
    return _prefs!.getString(_autoloadKey);
  }

  Future<DDCPreset?> getPresetByName(String name) async {
    final presets = await getAllPresets();
    try {
      return presets.firstWhere((p) => p.name == name);
    } catch (e) {
      return null;
    }
  }

  Future<void> _savePresets(List<DDCPreset> presets) async {
    final presetsJson = presets
        .map((preset) => jsonEncode(preset.toJson()))
        .toList();
    
    await _prefs!.setStringList(_presetsKey, presetsJson);
  }

  Future<void> clearAllPresets() async {
    await init();
    await _prefs!.remove(_presetsKey);
    await _prefs!.remove(_autoloadKey);
  }

  // Common IP suggestions
  List<String> getCommonIpSuggestions() {
    return [
      '192.168.1.1',
      '192.168.0.1', 
      '192.168.10.21',
      '10.0.0.1',
      '172.16.0.1',
      '127.0.0.1',
    ];
  }
}