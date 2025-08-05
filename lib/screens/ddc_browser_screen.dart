import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../models/ddc_preset.dart';
import '../services/preset_service.dart';
import '../services/screenshot_service.dart';
import '../widgets/connection_settings_widget.dart';
import '../widgets/preset_selector_widget.dart';
import '../widgets/screenshot_gallery_widget.dart';

class DDCBrowserScreen extends StatefulWidget {
  const DDCBrowserScreen({super.key});

  @override
  State<DDCBrowserScreen> createState() => _DDCBrowserScreenState();
}

class _DDCBrowserScreenState extends State<DDCBrowserScreen> with WidgetsBindingObserver {
  late WebViewController _webViewController;
  final ScreenshotController _screenshotController = ScreenshotController();
  
  // Connection state
  String _protocol = 'http';
  String _ipAddress = '';
  String _resolution = 'WVGA';
  bool _isLoading = false;
  bool _isConnected = false;
  String _statusMessage = 'Not Connected';
  
  // UI state
  DDCPreset? _currentPreset;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWebView();
    _loadAutoPreset();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (useful for managing connections)
    if (state == AppLifecycleState.resumed && _isConnected) {
      // Refresh connection when app comes back from background
      _refreshConnection();
    }
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _statusMessage = 'Connecting...';
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
              _isConnected = true;
              _statusMessage = 'Connected';
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
              _isConnected = false;
              _statusMessage = 'Connection Failed: ${error.description}';
            });
            _showErrorToast('Failed to load DDC4000 interface: ${error.description}');
          },
        ),
      );
  }

  Future<void> _loadAutoPreset() async {
    final autoPresetName = await PresetService.instance.getAutoloadPreset();
    if (autoPresetName != null) {
      final preset = await PresetService.instance.getPresetByName(autoPresetName);
      if (preset != null) {
        _loadPreset(preset);
      }
    }
  }

  void _loadPreset(DDCPreset preset) {
    setState(() {
      _protocol = preset.protocol;
      _ipAddress = preset.ip;
      _resolution = preset.resolution;
      _currentPreset = preset;
    });
    
    _connectToDDC();
    PresetService.instance.updateLastUsed(preset.name);
  }

  void _connectToDDC() {
    if (_ipAddress.isEmpty) {
      _showErrorToast('Please enter an IP address');
      return;
    }

    final url = _buildDDCUrl();
    print('DDC URL: $url'); // Debug logging
    _webViewController.loadRequest(Uri.parse(url));
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting to DDC4000...';
    });
  }

  String _buildDDCUrl() {
    if (_resolution == 'QVGA') {
      return '$_protocol://$_ipAddress/ddcdialog.html?useOvl=1&busyReload=1&type=$_resolution&x=0&y=0&fit=1';
    } else {
      return '$_protocol://$_ipAddress/ddcdialog.html?useOvl=1&busyReload=1&type=$_resolution';
    }
  }

  void _refreshConnection() {
    if (_ipAddress.isNotEmpty) {
      _connectToDDC();
    }
  }

  Future<void> _takeScreenshot() async {
    try {
      // Request permissions first
      final hasPermission = await ScreenshotService.instance.requestPermissions();
      if (!hasPermission) {
        _showErrorToast('Storage permission required for screenshots');
        return;
      }

      // Show loading state
      _showSuccessToast('Capturing screenshot...');

      final screenshotData = await ScreenshotService.instance.takeScreenshot(
        controller: _screenshotController,
        ddcUrl: _isConnected ? _buildDDCUrl() : null,
        deviceIp: _ipAddress.isNotEmpty ? _ipAddress : null,
        resolution: _resolution,
      );

      if (screenshotData != null) {
        _showSuccessToast('Screenshot saved to gallery');
      } else {
        _showErrorToast('Failed to capture screenshot');
      }
    } catch (e) {
      _showErrorToast('Screenshot error: ${e.toString()}');
      print('Screenshot error details: $e');
    }
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          minHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: ConnectionSettingsWidget(
          protocol: _protocol,
          ipAddress: _ipAddress,
          resolution: _resolution,
          onSettingsChanged: (protocol, ip, resolution) {
            setState(() {
              _protocol = protocol;
              _ipAddress = ip;
              _resolution = resolution;
              _currentPreset = null; // Clear current preset when manually changed
            });
          },
          onConnect: _connectToDDC,
          ),
        ),
      ),
    );
  }

  void _showPresetSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: PresetSelectorWidget(
          currentPreset: _currentPreset,
          onPresetSelected: _loadPreset,
          onSavePreset: () => _saveCurrentAsPreset(),
        ),
      ),
    );
  }

  void _saveCurrentAsPreset() {
    if (_ipAddress.isEmpty) {
      _showErrorToast('Please configure connection settings first');
      return;
    }

    _showSavePresetDialog();
  }

  void _showSavePresetDialog() {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Preset Name',
                hintText: 'Enter a name for this preset',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Connection: $_protocol://$_ipAddress ($_resolution)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final preset = DDCPreset(
                  name: name,
                  protocol: _protocol,
                  ip: _ipAddress,
                  resolution: _resolution,
                  createdAt: DateTime.now(),
                );
                
                await PresetService.instance.savePreset(preset);
                _showSuccessToast('Preset saved successfully');
                
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showScreenshotGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ScreenshotGalleryScreen(),
      ),
    );
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.home_work, size: 24),
            SizedBox(width: 8),
            Text('DDC4000 Browser'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshConnection,
            tooltip: 'Refresh Connection',
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: _showPresetSelector,
            tooltip: 'Presets',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: 'Connection Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _isConnected ? Colors.green : (_isLoading ? Colors.orange : Colors.red),
              child: Row(
                children: [
                  Icon(
                    _isConnected ? Icons.wifi : (_isLoading ? Icons.wifi_protected_setup : Icons.wifi_off),
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const Spacer(),
                  if (_ipAddress.isNotEmpty) ...[
                    Text(
                      '$_protocol://$_ipAddress ($_resolution)',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            // WebView
            Expanded(
              child: Screenshot(
                controller: _screenshotController,
                child: _ipAddress.isEmpty
                    ? _buildWelcomeScreen()
                    : WebViewWidget(controller: _webViewController),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Theme.of(context).primaryColor,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.camera_alt),
            label: 'Screenshot',
            onTap: _takeScreenshot,
          ),
          SpeedDialChild(
            child: const Icon(Icons.photo_library),
            label: 'Gallery',
            onTap: _showScreenshotGallery,
          ),
          SpeedDialChild(
            child: const Icon(Icons.settings),
            label: 'Settings',
            onTap: _showSettingsDialog,
          ),
          SpeedDialChild(
            child: const Icon(Icons.bookmark),
            label: 'Presets',
            onTap: _showPresetSelector,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work,
              size: 120,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'DDC4000 Browser',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Professional building automation interface browser',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showSettingsDialog,
              icon: const Icon(Icons.settings),
              label: const Text('Configure Connection'),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _showPresetSelector,
              icon: const Icon(Icons.bookmark_border),
              label: const Text('Load Preset'),
            ),
          ],
        ),
      ),
    );
  }
}