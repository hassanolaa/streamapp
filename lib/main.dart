
import 'package:args/args.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:media_kit/media_kit.dart';
import 'package:streamapp/core/di/service_locator.dart' as di;
import 'package:streamapp/core/theme/app_theme.dart';
import 'package:streamapp/features/home/presentation/pages/navigation_shell.dart';
import 'package:streamapp/features/iptv/presentation/pages/iptv_home_page.dart';
import 'package:streamapp/features/movies/presentation/pages/movies_home_page.dart';
import 'package:streamapp/features/series/presentation/pages/series_home_page.dart';
import 'package:streamapp/features/videos/presentation/pages/channel_details_page.dart';
import 'package:streamapp/features/videos/presentation/pages/playlist_details_page.dart';
import 'package:streamapp/features/videos/presentation/pages/search_page.dart';
import 'package:streamapp/features/videos/presentation/pages/video_details_page.dart';
import 'package:streamapp/features/videos/presentation/pages/videos_home_page.dart';
import 'package:streamapp/test_videos_page.dart';

void main(List<String> args) async {
  final parsedList = args.expand((arg) => arg.split(',')).toList();
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await GetStorage.init();

  di.setupLocator();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MyApp(args: parsedList),
    ),
  );
}

class MyApp extends StatelessWidget {
  final List<String> args;

  const MyApp({super.key, required this.args});

  /// Parse all CLI arguments
  Map<String, String> _parseArgs() {
    try {
      final parser = ArgParser()
        ..addOption('screen', abbr: 's', defaultsTo: 'home')
        ..addOption('url', abbr: 'u')
        ..addOption('query', abbr: 'q');

      final results = parser.parse(args);

      return {
        'screen': results['screen'] ?? 'home',
        if (results['url'] != null) 'url': results['url']!,
        if (results['query'] != null) 'query': results['query']!,
      };
    } catch (e) {
      debugPrint('❌ Failed to parse args: $e');
      return {'screen': 'home'};
    }
  }

  /// Resolve which widget to show based on parsed args
  Widget _resolveInitialPage(Map<String, String> parsedArgs) {
    final screen = parsedArgs['screen'] ?? 'home';
    final url = parsedArgs['url'];
    final query = parsedArgs['query'];

    debugPrint('🚀 Launching screen: $screen | url: $url | query: $query');

    switch (screen) {
      // ── Test Page ──────────────────────────────────────────
      case 'test':
        return const TestVideosPage();

      // ── Search ─────────────────────────────────────────────
      case 'search':
        return SearchPage( //initialQuery: query ?? ''
        );

      // ── Playlist ───────────────────────────────────────────
      case 'playlist':
        if (url == null || url.isEmpty) {
          debugPrint('⚠️  --url is required for screen=playlist');
          return const NavigationShell();
        }
        return PlaylistDetailsPage(playlistUrl: url);

      // ── Video ──────────────────────────────────────────────
      case 'video':
        if (url == null || url.isEmpty) {
          debugPrint('⚠️  --url is required for screen=video');
          return const NavigationShell();
        }
        return VideoDetailsPage(videoUrl: url);

      // ── Channel ────────────────────────────────────────────
      case 'channel':
        if (url == null || url.isEmpty) {
          debugPrint('⚠️  --url is required for screen=channel');
          return const NavigationShell();
        }
        return ChannelDetailsPage(channelUrl: url);

      case 'videos':
        return const VideosHomePage();
      case 'movies':
        return const MoviesHomePage();
      
      case 'series':
        return const SeriesHomePage();
      
      case 'iptv':
        return const IptvHomePage();
      
      // ── Home (default) ─────────────────────────────────────
      case 'home':
      default:
        return const NavigationShell();
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsedArgs = _parseArgs();
    final initialPage = _resolveInitialPage(parsedArgs);

    return MaterialApp(
      title: 'Stream App',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: initialPage,
    );
  }
}
