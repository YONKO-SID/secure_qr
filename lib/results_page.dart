import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResultsPage extends StatefulWidget {
  final String scannedUrl;

  const ResultsPage({super.key, required this.scannedUrl});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool isLoading = true;
  Map<String, dynamic>? result;
  String? error;

  @override
  void initState() {
    super.initState();
    checkURL();
  }

  Future<void> checkURL() async {
    try {
      // TODO: Replace with your Firebase Cloud Function URL
      final response = await http.post(
        Uri.parse('YOUR_FIREBASE_FUNCTION_URL/checkUrl'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'url': widget.scannedUrl}),
      );

      if (response.statusCode == 200) {
        setState(() {
          result = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to check URL';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error: $e';
        isLoading = false;
      });
    }
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              )
            : _buildResults(),
      ),
    );
  }

  Widget _buildResults() {
    final isSafe = result?['status'] == 'safe';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSafe ? Icons.check_circle : Icons.warning,
          size: 100,
          color: isSafe ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 20),
        Text(
          isSafe ? 'Safe URL' : 'Unsafe URL Detected!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isSafe ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            widget.scannedUrl,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 30),
        if (isSafe)
          ElevatedButton(
            onPressed: () {
              // TODO: Open URL in safe in-app browser
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text('Open URL'),
          ),
        if (!isSafe)
          const Text(
            'This URL has been blocked for your safety.',
            style: TextStyle(color: Colors.red),
          ),
      ],
    );
  }
}
