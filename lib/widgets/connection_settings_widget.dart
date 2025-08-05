import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionSettingsWidget extends StatefulWidget {
  final String protocol;
  final String ipAddress;
  final String resolution;
  final Function(String protocol, String ip, String resolution) onSettingsChanged;
  final VoidCallback onConnect;

  const ConnectionSettingsWidget({
    super.key,
    required this.protocol,
    required this.ipAddress,
    required this.resolution,
    required this.onSettingsChanged,
    required this.onConnect,
  });

  @override
  State<ConnectionSettingsWidget> createState() => _ConnectionSettingsWidgetState();
}

class _ConnectionSettingsWidgetState extends State<ConnectionSettingsWidget> {
  late TextEditingController _ipController;
  late String _selectedProtocol;
  late String _selectedResolution;
  bool _autoLoad = false;

  final List<String> _protocols = ['http', 'https'];
  final List<String> _resolutions = ['QVGA', 'WVGA'];
  final List<String> _commonIPs = [
    '192.168.1.1',
    '192.168.0.1', 
    '192.168.10.21',
    '10.0.0.1',
    '172.16.0.1',
    '127.0.0.1',
  ];

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.ipAddress);
    _selectedProtocol = widget.protocol;
    _selectedResolution = widget.resolution;
    _loadAutoLoadSettings();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _updateSettings() {
    widget.onSettingsChanged(
      _selectedProtocol,
      _ipController.text.trim(),
      _selectedResolution,
    );
  }

  void _onConnectPressed() {
    _updateSettings();
    widget.onConnect();
    Navigator.of(context).pop();
  }

  Future<void> _loadAutoLoadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoLoad = prefs.getBool('simple_auto_load') ?? false;
      setState(() => _autoLoad = autoLoad);
      print('📱 Loaded auto-load setting: $autoLoad');
    } catch (e) {
      print('❌ Error loading auto-load settings: $e');
    }
  }

  Future<void> _saveAutoLoadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_autoLoad) {
        // Save current connection settings for auto-load
        await prefs.setBool('simple_auto_load', true);
        await prefs.setString('auto_protocol', _selectedProtocol);
        await prefs.setString('auto_ip', _ipController.text.trim());
        await prefs.setString('auto_resolution', _selectedResolution);
        print('💾 Saved auto-load settings: $_selectedProtocol://${_ipController.text.trim()} ($_selectedResolution)');
      } else {
        // Clear auto-load settings
        await prefs.setBool('simple_auto_load', false);
        await prefs.remove('auto_protocol');
        await prefs.remove('auto_ip');
        await prefs.remove('auto_resolution');
        print('🗑️ Cleared auto-load settings');
      }
    } catch (e) {
      print('❌ Error saving auto-load settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.settings, color: Color(0xFF2c3e50)),
              const SizedBox(width: 8),
              Text(
                'Connection Settings',
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
          const SizedBox(height: 24),

          // Protocol Selection
          Text(
            'Protocol',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _protocols.map((protocol) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: protocol == _protocols.last ? 0 : 8),
                child: ChoiceChip(
                  label: Text(protocol.toUpperCase()),
                  selected: _selectedProtocol == protocol,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedProtocol = protocol;
                      });
                    }
                  },
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),

          // IP Address Input
          Text(
            'IP Address',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              hintText: '192.168.10.21',
              prefixIcon: Icon(Icons.router),
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => _updateSettings(),
          ),
          const SizedBox(height: 12),

          // Common IP Suggestions
          Text(
            'Common IPs',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _commonIPs.map((ip) => GestureDetector(
              onTap: () {
                _ipController.text = ip;
                _updateSettings();
              },
              child: Chip(
                label: Text(
                  ip,
                  style: const TextStyle(fontSize: 12),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),

          // Resolution Selection
          Text(
            'Resolution',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('QVGA (320×240)'),
                  selected: _selectedResolution == 'QVGA',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedResolution = 'QVGA';
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('WVGA (800×480)'),
                  selected: _selectedResolution == 'WVGA',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedResolution = 'WVGA';
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Connection Info',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'URL: ${_selectedProtocol}://${_ipController.text.trim().isEmpty ? '[IP]' : _ipController.text.trim()}/ddcdialog.html',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Resolution: $_selectedResolution (${_selectedResolution == 'QVGA' ? '320×240' : '800×480'})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Auto-Load Toggle
          Row(
            children: [
              Checkbox(
                value: _autoLoad,
                onChanged: (value) {
                  setState(() => _autoLoad = value ?? false);
                  _saveAutoLoadSettings();
                },
              ),
              Expanded(
                child: Text(
                  'Auto-connect on app startup',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Connect Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _ipController.text.trim().isNotEmpty ? _onConnectPressed : null,
              icon: const Icon(Icons.link),
              label: const Text('Connect to DDC4000'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}