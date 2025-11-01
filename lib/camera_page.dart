import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:secure_qr/results_page.dart'; // Import the results page

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool _isLoading = false;

  Future<void> _analyzeUrl(String url) async {
    setState(() {
      _isLoading = true;
    });

    // This is the old backend URL. We will replace this with the Firebase function call later.
    final backendUrl = Uri.parse('http://10.0.2.2:3000/analyze');

    try {
      final response = await http.post(
        backendUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'url': url}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsPage(scannedUrl: result),
          ),
        );
      } else {
        // TODO: Show an error message to the user.
        debugPrint('Backend error: ${response.body}');
      }
    } catch (e) {
      // TODO: Show an error message to the user.
      debugPrint('Failed to connect to backend: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_isLoading) return;

              final Barcode barcode = capture.barcodes.first;
              final String? scannedValue = barcode.rawValue;

              if (scannedValue != null) {
                final uri = Uri.tryParse(scannedValue);
                bool isWebUrl =
                    uri != null &&
                    (uri.isScheme('http') || uri.isScheme('https'));

                if (isWebUrl) {
                  _analyzeUrl(scannedValue);
                } else {
                  // TODO: Display non-URL content to the user.
                  debugPrint('Scanned content is not a URL: $scannedValue');
                }
              }
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
