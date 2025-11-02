import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultsPage extends StatefulWidget {
  final String scannedUrl;
  final Map<String, dynamic>? analysisResult;

  const ResultsPage({
    super.key, 
    required this.scannedUrl,
    this.analysisResult,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool isLoading = false;

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch URL')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // No need to make another API call - data comes from camera page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Results'),
        backgroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Security header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Powered by Google Safe Browsing',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Results content
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final result = widget.analysisResult;
    final verdict = result?['verdict'] ?? 'WARNING';
    final finalUrl = result?['finalUrl'] ?? widget.scannedUrl;
    final threatTypes = result?['threatTypes'] ?? [];
    
    // Determine safety based on verdict
    final isSafe = verdict == 'SAFE';
    final isDangerous = verdict == 'DANGEROUS';
    final isWarning = verdict == 'WARNING';

    // Set colors and icons based on verdict
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (isSafe) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Safe URL';
    } else if (isDangerous) {
      statusColor = Colors.red;
      statusIcon = Icons.dangerous;
      statusText = 'Dangerous URL Detected!';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Warning - Proceed with Caution';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          statusIcon,
          size: 100,
          color: statusColor,
        ),
        const SizedBox(height: 20),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
        const SizedBox(height: 10),
        if (threatTypes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Threats detected: ${threatTypes.join(', ')}',
              style: TextStyle(
                color: statusColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Final URL:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              SelectableText(
                finalUrl,
                style: const TextStyle(fontSize: 14),
              ),
              if (finalUrl != widget.scannedUrl) ...[
                const SizedBox(height: 8),
                const Text(
                  'Original URL:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  widget.scannedUrl,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 30),
        if (isSafe)
          ElevatedButton.icon(
            onPressed: () => _launchUrl(finalUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open URL Safely'),
          )
        else if (isWarning)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _launchUrl(finalUrl),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.warning),
                label: const Text('Proceed Anyway'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
              ),
            ],
          )
        else if (isDangerous)
          Column(
            children: [
              const Text(
                'This URL has been blocked for your safety.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                icon: const Icon(Icons.block),
                label: const Text('Stay Safe - Go Back'),
              ),
            ],
          ),
      ],
    );
  }
}
