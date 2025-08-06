import 'package:flutter/material.dart';
import '../models/ddc_preset.dart';
import '../services/preset_service.dart';

class PresetSelectorWidget extends StatefulWidget {
  final DDCPreset? currentPreset;
  final Function(DDCPreset) onPresetSelected;
  final VoidCallback onSavePreset;

  const PresetSelectorWidget({
    super.key,
    this.currentPreset,
    required this.onPresetSelected,
    required this.onSavePreset,
  });

  @override
  State<PresetSelectorWidget> createState() => _PresetSelectorWidgetState();
}

class _PresetSelectorWidgetState extends State<PresetSelectorWidget> {
  List<DDCPreset> _presets = [];
  String? _autoloadPreset;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    print('🔧 PresetSelectorWidget._loadPresets() called');
    setState(() => _isLoading = true);
    
    try {
      print('   Calling PresetService.getAllPresets()...');
      final presets = await PresetService.instance.getAllPresets();
      print('   Received ${presets.length} presets from service');
      
      for (int i = 0; i < presets.length; i++) {
        print('   Preset $i: ${presets[i].name} (${presets[i].protocol}://${presets[i].ip})');
      }
      
      print('   Getting autoload preset...');
      final autoload = await PresetService.instance.getAutoloadPreset();
      print('   Autoload preset: $autoload');
      
      setState(() {
        _presets = presets;
        _autoloadPreset = autoload;
        _isLoading = false;
      });
      
      print('   UI updated with ${_presets.length} presets');
    } catch (e) {
      print('❌ Error loading presets: $e');
      
      setState(() {
        _presets = [];
        _autoloadPreset = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _setAutoloadPreset(String? presetName) async {
    await PresetService.instance.setAutoloadPreset(presetName);
    setState(() => _autoloadPreset = presetName);
  }

  Future<void> _deletePreset(DDCPreset preset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Preset'),
        content: Text('Are you sure you want to delete "${preset.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PresetService.instance.deletePreset(preset.name);
      await _loadPresets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.bookmark, color: Color(0xFF2c3e50)),
              const SizedBox(width: 8),
              Text(
                'Connection Presets',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF2c3e50),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Save Current Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onSavePreset();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.add),
              label: const Text('Save Current Configuration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Presets List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _presets.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _presets.length,
                        itemBuilder: (context, index) {
                          final preset = _presets[index];
                          final isAutoload = preset.name == _autoloadPreset;
                          final isCurrent = widget.currentPreset?.name == preset.name;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: preset.protocol == 'https' 
                                    ? Colors.green 
                                    : Colors.orange,
                                child: Text(
                                  preset.protocol.toUpperCase()[0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                preset.name,
                                style: TextStyle(
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  color: isCurrent ? Theme.of(context).primaryColor : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${preset.protocol}://${preset.ip}'),
                                  Text(
                                    '${preset.resolution} • ${_formatDate(preset.createdAt)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isAutoload)
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'connect':
                                          widget.onPresetSelected(preset);
                                          Navigator.of(context).pop();
                                          break;
                                        case 'autoload':
                                          _setAutoloadPreset(isAutoload ? null : preset.name);
                                          break;
                                        case 'delete':
                                          _deletePreset(preset);
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'connect',
                                        child: Row(
                                          children: [
                                            Icon(Icons.link),
                                            SizedBox(width: 8),
                                            Text('Connect'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'autoload',
                                        child: Row(
                                          children: [
                                            Icon(isAutoload ? Icons.star : Icons.star_border),
                                            const SizedBox(width: 8),
                                            Text(isAutoload ? 'Remove Autoload' : 'Set as Autoload'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () {
                                widget.onPresetSelected(preset);
                                Navigator.of(context).pop();
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Presets Saved',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save your DDC4000 connection settings\nfor quick access later',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              widget.onSavePreset();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.add),
            label: const Text('Save Current Configuration'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}