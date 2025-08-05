import 'package:json_annotation/json_annotation.dart';

part 'screenshot_data.g.dart';

@JsonSerializable()
class ScreenshotData {
  final String id;
  final String fileName;
  final String filePath;
  final String? ddcUrl;
  final String? deviceIp;
  final String? resolution;
  final DateTime capturedAt;
  final int fileSize;
  final int width;
  final int height;

  const ScreenshotData({
    required this.id,
    required this.fileName,
    required this.filePath,
    this.ddcUrl,
    this.deviceIp,
    this.resolution,
    required this.capturedAt,
    required this.fileSize,
    required this.width,
    required this.height,
  });

  String get displayName {
    if (deviceIp != null && resolution != null) {
      return '$deviceIp ($resolution)';
    } else if (deviceIp != null) {
      return deviceIp!;
    } else {
      return fileName;
    }
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  String get dimensionsText => '${width}×${height}';

  ScreenshotData copyWith({
    String? id,
    String? fileName,
    String? filePath,
    String? ddcUrl,
    String? deviceIp,
    String? resolution,
    DateTime? capturedAt,
    int? fileSize,
    int? width,
    int? height,
  }) {
    return ScreenshotData(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      ddcUrl: ddcUrl ?? this.ddcUrl,
      deviceIp: deviceIp ?? this.deviceIp,
      resolution: resolution ?? this.resolution,
      capturedAt: capturedAt ?? this.capturedAt,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  factory ScreenshotData.fromJson(Map<String, dynamic> json) => _$ScreenshotDataFromJson(json);
  Map<String, dynamic> toJson() => _$ScreenshotDataToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScreenshotData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ScreenshotData(id: $id, fileName: $fileName, deviceIp: $deviceIp, resolution: $resolution)';
  }
}