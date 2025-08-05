import 'package:json_annotation/json_annotation.dart';

part 'ddc_preset.g.dart';

@JsonSerializable()
class DDCPreset {
  final String name;
  final String protocol;
  final String ip;
  final String resolution;
  final DateTime createdAt;
  final DateTime? lastUsed;

  const DDCPreset({
    required this.name,
    required this.protocol,
    required this.ip,
    required this.resolution,
    required this.createdAt,
    this.lastUsed,
  });

  String get url {
    if (resolution == 'QVGA') {
      return '$protocol://$ip/ddcdialog.html?useOvl=1&busyReload=1&type=$resolution&x=0&y=0&fit=1';
    } else {
      return '$protocol://$ip/ddcdialog.html?useOvl=1&busyReload=1&type=$resolution';
    }
  }

  String get displayName => '$name ($protocol://$ip)';

  DDCPreset copyWith({
    String? name,
    String? protocol,
    String? ip,
    String? resolution,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return DDCPreset(
      name: name ?? this.name,
      protocol: protocol ?? this.protocol,
      ip: ip ?? this.ip,
      resolution: resolution ?? this.resolution,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  factory DDCPreset.fromJson(Map<String, dynamic> json) => _$DDCPresetFromJson(json);
  Map<String, dynamic> toJson() => _$DDCPresetToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DDCPreset &&
        other.name == name &&
        other.protocol == protocol &&
        other.ip == ip &&
        other.resolution == resolution;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        protocol.hashCode ^
        ip.hashCode ^
        resolution.hashCode;
  }

  @override
  String toString() {
    return 'DDCPreset(name: $name, protocol: $protocol, ip: $ip, resolution: $resolution)';
  }
}