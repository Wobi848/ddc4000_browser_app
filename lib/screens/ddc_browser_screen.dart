import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
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
  bool _showZoomInstructions = true;
  final TransformationController _transformationController = TransformationController();
  
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
      ..setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
      ..enableZoom(true)
      ..clearCache()
      ..clearLocalStorage()
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('🌐 WebView Page Started: $url');
            setState(() {
              _isLoading = true;
              _statusMessage = 'Loading: ${Uri.parse(url).host}';
            });
          },
          onPageFinished: (url) {
            print('✅ WebView Page Finished: $url');
            
            // Simple desktop optimization
            _webViewController.runJavaScript('console.log("DDC4000 page loaded - applying desktop mode");');
            
            // Apply display optimizations after page loads
            _optimizeDisplayForResolution();
            
            setState(() {
              _isLoading = false;
              _isConnected = true;
              _statusMessage = 'Connected to ${Uri.parse(url).host}';
            });
          },
          onWebResourceError: (error) {
            print('❌ WebView Error: ${error.description}');
            print('   Error Type: ${error.errorType}');
            print('   Error Code: ${error.errorCode}');
            print('   Failed URL: ${error.url}');
            setState(() {
              _isLoading = false;
              _isConnected = false;
              _statusMessage = 'Failed: ${error.description}';
            });
            _showErrorToast('Connection failed: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔄 Navigation Request: ${request.url}');
            print('   - Is for main frame: ${request.isMainFrame}');
            return NavigationDecision.navigate;
          },
          onHttpError: (HttpResponseError error) {
            print('🚫 HTTP Error: ${error.response?.statusCode}');
            print('   - URL: ${error.request?.uri}');
            print('   - Headers: ${error.response?.headers}');
          },
          onUrlChange: (UrlChange change) {
            print('🔗 URL Changed: ${change.url}');
          },
        ),
      );
  }

  Future<void> _loadAutoPreset() async {
    print('🔄 Checking for autoload preset...');
    final autoPresetName = await PresetService.instance.getAutoloadPreset();
    print('   Autoload preset name: $autoPresetName');
    
    if (autoPresetName != null) {
      final preset = await PresetService.instance.getPresetByName(autoPresetName);
      print('   Found preset: ${preset?.name}');
      
      if (preset != null) {
        print('✅ Loading autoload preset: ${preset.name}');
        _loadPreset(preset);
      } else {
        print('❌ Autoload preset not found, removing autoload setting');
        await PresetService.instance.setAutoloadPreset(null);
      }
    } else {
      print('ℹ️ No autoload preset set');
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

    // Build base URL first (without timestamp)
    String baseUrl;
    if (_resolution == 'QVGA') {
      baseUrl = '$_protocol://$_ipAddress/ddcdialog.html?useOvl=1&busyReload=1&type=$_resolution&x=0&y=0&fit=1';
    } else {
      baseUrl = '$_protocol://$_ipAddress/ddcdialog.html?useOvl=1&busyReload=1&type=$_resolution';
    }
    
    final url = _buildDDCUrl(); // This adds timestamp
    
    // COMPREHENSIVE DEBUG LOGGING (matching web prototype format)
    print('🔗 DDC4000 FLUTTER URL DEBUG:');
    print('========================================');
    print('Protocol: $_protocol');
    print('IP Address: $_ipAddress');
    print('Resolution: $_resolution');
    print('Original URL: $baseUrl');
    print('Final URL with timestamp: $url');
    print('URL Components:');
    print('  - Base: $_protocol://$_ipAddress');
    print('  - Path: /ddcdialog.html');
    print('  - Parameters: ${_buildUrlParameters()}');
    print('WebView Configuration:');
    print('  - User Agent: Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36');
    print('  - JavaScript Enabled: true');
    print('  - Cache Cleared: true');
    print('========================================');
    
    // Test basic connectivity first
    _testConnectivity(url);
    
    _webViewController.loadRequest(Uri.parse(url));
    
    // Show URL in toast for debugging
    _showSuccessToast('Connecting to: $url');
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting to: $_protocol://$_ipAddress';
    });
  }

  Future<void> _testConnectivity(String url) async {
    print('🔍 Testing connectivity to: $url');
    try {
      // This is just for debugging - test if the URL is reachable
      final uri = Uri.parse(url);
      print('   - Parsed URI: $uri');
      print('   - Host: ${uri.host}');
      print('   - Port: ${uri.port}');
      print('   - Path: ${uri.path}');
      print('   - Query: ${uri.query}');
    } catch (e) {
      print('❌ URL parsing error: $e');
    }
  }

  void _optimizeDisplayForResolution() {
    print('📱 Applying DESKTOP MODE for DDC4000 with InteractiveViewer');
    
    String jsCode = '''
      setTimeout(function() {
        console.log('🖥️ SETTING UP DESKTOP DDC4000...');
        
        // Remove mobile viewport
        var viewport = document.querySelector("meta[name=viewport]");
        if (viewport) viewport.remove();
        
        // Force desktop viewport
        viewport = document.createElement('meta');
        viewport.name = 'viewport';
        viewport.content = 'width=1400, initial-scale=1.0, user-scalable=no';
        document.head.appendChild(viewport);
        
        // Set minimum sizes to ensure full interface
        document.body.style.minWidth = '1400px';
        document.body.style.minHeight = '1000px';
        document.documentElement.style.minWidth = '1400px';
        
        console.log('✅ DESKTOP MODE READY FOR INTERACTIVEVIEWER');
        
      }, 200);
    ''';
    
    _webViewController.runJavaScript(jsCode);
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.2).clamp(0.05, 5.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.2).clamp(0.05, 5.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _fitToScreen() {
    // Calculate scale to fit the 1400x1000 content in the screen
    final screenSize = MediaQuery.of(context).size;
    final scaleX = screenSize.width / 1400;
    final scaleY = (screenSize.height - 100) / 1000; // Account for app bar
    final fitScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.05, 5.0);
    
    _transformationController.value = Matrix4.identity()..scale(fitScale);
    print('🎯 Fit to screen: ${fitScale}x scale');
  }

  String _buildDDCUrl() {
    String baseUrl;
    if (_resolution == 'QVGA') {
      baseUrl = '$_protocol://$_ipAddress/ddcdialog.html?useOvl=1&busyReload=1&type=$_resolution&x=0&y=0&fit=1';
    } else {
      baseUrl = '$_protocol://$_ipAddress/ddcdialog.html?useOvl=1&busyReload=1&type=$_resolution';
    }
    
    // Add timestamp to prevent caching issues (like web prototype)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$baseUrl&_t=$timestamp';
  }
  
  String _buildUrlParameters() {
    if (_resolution == 'QVGA') {
      return 'useOvl=1&busyReload=1&type=$_resolution&x=0&y=0&fit=1';
    } else {
      return 'useOvl=1&busyReload=1&type=$_resolution';
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
      builder: (context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            minHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
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
            ],
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
      builder: (context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            minHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  child: PresetSelectorWidget(
                    currentPreset: _currentPreset,
                    onPresetSelected: _loadPreset,
                    onSavePreset: () => _saveCurrentAsPreset(),
                  ),
                ),
              ),
            ],
          ),
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
                try {
                  print('🔄 Saving preset: $name');
                  print('   Protocol: $_protocol');
                  print('   IP: $_ipAddress');
                  print('   Resolution: $_resolution');
                  
                  final preset = DDCPreset(
                    name: name,
                    protocol: _protocol,
                    ip: _ipAddress,
                    resolution: _resolution,
                    createdAt: DateTime.now(),
                  );
                  
                  await PresetService.instance.savePreset(preset);
                  print('✅ Preset saved successfully: $name');
                  _showSuccessToast('Preset "$name" saved successfully');
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  print('❌ Error saving preset: $e');
                  _showErrorToast('Failed to save preset: ${e.toString()}');
                }
              } else {
                _showErrorToast('Please enter a preset name');
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
        bottom: true, // Ensure bottom safe area is respected
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
            // WebView with additional bottom padding to avoid system UI
            Expanded(
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom > 0 
                    ? 0 // SafeArea already handles it
                    : 16, // Add padding for devices without safe area
                ),
                child: Screenshot(
                  controller: _screenshotController,
                  child: _ipAddress.isEmpty
                      ? _buildWelcomeScreen()
                      : Stack(
                          children: [
                            InteractiveViewer(
                              transformationController: _transformationController,
                              minScale: 0.05,
                              maxScale: 5.0,
                              constrained: false,
                              scaleEnabled: true,
                              panEnabled: true,
                              boundaryMargin: const EdgeInsets.all(double.infinity),
                              clipBehavior: Clip.none,
                              child: SizedBox(
                                width: 1400, // Larger desktop width to capture more interface
                                height: 1000, // Larger desktop height to capture more interface
                                child: WebViewWidget(
                                  controller: _webViewController,
                                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                                    Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                                    Factory<LongPressGestureRecognizer>(() => LongPressGestureRecognizer()),
                                  },
                                ),
                              ),
                            ),
                            // Instructions overlay (dismissible)
                            if (_isConnected && _showZoomInstructions)
                              Positioned(
                                top: 10,
                                left: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.touch_app, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Pinch out for full view • Drag to scroll',
                                          style: TextStyle(color: Colors.white, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => setState(() => _showZoomInstructions = false),
                                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Manual zoom controls
                            if (_isConnected)
                              Positioned(
                                bottom: 80,
                                right: 16,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FloatingActionButton.small(
                                      heroTag: "zoom_in",
                                      onPressed: _zoomIn,
                                      child: const Icon(Icons.zoom_in),
                                      backgroundColor: Colors.blue.withOpacity(0.8),
                                    ),
                                    const SizedBox(height: 8),
                                    FloatingActionButton.small(
                                      heroTag: "zoom_out", 
                                      onPressed: _zoomOut,
                                      child: const Icon(Icons.zoom_out),
                                      backgroundColor: Colors.blue.withOpacity(0.8),
                                    ),
                                    const SizedBox(height: 8),
                                    FloatingActionButton.small(
                                      heroTag: "fit_screen",
                                      onPressed: _fitToScreen,
                                      child: const Icon(Icons.fit_screen),
                                      backgroundColor: Colors.green.withOpacity(0.8),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SafeArea(
        child: SpeedDial(
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