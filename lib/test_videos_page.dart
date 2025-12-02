import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/data/repositories/videos_repository_impl.dart';

class TestVideosPage extends StatefulWidget {
  const TestVideosPage({super.key});

  @override
  State<TestVideosPage> createState() => _TestVideosPageState();
}

class _TestVideosPageState extends State<TestVideosPage> {
  final TextEditingController _controller = TextEditingController(text: 'flutter tutorial');
  String _output = 'Ready to test...';
  bool _isLoading = false;

  Future<void> _runTest() async {
    setState(() {
      _isLoading = true;
      _output = 'Testing...';
    });

    try {
      final videosRepo = sl<VideosRepository>();
      final buffer = StringBuffer();

      // Test 1: Search for videos
      buffer.writeln('=== Test 1: Search Videos ===');
      final results = await videosRepo.search('youtube', _controller.text);
      buffer.writeln('✓ Found ${results.items.items.length} results');
      
      if (results.items.items.isNotEmpty) {
        final firstItem = results.items.items.first;
        buffer.writeln('First result type: ${firstItem.type}');
        if (firstItem.data is StreamSummaryModel) {
          final stream = firstItem.data as StreamSummaryModel;
          buffer.writeln('First video: ${stream.name}');
          buffer.writeln('Channel: ${stream.uploader?.name}');
        }
      }
      buffer.writeln('');

      // Test 2: Load more results (if available)
      if (results.items.nextPageToken != null) {
        buffer.writeln('=== Test 2: Load More ===');
        final moreItems = await videosRepo.loadMore(results.items.nextPageToken!);
        buffer.writeln('✓ Loaded ${moreItems.items.length} more items');
        buffer.writeln('');
      }

      // Test 3: Get stream info (if we have a URL)
      if (results.items.items.isNotEmpty) {
        final firstItem = results.items.items.first;
        if (firstItem.data is StreamSummaryModel) {
          final stream = firstItem.data as StreamSummaryModel;
          if (stream.url != null) {
            buffer.writeln('=== Test 3: Get Stream Info ===');
            final streamInfo = await videosRepo.getStreamInfo(stream.url!);
            buffer.writeln('✓ Video title: ${streamInfo.name}');
            buffer.writeln('Duration: ${streamInfo.duration} seconds');
            buffer.writeln('Views: ${streamInfo.viewCount}');
            buffer.writeln('Likes: ${streamInfo.likeCount}');
            buffer.writeln('Video streams: ${streamInfo.videoStreams.length}');
            buffer.writeln('Audio streams: ${streamInfo.audioStreams.length}');
            buffer.writeln('');
          }
        }
      }

      // Test 4: Get search providers
      buffer.writeln('=== Test 4: Search Providers ===');
      final providers = await videosRepo.getSearchProviders();
      buffer.writeln('✓ Available providers: ${providers.join(", ")}');
      buffer.writeln('');

      buffer.writeln('✅ All tests passed!');
      
      setState(() {
        _output = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _output = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Videos Feature',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 24),
            
            // Search input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Search Query',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _runTest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Run Test'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Output
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _output,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
