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
    try {
      print('🔧 PresetService.init() called');
      if (_prefs == null) {
        print('   - Getting SharedPreferences instance...');
        _prefs = await SharedPreferences.getInstance();
        print('   - SharedPreferences initialized successfully');
      } else {
        print('   - SharedPreferences already initialized');
      }
    } catch (e, stackTrace) {
      print('❌ Error initializing SharedPreferences: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
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
    print('📋 PresetService.savePreset() called');
    print('   Preset name: ${preset.name}');
    print('   Preset IP: ${preset.ip}');
    
    await init();
    print('   SharedPreferences initialized');
    
    final presets = await getAllPresets();
    print('   Current presets count: ${presets.length}');
    
    // Remove existing preset with same name or IP
    final removedCount = presets.length;
    presets.removeWhere((p) => p.name == preset.name || 
                             (p.ip == preset.ip && p.protocol == preset.protocol));
    print('   Removed ${removedCount - presets.length} duplicate presets');
    
    // Add new preset
    presets.insert(0, preset);
    print('   Added new preset, total count: ${presets.length}');
    
    // Keep only last 20 presets
    if (presets.length > 20) {
      presets.removeRange(20, presets.length);
      print('   Trimmed to 20 presets');
    }
    
    await _savePresets(presets);
    print('✅ Preset saved to SharedPreferences');
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
    try {
      print('💾 _savePresets called with ${presets.length} presets');
      
      final presetsJson = presets
          .map((preset) {
            print('   - Converting preset: ${preset.name}');
            final json = preset.toJson();
            print('   - JSON: $json');
            return jsonEncode(json);
          })
          .toList();
      
      print('   - Calling SharedPreferences.setStringList...');
      final success = await _prefs!.setStringList(_presetsKey, presetsJson);
      print('   - setStringList result: $success');
      
      // Verify it was saved
      final saved = _prefs!.getStringList(_presetsKey);
      print('   - Verification: Found ${saved?.length ?? 0} saved presets');
      
    } catch (e, stackTrace) {
      print('❌ Error in _savePresets: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
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