import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenshot/screenshot.dart';
import '../models/screenshot_data.dart';

class ScreenshotService {
  static const String _screenshotsKey = 'ddc_screenshots';

  static ScreenshotService? _instance;
  static ScreenshotService get instance => _instance ??= ScreenshotService._();
  ScreenshotService._();

  SharedPreferences? _prefs;
  Directory? _screenshotsDir;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _initScreenshotsDirectory();
  }

  Future<void> _initScreenshotsDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    _screenshotsDir = Directory('${appDir.path}/screenshots');
    
    if (!await _screenshotsDir!.exists()) {
      await _screenshotsDir!.create(recursive: true);
    }
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we need photos permission instead of storage
      final status = await Permission.photos.request();
      if (status.isDenied) {
        // Fallback to storage permission for older Android versions
        final storageStatus = await Permission.storage.request();
        return storageStatus.isGranted;
      }
      return status.isGranted;
    }
    return true; // iOS doesn't need explicit permission for saving to Photos
  }

  Future<ScreenshotData?> takeScreenshot({
    required ScreenshotController controller,
    String? ddcUrl,
    String? deviceIp,
    String? resolution,
  }) async {
    try {
      await init();
      
      final imageBytes = await controller.capture();
      if (imageBytes == null) return null;

      // Generate unique filename
      final timestamp = DateTime.now();
      final fileName = 'ddc_screenshot_${timestamp.millisecondsSinceEpoch}.png';
      final filePath = '${_screenshotsDir!.path}/$fileName';

      // Save to app directory
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Save to device gallery with permission
      if (await requestPermissions()) {
        await Gal.putImageBytes(imageBytes);
      }

      // Get image dimensions (simple approach - you might want to use image package for better parsing)
      final width = 800; // Default, could be calculated from imageBytes
      final height = 480; // Default, could be calculated from imageBytes

      final screenshotData = ScreenshotData(
        id: timestamp.millisecondsSinceEpoch.toString(),
        fileName: fileName,
        filePath: filePath,
        ddcUrl: ddcUrl,
        deviceIp: deviceIp,
        resolution: resolution,
        capturedAt: timestamp,
        fileSize: imageBytes.length,
        width: width,
        height: height,
      );

      await _saveScreenshotMetadata(screenshotData);
      return screenshotData;
    } catch (e) {
      print('Error taking screenshot: $e');
      return null;
    }
  }

  Future<List<ScreenshotData>> getAllScreenshots() async {
    await init();
    final screenshotsJson = _prefs!.getStringList(_screenshotsKey) ?? [];
    
    final screenshots = screenshotsJson
        .map((json) => ScreenshotData.fromJson(jsonDecode(json)))
        .toList();

    // Sort by capture date (newest first)
    screenshots.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    
    // Filter out screenshots whose files no longer exist
    final validScreenshots = <ScreenshotData>[];
    for (final screenshot in screenshots) {
      if (await File(screenshot.filePath).exists()) {
        validScreenshots.add(screenshot);
      }
    }

    // Update the list if any files were missing
    if (validScreenshots.length != screenshots.length) {
      await _saveAllScreenshots(validScreenshots);
    }

    return validScreenshots;
  }

  Future<void> deleteScreenshot(String id) async {
    await init();
    final screenshots = await getAllScreenshots();
    final screenshot = screenshots.where((s) => s.id == id).firstOrNull;
    
    if (screenshot != null) {
      // Delete file
      final file = File(screenshot.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Remove from metadata
      screenshots.removeWhere((s) => s.id == id);
      await _saveAllScreenshots(screenshots);
    }
  }

  Future<void> clearAllScreenshots() async {
    await init();
    final screenshots = await getAllScreenshots();
    
    // Delete all files
    for (final screenshot in screenshots) {
      final file = File(screenshot.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    // Clear metadata
    await _prefs!.remove(_screenshotsKey);
  }

  Future<Uint8List?> getScreenshotBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      print('Error reading screenshot file: $e');
    }
    return null;
  }

  Future<void> _saveScreenshotMetadata(ScreenshotData screenshot) async {
    final screenshots = await getAllScreenshots();
    screenshots.insert(0, screenshot);
    
    // Keep only last 100 screenshots
    if (screenshots.length > 100) {
      // Delete old files
      for (int i = 100; i < screenshots.length; i++) {
        final file = File(screenshots[i].filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      screenshots.removeRange(100, screenshots.length);
    }
    
    await _saveAllScreenshots(screenshots);
  }

  Future<void> _saveAllScreenshots(List<ScreenshotData> screenshots) async {
    final screenshotsJson = screenshots
        .map((screenshot) => jsonEncode(screenshot.toJson()))
        .toList();
    
    await _prefs!.setStringList(_screenshotsKey, screenshotsJson);
  }
}