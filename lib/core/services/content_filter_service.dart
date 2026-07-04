import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ContentFilterService {
  static const String _url =
      'https://khaledekramy-harmful-title-classifier-api.hf.space/predict';
  static const double _threshold = 0.65; // score 65.0 => 0.65

  /// Returns true if the query is harmful (score >= 0.65), false otherwise.
  Future<bool> isHarmful(String query) async {
    if (query.trim().isEmpty) return false;
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': query}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['score'] != null) {
          final doubleScore = double.tryParse(data['score'].toString()) ?? 0.0;
          return doubleScore >= _threshold;
        }
      }
      print(response.body);
    } catch (e) {
      print('⚠️ Error in ContentFilterService: $e');
    }
    return false;
  }

  /// Displays a premium alert dialog informing the user that their search query has been blocked.
  void showBlockedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.errorContainer.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.block_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Search Blocked',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your search query has been blocked because it contains content classified as harmful or inappropriate.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Dismiss',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
