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

      // Test 1: Get search providers
      buffer.writeln('=== Test 1: Search Providers ===');
      final providers = await videosRepo.getSearchProviders();
      buffer.writeln('✓ Available providers: ${providers.join(", ")}');
      buffer.writeln('');

      // Test 2: Get filters for YouTube
      buffer.writeln('=== Test 2: Get Filters (YouTube) ===');
      try {
        final filters = await videosRepo.getFilters('youtube');
        buffer.writeln('✓ Available filters: ${filters.join(", ")}');
      } catch (e) {
        buffer.writeln('⚠ Filters not available: $e');
      }
      buffer.writeln('');

      // Test 3: Get sort options for YouTube
      buffer.writeln('=== Test 3: Get Sort Options (YouTube) ===');
      try {
        final sortOptions = await videosRepo.getSortOptions('youtube');
        buffer.writeln('✓ Available sort options: ${sortOptions.join(", ")}');
      } catch (e) {
        buffer.writeln('⚠ Sort options not available: $e');
      }
      buffer.writeln('');

      // Test 4: Single provider search (YouTube)
      buffer.writeln('=== Test 4: Single Provider Search (YouTube) ===');
      final singleResults = await videosRepo.search('youtube', _controller.text);
      buffer.writeln('✓ Found ${singleResults.items.items.length} results');
      if (singleResults.items.items.isNotEmpty) {
        final firstItem = singleResults.items.items.first;
        buffer.writeln('First result type: ${firstItem.type}');
        if (firstItem.data is StreamSummaryModel) {
          final stream = firstItem.data as StreamSummaryModel;
          buffer.writeln('First video: ${stream.name}');
          buffer.writeln('Channel: ${stream.uploader?.name}');
        }
      }
      buffer.writeln('');

      // Test 5: Multi-provider search (YouTube + SoundCloud)
      buffer.writeln('=== Test 5: Multi-Provider Search (YouTube + SoundCloud) ===');
      final multiResults = await videosRepo.searchMultipleProviders(
        ['youtube', 'soundcloud'],
        _controller.text,
      );
      buffer.writeln('✓ Found ${multiResults.items.items.length} combined results');
      buffer.writeln('Has more pages: ${multiResults.items.nextPageToken != null}');
      buffer.writeln('');

      // Test 6: Search with filters
      buffer.writeln('=== Test 6: Search with Filters ===');
      try {
        final filteredResults = await videosRepo.search(
          'YouTube',
          _controller.text,
          filters: ['videos'], // Only videos, not channels or playlists
        );
        buffer.writeln('✓ Found ${filteredResults.items.items.length} filtered results');
      } catch (e) {
        buffer.writeln('⚠ Filtered search failed: $e');
      }
      buffer.writeln('');

      // Test 7: Search with sort
      buffer.writeln('=== Test 7: Search with Sort ===');
      try {
        final sortedResults = await videosRepo.search(
          'YouTube',
          _controller.text,
          sortCriteria: 'upload_date', // Sort by upload date
        );
        buffer.writeln('✓ Found ${sortedResults.items.items.length} sorted results');
      } catch (e) {
        buffer.writeln('⚠ Sorted search failed: $e');
      }
      buffer.writeln('');

      // Test 8: Load more results (if available)
      if (singleResults.items.nextPageToken != null) {
        buffer.writeln('=== Test 8: Load More ===');
        final moreItems = await videosRepo.loadMore(singleResults.items.nextPageToken!);
        buffer.writeln('✓ Loaded ${moreItems.items.length} more items');
        buffer.writeln('');
      }

      // Test 9: Get stream info (if we have a URL)
      if (singleResults.items.items.isNotEmpty) {
        final firstItem = singleResults.items.items.first;
        if (firstItem.data is StreamSummaryModel) {
          final stream = firstItem.data as StreamSummaryModel;
          if (stream.url != null) {
            buffer.writeln('=== Test 9: Get Stream Info ===');
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

      // Test 10: Get catalogs
      try {
        final catalogs = await videosRepo.getCatalogs();
        buffer.writeln('✓ Available catalogs: ${catalogs.join(", ")}');
             buffer.writeln('=== Test 10: Get Catalogs ===');
 
        // Try to get catalog content for first provider
        if (catalogs.isNotEmpty) {
          final catalogContent = await videosRepo.getCatalog(catalogs.first);
          buffer.writeln('✓ ${catalogs.first} catalog has ${catalogContent.length} playlists');
        }
      } catch (e) {
        buffer.writeln('⚠ Catalogs not available: $e');
      }
      buffer.writeln('');

      buffer.writeln('✅ All tests completed!');

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
            Row(
              children: [
                Icon(
                  Icons.science_rounded,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  'Test Videos Feature',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Comprehensive test suite for video search functionality',
              style: Theme.of(context).textTheme.bodyMedium,
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
                      hintText: 'Enter search term...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runTest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(_isLoading ? 'Testing...' : 'Run All Tests'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Output
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.terminal_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Test Output',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _output,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                                height: 1.6,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
