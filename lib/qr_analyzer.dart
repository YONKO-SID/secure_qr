import 'dart:async';

enum QRType { url, upi, text, contact, wifi }
enum RiskLevel { low, medium, high }

class ScanResult {
  final String content;
  final QRType type;
  final RiskLevel riskLevel;
  final DateTime timestamp;
  final String? threatType;
  final String? finalUrl;

  ScanResult({
    required this.content,
    required this.type,
    required this.riskLevel,
    required this.timestamp,
    this.threatType,
    this.finalUrl,
  });
}

class QRAnalyzer {
  static final List<String> _phishingPatterns = [
    'bit.ly', 'tinyurl.com', 'cutt.ly', 'tiny.cc', 'ow.ly', 'short.link',
    r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}', // Raw IPs
    'login', 'verify', 'urgent', 'suspended', 'account', 'security',
    'update', 'confirm', 'validate', 'authenticate', 'unlock'
  ];

  static final List<String> _suspiciousKeywords = [
    'free', 'winner', 'congratulations', 'prize', 'lottery',
    'urgent', 'immediate', 'expire', 'suspend', 'verify',
    'click', 'download', 'install', 'update'
  ];

  Future<ScanResult> analyze(String content) async {
    final type = _detectType(content);
    final risk = await _assessRisk(content, type);
    
    return ScanResult(
      content: content,
      type: type,
      riskLevel: risk.level,
      timestamp: DateTime.now(),
      threatType: risk.threatType,
      finalUrl: risk.finalUrl,
    );
  }

  QRType _detectType(String content) {
    if (content.startsWith('upi://')) return QRType.upi;
    if (content.startsWith('WIFI:')) return QRType.wifi;
    if (content.startsWith('BEGIN:VCARD')) return QRType.contact;
    
    final uri = Uri.tryParse(content);
    if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
      return QRType.url;
    }
    
    return QRType.text;
  }

  Future<({RiskLevel level, String? threatType, String? finalUrl})> _assessRisk(String content, QRType type) async {
    if (type == QRType.url) {
      return _assessUrlRisk(content);
    } else if (type == QRType.upi) {
      return _assessUPIRisk(content);
    }
    
    return (level: RiskLevel.low, threatType: null, finalUrl: null);
  }

  ({RiskLevel level, String? threatType, String? finalUrl}) _assessUrlRisk(String url) {
    // Check for URL shorteners
    for (final pattern in _phishingPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(url)) {
        return (level: RiskLevel.high, threatType: 'URL_SHORTENER', finalUrl: url);
      }
    }

    // Check for suspicious keywords
    int suspiciousCount = 0;
    for (final keyword in _suspiciousKeywords) {
      if (url.toLowerCase().contains(keyword)) {
        suspiciousCount++;
      }
    }

    if (suspiciousCount >= 2) {
      return (level: RiskLevel.medium, threatType: 'SUSPICIOUS_KEYWORDS', finalUrl: url);
    }

    // Check for IP addresses instead of domains
    if (RegExp(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').hasMatch(url)) {
      return (level: RiskLevel.high, threatType: 'IP_ADDRESS', finalUrl: url);
    }

    // Check for missing HTTPS
    if (!url.startsWith('https://')) {
      return (level: RiskLevel.medium, threatType: 'NO_HTTPS', finalUrl: url);
    }

    return (level: RiskLevel.low, threatType: null, finalUrl: url);
  }

  ({RiskLevel level, String? threatType, String? finalUrl}) _assessUPIRisk(String upi) {
    // Basic UPI validation
    if (!upi.contains('@')) {
      return (level: RiskLevel.high, threatType: 'INVALID_UPI', finalUrl: upi);
    }

    // Check for suspicious UPI patterns
    if (RegExp(r'\d{10,}').hasMatch(upi)) {
      return (level: RiskLevel.medium, threatType: 'NUMERIC_UPI', finalUrl: upi);
    }

    return (level: RiskLevel.low, threatType: null, finalUrl: upi);
  }

  // Quick check for immediate warnings
  String quickCheck(String url) {
    final result = _assessUrlRisk(url);
    
    if (result.level == RiskLevel.high) return 'HIGH';
    if (result.level == RiskLevel.medium) return 'MEDIUM';
    return 'LOW';
  }
}