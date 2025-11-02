import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibration/vibration.dart';
import 'package:secure_qr/results_page.dart';
import 'package:secure_qr/scanning_animations.dart';
import 'package:secure_qr/qr_analyzer.dart';
import 'package:secure_qr/scan_history_service.dart';
import 'package:secure_qr/history_page.dart';
import 'package:secure_qr/theme_service.dart';
import 'package:secure_qr/main.dart';
import 'package:secure_qr/scan_result.dart' as scan_result;

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool _isAnalyzing = false;
  bool _batchMode = false;
  final List<String> _scannedCodes = [];
  final MobileScannerController _controller = MobileScannerController();
  final QRAnalyzer _analyzer = QRAnalyzer();
  Rect? _scanWindow;
  double _currentZoom = 0.0;

  @override
  void initState() {
    super.initState();
    // Don't access MediaQuery here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateScanWindow();
  }

  void _calculateScanWindow() {
    final size = MediaQuery.of(context).size;
    final scanArea = size.width * 0.7;
    final scanWindow = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanArea,
      height: scanArea,
    );
    setState(() {
      _scanWindow = scanWindow;
    });
  }

  Future<void> _onBarcode(String value) async {
    if (_isAnalyzing) return;
    
    setState(() {
      _isAnalyzing = true;
    });

    // Stop camera for analysis
    await _controller.stop();

    // Haptic feedback
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }

    // Quick local check
    final risk = _analyzer.quickCheck(value);
    
    if (risk == 'HIGH' && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
          title: const Text('Suspicious QR Code'),
          content: Text('This QR contains patterns often used in phishing:\n\n$value'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('View Details'),
            ),
          ],
        ),
      );
      
      if (proceed != true) {
        setState(() {
          _isAnalyzing = false;
        });
        await _controller.start();
        return;
      }
    }

    if (_batchMode) {
      // Batch mode: collect multiple codes
      setState(() {
        _scannedCodes.add(value);
      });
      
      // Quick check for batch mode
      final quickResult = _analyzer.quickCheck(value);
      final historyScanResult = scan_result.ScanResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: value,
        type: scan_result.QRType.url,
        riskLevel: scan_result.RiskLevel.values[quickResult == 'HIGH' ? 2 : quickResult == 'MEDIUM' ? 1 : 0],
        threats: quickResult != 'LOW' ? ['Quick check: $quickResult'] : [],
        timestamp: DateTime.now(),
        analysis: 'Batch scan quick check',
      );
      await ScanHistoryService.addScan(historyScanResult);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanned ${_scannedCodes.length} codes'),
            action: SnackBarAction(
              label: 'View All',
              onPressed: () => _showBatchResults(),
            ),
          ),
        );
      }
      
      setState(() {
        _isAnalyzing = false;
      });
      await _controller.start();
      return;
    }

    // Normal flow: analyze and navigate to results
    try {
      final result = await _analyzer.analyze(value);
      
      // Save to history
       final historyScanResult = scan_result.ScanResult(
         id: DateTime.now().millisecondsSinceEpoch.toString(),
         content: value,
         type: scan_result.QRType.values[result.type.index],
         riskLevel: scan_result.RiskLevel.values[result.riskLevel.index],
         threats: result.threatType != null ? [result.threatType!] : [],
         timestamp: DateTime.now(),
         analysis: result.finalUrl,
       );
       await ScanHistoryService.addScan(historyScanResult);
      
      if (!mounted) return;
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsPage(
            scannedUrl: value,
            analysisResult: {
              'verdict': result.riskLevel == RiskLevel.low ? 'SAFE' : 
                        result.riskLevel == RiskLevel.high ? 'DANGEROUS' : 'WARNING',
              'finalUrl': result.finalUrl ?? value,
              'threatTypes': result.threatType != null ? [result.threatType] : [],
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to analyze QR: $e')),
      );
    }

    setState(() {
      _isAnalyzing = false;
    });
    
    if (mounted) await _controller.start();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    // Show loading overlay
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Analyzing image...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await _controller.analyzeImage(img.path);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No QR code found in image'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showBatchResults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batch Scan Results (${_scannedCodes.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _scannedCodes.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_scannedCodes[index]),
                leading: const Icon(Icons.qr_code),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResultsPage(scannedUrl: _scannedCodes[index]),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _scannedCodes.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Batch results cleared')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure QR Scanner'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: Icon(_batchMode ? Icons.layers : Icons.layers_outlined),
            onPressed: () {
              setState(() {
                _batchMode = !_batchMode;
                if (!_batchMode) {
                  _scannedCodes.clear();
                }
              });
            },
            tooltip: _batchMode ? 'Exit Batch Mode' : 'Enable Batch Mode',
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickFromGallery,
            tooltip: 'Pick from Gallery',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryPage(),
                ),
              );
            },
            tooltip: 'Scan History',
          ),
          IconButton(
            icon: Icon(ThemeService.isDarkTheme ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              final newTheme = !ThemeService.isDarkTheme;
              MyApp.setTheme(context, newTheme);
              setState(() {}); // Refresh the icon
            },
            tooltip: ThemeService.isDarkTheme ? 'Light Mode' : 'Dark Mode',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isAnalyzing) return;
              
              // Check if there are any barcodes before accessing first
              if (capture.barcodes.isNotEmpty) {
                final Barcode barcode = capture.barcodes.first;
                final String? scannedValue = barcode.rawValue;

                if (scannedValue != null) {
                  _onBarcode(scannedValue);
                }
              }
            },
          ),
          
          // Scanning overlay with hexagonal window
          if (_scanWindow != null) ...[
            // Corner indicators
            CustomPaint(
              painter: CornerIndicatorsPainter(
                window: _scanWindow!,
                color: const Color(0xFF11F3E5),
              ),
              size: Size.infinite,
            ),
            
            // Animated scanning line
            ScanLineAnimation(window: _scanWindow!),
          ],
          
          // Zoom controls (simplified version)
          Positioned(
            bottom: 100,
            left: 40,
            right: 40,
            child: Row(
              children: [
                const Icon(Icons.zoom_out, color: Colors.white70),
                Expanded(
                  child: Slider(
                    value: _currentZoom,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) {
                      setState(() {
                        _currentZoom = v;
                      });
                      // Note: zoom control requires mobile_scanner 6.0.0+
                      // For now, we'll just store the value
                    },
                    activeColor: const Color(0xFF11F3E5),
                  ),
                ),
                const Icon(Icons.zoom_in, color: Colors.white70),
              ],
            ),
          ),
          
          // Loading overlay
          if (_isAnalyzing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF11F3E5)),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing QR Code...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          
          // Batch mode indicator
          if (_batchMode)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF11F3E5).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Batch Mode: ${_scannedCodes.length}',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
