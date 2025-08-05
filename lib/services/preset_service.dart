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
        
        // Test basic functionality
        print('   - Testing SharedPreferences write/read...');
        await _prefs!.setString('test_key', 'test_value');
        final testValue = _prefs!.getString('test_key');
        print('   - Test write/read result: $testValue');
        
        if (testValue == 'test_value') {
          print('   - ✅ SharedPreferences is working correctly');
        } else {
          print('   - ❌ SharedPreferences test failed!');
        }
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
    try {
      print('📖 SIMPLE getAllPresets() called');
      await init();
      
      // Get simple preset list
      final presetNames = _prefs!.getStringList('simple_preset_list') ?? [];
      print('   Found ${presetNames.length} simple presets in storage');
      
      if (presetNames.isEmpty) {
        print('   No simple presets found, returning empty list');
        return [];
      }
      
      final presets = <DDCPreset>[];
      for (final name in presetNames) {
        try {
          final presetKey = 'simple_preset_$name';
          final presetData = _prefs!.getString(presetKey);
          
          if (presetData != null) {
            final parts = presetData.split('|');
            if (parts.length >= 3) {
              final preset = DDCPreset(
                name: name,
                protocol: parts[0],
                ip: parts[1],
                resolution: parts[2],
                createdAt: parts.length > 3 
                  ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(parts[3]) ?? 0)
                  : DateTime.now(),
              );
              presets.add(preset);
              print('   ✅ Successfully loaded simple preset: $name');
            }
          }
        } catch (e) {
          print('   ❌ Error loading preset $name: $e');
          // Skip malformed preset
        }
      }
      
      print('   Returning ${presets.length} valid simple presets');
      return presets;
      
    } catch (e, stackTrace) {
      print('❌ Error in getAllPresets: $e');
      print('   Stack trace: $stackTrace');
      return []; // Return empty list on error
    }
  }

  Future<void> savePreset(DDCPreset preset) async {
    print('📋 SIMPLE PresetService.savePreset() called');
    print('   Preset name: ${preset.name}');
    print('   Preset IP: ${preset.ip}');
    
    try {
      await init();
      print('   SharedPreferences initialized');
      
      // SIMPLE APPROACH: Save individual preset data directly
      final presetKey = 'simple_preset_${preset.name}';
      final presetData = '${preset.protocol}|${preset.ip}|${preset.resolution}|${DateTime.now().millisecondsSinceEpoch}';
      
      print('   Saving preset data: $presetData');
      await _prefs!.setString(presetKey, presetData);
      
      // Verify it was saved
      final saved = _prefs!.getString(presetKey);
      print('   Verification read: $saved');
      
      if (saved == presetData) {
        // Add to preset list
        final presetList = _prefs!.getStringList('simple_preset_list') ?? [];
        if (!presetList.contains(preset.name)) {
          presetList.insert(0, preset.name);
          await _prefs!.setStringList('simple_preset_list', presetList);
          print('   Added to preset list, total presets: ${presetList.length}');
        }
        print('✅ SIMPLE preset saved successfully');
      } else {
        throw Exception('Preset save verification failed');
      }
      
    } catch (e, stackTrace) {
      print('❌ DETAILED ERROR in savePreset: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deletePreset(String name) async {
    try {
      print('🗑️ SIMPLE deletePreset() called: $name');
      await init();
      
      // Remove from preset list
      final presetList = _prefs!.getStringList('simple_preset_list') ?? [];
      presetList.remove(name);
      await _prefs!.setStringList('simple_preset_list', presetList);
      
      // Remove preset data
      final presetKey = 'simple_preset_$name';
      await _prefs!.remove(presetKey);
      
      print('   ✅ Simple preset deleted: $name');
    } catch (e) {
      print('   ❌ Error deleting preset: $e');
    }
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