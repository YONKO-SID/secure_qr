import 'package:hive_flutter/hive_flutter.dart';

enum QRType {
  url,
  text,
  wifi,
  email,
  phone,
  sms,
  location,
  contact,
  calendar,
  unknown,
}

enum RiskLevel {
  low,
  medium,
  high,
}

@HiveType(typeId: 1)
class ScanResult {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String content;
  
  @HiveField(2)
  final QRType type;
  
  @HiveField(3)
  final RiskLevel riskLevel;
  
  @HiveField(4)
  final List<String> threats;
  
  @HiveField(5)
  final DateTime timestamp;
  
  @HiveField(6)
  final String? analysis;

  ScanResult({
    required this.id,
    required this.content,
    required this.type,
    required this.riskLevel,
    required this.threats,
    required this.timestamp,
    this.analysis,
  });

  ScanResult copyWith({
    String? id,
    String? content,
    QRType? type,
    RiskLevel? riskLevel,
    List<String>? threats,
    DateTime? timestamp,
    String? analysis,
  }) {
    return ScanResult(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      riskLevel: riskLevel ?? this.riskLevel,
      threats: threats ?? this.threats,
      timestamp: timestamp ?? this.timestamp,
      analysis: analysis ?? this.analysis,
    );
  }
}