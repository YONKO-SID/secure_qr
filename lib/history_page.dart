import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'scan_history_service.dart';
import 'scan_result.dart';
import 'results_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Box<ScanResult> _historyBox;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeHistory();
  }

  Future<void> _initializeHistory() async {
    await ScanHistoryService.init();
    _historyBox = Hive.box<ScanResult>('scan_history');
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportHistory,
            tooltip: 'Export History',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showClearDialog,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<ScanResult>>(
        valueListenable: _historyBox.listenable(),
        builder: (context, box, _) {
          final scans = box.values.toList().reversed.toList();
          
          if (scans.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No scan history yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start scanning QR codes to see them here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scans.length,
            itemBuilder: (context, index) {
              final scan = scans[index];
              return _buildHistoryItem(scan, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(ScanResult scan, int index) {
    final color = scan.riskLevel == RiskLevel.low
        ? Colors.green
        : scan.riskLevel == RiskLevel.medium
            ? Colors.orange
            : Colors.red;
    final icon = scan.riskLevel == RiskLevel.low ? Icons.check_circle : Icons.warning;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openScanResult(scan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDisplayContent(scan.content),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scan.type.toString().split('.').last.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    onPressed: () => _shareScan(scan),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(scan.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      scan.riskLevel.toString().split('.').last,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (scan.threats.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Threats: ${scan.threats.join(', ')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayContent(String content) {
    if (content.length > 50) {
      return '${content.substring(0, 47)}...';
    }
    return content;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _openScanResult(ScanResult scan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsPage(scannedUrl: scan.content),
      ),
    );
  }

  void _shareScan(ScanResult scan) {
    final shareText = '''
QR Scan Result:
Content: ${scan.content}
Type: ${scan.type.toString().split('.').last}
Risk Level: ${scan.riskLevel.toString().split('.').last}
Timestamp: ${scan.timestamp.toString()}
${scan.threats.isNotEmpty ? 'Threats: ${scan.threats.join(', ')}' : ''}
    '''.trim();
    
    Share.share(shareText);
  }

  void _clearHistory() async {
    try {
      await ScanHistoryService.clearHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear history: $e')),
        );
      }
    }
  }

  void _exportHistory() async {
    try {
      final exportData = await ScanHistoryService.exportHistory();
      
      if (!mounted) return;
      
      // Share the exported data
      await Share.share(
        exportData,
        subject: 'QR Scan History',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all scan history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearHistory();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}