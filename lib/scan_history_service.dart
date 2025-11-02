import 'package:hive_flutter/hive_flutter.dart';
import 'scan_result.dart';

class ScanHistoryService {
  static const String _historyBoxName = 'scan_history';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ScanResultAdapter());
      Hive.registerAdapter(QRTypeAdapter());
      Hive.registerAdapter(RiskLevelAdapter());
    }
    
    await Hive.openBox<ScanResult>(_historyBoxName);
  }
  
  static Future<void> addScan(ScanResult scan) async {
    final box = Hive.box<ScanResult>(_historyBoxName);
    await box.add(scan);
  }
  
  static List<ScanResult> getScanHistory() {
    final box = Hive.box<ScanResult>(_historyBoxName);
    return box.values.toList().reversed.toList(); // Most recent first
  }
  
  static Future<void> clearHistory() async {
    final box = Hive.box<ScanResult>(_historyBoxName);
    await box.clear();
  }
  
  static Future<void> deleteScan(String id) async {
    final box = Hive.box<ScanResult>(_historyBoxName);
    final index = box.values.toList().indexWhere((scan) => scan.id == id);
    if (index != -1) {
      await box.deleteAt(index);
    }
  }
  
  static Future<String> exportHistory() async {
    final scans = getScanHistory();
    final exportData = scans.map((scan) => 
      '${scan.timestamp.toIso8601String()} - ${scan.content} - ${scan.riskLevel} - ${scan.threats.join(', ')}'
    ).join('\n');
    
    return exportData;
  }
}

class ScanResultAdapter extends TypeAdapter<ScanResult> {
  @override
  final int typeId = 1;
  
  @override
  ScanResult read(BinaryReader reader) {
    return ScanResult(
      id: reader.readString(),
      content: reader.readString(),
      type: QRType.values[reader.readInt()],
      riskLevel: RiskLevel.values[reader.readInt()],
      threats: List<String>.from(reader.readList()),
      timestamp: DateTime.parse(reader.readString()),
      analysis: reader.readString(),
    );
  }
  
  @override
  void write(BinaryWriter writer, ScanResult obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.content);
    writer.writeInt(obj.type.index);
    writer.writeInt(obj.riskLevel.index);
    writer.writeList(obj.threats);
    writer.writeString(obj.timestamp.toIso8601String());
    writer.writeString(obj.analysis ?? '');
  }
}

class QRTypeAdapter extends TypeAdapter<QRType> {
  @override
  final int typeId = 2;
  
  @override
  QRType read(BinaryReader reader) {
    return QRType.values[reader.readInt()];
  }
  
  @override
  void write(BinaryWriter writer, QRType obj) {
    writer.writeInt(obj.index);
  }
}

class RiskLevelAdapter extends TypeAdapter<RiskLevel> {
  @override
  final int typeId = 3;
  
  @override
  RiskLevel read(BinaryReader reader) {
    return RiskLevel.values[reader.readInt()];
  }
  
  @override
  void write(BinaryWriter writer, RiskLevel obj) {
    writer.writeInt(obj.index);
  }
}