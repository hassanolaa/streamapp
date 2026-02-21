import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/features/movies/presentation/pages/person_details_page.dart';
import 'package:streamapp/features/series/data/models/series_model.dart';
import 'package:streamapp/features/series/presentation/cubit/series_cubit.dart';
import 'package:streamapp/features/series/presentation/cubit/series_state.dart';
import 'package:streamapp/features/series/presentation/widgets/series_card_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class SeriesDetailsPage extends StatelessWidget {
  final int seriesId;
  const SeriesDetailsPage({super.key, required this.seriesId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SeriesCubit(repository: sl())..loadSeriesDetails(seriesId),
      child: const _SeriesDetailsContent(),
    );
  }
}

class _SeriesDetailsContent extends StatefulWidget {
  const _SeriesDetailsContent();

  @override
  State<_SeriesDetailsContent> createState() => _SeriesDetailsContentState();
}

class _SeriesDetailsContentState extends State<_SeriesDetailsContent> {
  // Sections: 0=back  1=actionBtns  2=seasons  3=cast  4=trailers  5=similar  6=recommended
  int _section = 0;

  // Section 1 – hero action buttons
  int _btnIndex = 0;
  final _btnNodes = List.generate(2, (_) => FocusNode());

  // Section 2 – seasons row
  int _seasonIndex = 0;
  final _seasonScroll = ScrollController();

  // Section 3 – cast
  int _castIndex = 0;
  final _castScroll = ScrollController();

  // Section 4 – trailers
  int _trailerIndex = 0;
  final _trailerScroll = ScrollController();

  // Section 5 – similar
  int _similarIndex = 0;
  final _similarScroll = ScrollController();

  // Section 6 – recommended
  int _recommendedIndex = 0;
  final _recommendedScroll = ScrollController();

  final _backNode = FocusNode();
  final _pageScroll = ScrollController();

  bool _isOverviewExpanded = false;

  SeriesDetailLoaded? _loaded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _backNode.requestFocus());
  }

  @override
  void dispose() {
    _backNode.dispose();
    for (final n in _btnNodes) n.dispose();
    _seasonScroll.dispose();
    _castScroll.dispose();
    _trailerScroll.dispose();
    _similarScroll.dispose();
    _recommendedScroll.dispose();
    _pageScroll.dispose();
    super.dispose();
  }

  int get _maxSection {
    if (_loaded == null) return 0;
    int max = 1;
    final seasons = _loaded!.detail.seasons
        .where((s) => s.seasonNumber > 0)
        .toList();
    if (seasons.isNotEmpty) max = 2;
    if (_loaded!.credits.cast.isNotEmpty) max = 3;
    final videos = _loaded!.videos.where((v) => v.site == 'YouTube').toList();
    if (videos.isNotEmpty) max = 4;
    if (_loaded!.similarSeries.isNotEmpty) max = 5;
    if (_loaded!.recommendedSeries.isNotEmpty) max = 6;
    return max;
  }

  void _goSection(int s) {
    if (s < 0 || s > _maxSection) return;
    setState(() => _section = s);
    _scrollPageToSection(s);
    if (s == 0) _backNode.requestFocus();
    if (s == 1) _btnNodes[_btnIndex].requestFocus();
  }

  void _scrollPageToSection(int s) {
    final offset = switch (s) {
      0 || 1 => 0.0,
      2 => 520.0,
      3 => 820.0,
      4 => 1120.0,
      5 => 1420.0,
      6 => 1720.0,
      _ => 0.0,
    };
    if (_pageScroll.hasClients) {
      _pageScroll.animateTo(
        offset.clamp(0.0, _pageScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollRow(ScrollController ctrl, int index, {double itemW = 216}) {
    if (!ctrl.hasClients) return;
    final target =
        (index * itemW - 80).clamp(0.0, ctrl.position.maxScrollExtent);
    ctrl.animateTo(target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic);
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    switch (_section) {
      case 0:
        if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.arrowRight) {
          _goSection(1);
          return KeyEventResult.handled;
        }

      case 1:
        if (key == LogicalKeyboardKey.arrowUp ||
            (key == LogicalKeyboardKey.arrowLeft && _btnIndex == 0)) {
          _goSection(0);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft && _btnIndex > 0) {
          setState(() => _btnIndex--);
          _btnNodes[_btnIndex].requestFocus();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight && _btnIndex < 1) {
          setState(() => _btnIndex++);
          _btnNodes[_btnIndex].requestFocus();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          _goSection(2);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
          _activateHeroButton();
          return KeyEventResult.handled;
        }

      case 2: // seasons
        final seasons = _loaded!.detail.seasons
            .where((s) => s.seasonNumber > 0)
            .toList();
        final maxIdx = seasons.length - 1;
        if (key == LogicalKeyboardKey.arrowUp) {
          _goSection(1);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          _goSection(3);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft && _seasonIndex > 0) {
          setState(() => _seasonIndex--);
          _scrollRow(_seasonScroll, _seasonIndex, itemW: 180);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight && _seasonIndex < maxIdx) {
          setState(() => _seasonIndex++);
          _scrollRow(_seasonScroll, _seasonIndex, itemW: 180);
          return KeyEventResult.handled;
        }

      case 3: // cast
        final maxCast = (_loaded!.credits.cast.length.clamp(0, 20) - 1);
        if (key == LogicalKeyboardKey.arrowUp) {
          _goSection(2);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          _goSection(4);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft && _castIndex > 0) {
          setState(() => _castIndex--);
          _scrollRow(_castScroll, _castIndex, itemW: 138);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight && _castIndex < maxCast) {
          setState(() => _castIndex++);
          _scrollRow(_castScroll, _castIndex, itemW: 138);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.enter) {
          final actor = _loaded!.credits.cast[_castIndex];
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PersonDetailsPage(personId: actor.id)));
          return KeyEventResult.handled;
        }

      case 4: // trailers
        final videos = _loaded!.videos
            .where((v) => v.site == 'YouTube')
            .toList();
        final maxTrailer = videos.length.clamp(0, 10) - 1;
        if (key == LogicalKeyboardKey.arrowUp) {
          _goSection(3);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          _goSection(5);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft && _trailerIndex > 0) {
          setState(() => _trailerIndex--);
          _scrollRow(_trailerScroll, _trailerIndex, itemW: 316);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight && _trailerIndex < maxTrailer) {
          setState(() => _trailerIndex++);
          _scrollRow(_trailerScroll, _trailerIndex, itemW: 316);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.enter) {
          final url = videos[_trailerIndex].youtubeUrl;
          if (url.isNotEmpty) _launchUrl(url);
          return KeyEventResult.handled;
        }

      case 5: // similar
        final maxSim = _loaded!.similarSeries.length.clamp(0, 20) - 1;
        if (key == LogicalKeyboardKey.arrowUp) {
          _goSection(4);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          _goSection(6);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft && _similarIndex > 0) {
          setState(() => _similarIndex--);
          _scrollRow(_similarScroll, _similarIndex);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight && _similarIndex < maxSim) {
          setState(() => _similarIndex++);
          _scrollRow(_similarScroll, _similarIndex);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.enter) {
          final s = _loaded!.similarSeries[_similarIndex];
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SeriesDetailsPage(seriesId: s.id)));
          return KeyEventResult.handled;
        }

      case 6: // recommended
        final maxRec = _loaded!.recommendedSeries.length.clamp(0, 20) - 1;
        if (key == LogicalKeyboardKey.arrowUp) {
          _goSection(5);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft && _recommendedIndex > 0) {
          setState(() => _recommendedIndex--);
          _scrollRow(_recommendedScroll, _recommendedIndex);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight && _recommendedIndex < maxRec) {
          setState(() => _recommendedIndex++);
          _scrollRow(_recommendedScroll, _recommendedIndex);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.enter) {
          final s = _loaded!.recommendedSeries[_recommendedIndex];
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SeriesDetailsPage(seriesId: s.id)));
          return KeyEventResult.handled;
        }
    }

    return KeyEventResult.ignored;
  }

  void _activateHeroButton() {
    if (_loaded == null) return;
    final detail = _loaded!.detail;
    if (_btnIndex == 0 &&
        detail.homepage != null &&
        detail.homepage!.isNotEmpty) {
      _launchUrl(detail.homepage!);
    } else if (_btnIndex == 1) {
      // IMDb link via TMDB external IDs — open TMDB page as fallback
      _launchUrl('https://www.themoviedb.org/tv/${detail.id}');
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (_, event) => _handleKey(event),
      child: Scaffold(
        body: BlocBuilder<SeriesCubit, SeriesState>(
          builder: (context, state) {
            if (state is SeriesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SeriesError) {
              return _buildError(context, state.message);
            }
            if (state is SeriesDetailLoaded) {
              _loaded = state;
              return _buildBody(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SeriesDetailLoaded state) {
    final detail = state.detail;
    final credits = state.credits;
    final videos = state.videos
        .where((v) => v.site == 'YouTube')
        .toList()
      ..sort((a, b) {
        const order = {'Trailer': 0, 'Teaser': 1};
        return (order[a.type] ?? 2).compareTo(order[b.type] ?? 2);
      });
    final seasons =
        detail.seasons.where((s) => s.seasonNumber > 0).toList();

    return SingleChildScrollView(
      controller: _pageScroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroBanner(context, detail, credits),
          const SizedBox(height: 40),

          // Info chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Wrap(spacing: 16, runSpacing: 12, children: [
              if (detail.formattedRuntime.isNotEmpty)
                _infoChip(context, Icons.schedule_rounded,
                    detail.formattedRuntime, Colors.blue),
              if (detail.numberOfSeasons != null)
                _infoChip(context, Icons.layers_rounded,
                    '${detail.numberOfSeasons} Season${detail.numberOfSeasons! > 1 ? 's' : ''}',
                    Colors.indigo),
              if (detail.numberOfEpisodes != null)
                _infoChip(context, Icons.video_library_rounded,
                    '${detail.numberOfEpisodes} Episodes', Colors.teal),
              if (detail.status != null)
                _infoChip(context, Icons.info_outline_rounded,
                    detail.status!, Colors.orange),
              if (detail.originalLanguage != null)
                _infoChip(context, Icons.language_rounded,
                    detail.originalLanguage!.toUpperCase(), Colors.green),
            ]),
          ),
          const SizedBox(height: 24),

          // Genres
          if (detail.genres.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: detail.genres
                      .map((g) => Chip(
                            label: Text(g.name),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            labelStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                fontWeight: FontWeight.w600),
                            side: BorderSide.none,
                          ))
                      .toList()),
            ),
          const SizedBox(height: 24),

          // Networks
          if (detail.networks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text('Networks',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: detail.networks
                      .where((n) => n.name != null)
                      .map((n) => Chip(
                            avatar: n.fullLogoPath.isNotEmpty
                                ? CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(n.fullLogoPath),
                                    backgroundColor: Colors.white)
                                : CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                    child: const Icon(Icons.tv_rounded,
                                        size: 14)),
                            label: Text(n.name!),
                          ))
                      .toList()),
            ),
            const SizedBox(height: 24),
          ],

          // Overview
          if (detail.overview != null && detail.overview!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text('Overview',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detail.overview!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(height: 1.6),
                          maxLines: _isOverviewExpanded ? null : 4,
                          overflow: _isOverviewExpanded
                              ? TextOverflow.clip
                              : TextOverflow.ellipsis),
                      if (detail.overview!.length > 200) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => setState(() =>
                              _isOverviewExpanded = !_isOverviewExpanded),
                          child: Text(
                            _isOverviewExpanded ? 'Show less' : 'Show more',
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ]),
              ),
            ),
            const SizedBox(height: 40),
          ],

          // Seasons
          if (seasons.isNotEmpty) ...[
            _sectionHeader(context, 'Seasons', isFocused: _section == 2),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: ListView.builder(
                controller: _seasonScroll,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 52),
                itemCount: seasons.length,
                itemBuilder: (context, i) => _buildSeasonCard(
                    context, seasons[i], i == _seasonIndex && _section == 2),
              ),
            ),
            const SizedBox(height: 40),
          ],

          // Last episode aired
          if (detail.lastEpisodeToAir != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text('Last Episode',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: _buildEpisodeCard(context, detail.lastEpisodeToAir!),
            ),
            const SizedBox(height: 40),
          ],

          // Next episode
          if (detail.nextEpisodeToAir != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text('Next Episode',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: _buildEpisodeCard(context, detail.nextEpisodeToAir!),
            ),
            const SizedBox(height: 40),
          ],

          // Cast
          if (credits.cast.isNotEmpty) ...[
            _sectionHeader(context, 'Cast', isFocused: _section == 3),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: ListView.builder(
                controller: _castScroll,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 52),
                itemCount: credits.cast.length.clamp(0, 20),
                itemBuilder: (context, i) => _buildCastCard(context,
                    credits.cast[i], i == _castIndex && _section == 3),
              ),
            ),
            const SizedBox(height: 40),
          ],

          // Crew / Creators
          if (credits.creators.isNotEmpty || credits.writers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text('Crew',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Wrap(spacing: 24, runSpacing: 16, children: [
                ...credits.creators.map((c) => _crewChip(
                    context, c, c.job ?? 'Creator', Icons.star_rounded)),
                ...credits.writers
                    .take(4)
                    .map((w) => _crewChip(
                        context, w, w.job ?? 'Writer', Icons.edit_rounded)),
              ]),
            ),
            const SizedBox(height: 40),
          ],

          // Trailers
          if (videos.isNotEmpty) ...[
            _sectionHeader(context, 'Trailers & Videos',
                isFocused: _section == 4),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                controller: _trailerScroll,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 52),
                itemCount: videos.length.clamp(0, 10),
                itemBuilder: (context, i) => _buildVideoCard(context,
                    videos[i], i == _trailerIndex && _section == 4),
              ),
            ),
            const SizedBox(height: 40),
          ],

          // Production companies
          if (detail.productionCompanies.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text('Production',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: detail.productionCompanies
                      .where((c) => c.name != null)
                      .map((c) => Chip(
                            avatar: c.fullLogoPath.isNotEmpty
                                ? CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(c.fullLogoPath),
                                    backgroundColor: Colors.white)
                                : CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                    child: const Icon(Icons.business_rounded,
                                        size: 14)),
                            label: Text(c.name!),
                          ))
                      .toList()),
            ),
            const SizedBox(height: 40),
          ],

          // Similar series
          if (state.similarSeries.isNotEmpty) ...[
            _sectionHeader(context, '📺 Similar Series',
                isFocused: _section == 5),
            const SizedBox(height: 16),
            SizedBox(
              height: 340,
              child: ListView.builder(
                controller: _similarScroll,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 52),
                itemCount: state.similarSeries.length.clamp(0, 20),
                itemBuilder: (context, i) {
                  final s = state.similarSeries[i];
                  return SeriesCardWidget(
                    series: s,
                    isFocused: i == _similarIndex && _section == 5,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                SeriesDetailsPage(seriesId: s.id))),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],

          // Recommended series
          if (state.recommendedSeries.isNotEmpty) ...[
            _sectionHeader(context, '👍 Recommended',
                isFocused: _section == 6),
            const SizedBox(height: 16),
            SizedBox(
              height: 340,
              child: ListView.builder(
                controller: _recommendedScroll,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 52),
                itemCount: state.recommendedSeries.length.clamp(0, 20),
                itemBuilder: (context, i) {
                  final s = state.recommendedSeries[i];
                  return SeriesCardWidget(
                    series: s,
                    isFocused: i == _recommendedIndex && _section == 6,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                SeriesDetailsPage(seriesId: s.id))),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Hero banner ─────────────────────────────────────────────────────────────

  Widget _buildHeroBanner(BuildContext context, SeriesDetailModel detail,
      SeriesCreditsModel credits) {
    final w = MediaQuery.of(context).size.width;
    final h = w * 0.45;

    final hasWebsite =
        detail.homepage != null && detail.homepage!.isNotEmpty;

    return SizedBox(
      height: h,
      child: Stack(children: [
        Positioned.fill(
          child: detail.fullBackdropPath.isNotEmpty
              ? Image.network(detail.fullBackdropPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey[850]))
              : Container(color: Colors.grey[850]),
        ),
        Positioned.fill(
            child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.95)
          ],
          stops: const [0.2, 0.6, 1.0],
        )))),
        Positioned.fill(
            child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Colors.transparent,
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5)
          ],
        )))),

        // Back button
        Positioned(
          left: 20,
          top: 40,
          child: Focus(
            focusNode: _backNode,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: _section == 0
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    size: 32, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    padding: const EdgeInsets.all(8)),
              ),
            ),
          ),
        ),

        // Content
        Positioned(
          left: 60,
          bottom: 60,
          right: 60,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (detail.fullPosterPath.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(detail.fullPosterPath,
                        height: h * 0.7,
                        width: h * 0.7 * 0.67,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox()),
                  ),
                const SizedBox(width: 40),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (detail.tagline != null && detail.tagline!.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('"${detail.tagline}"',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      color: Colors.white70,
                                      fontStyle: FontStyle.italic))),
                    Text(detail.name ?? 'Untitled',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                                fontSize: 42,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                              Shadow(
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.5))
                            ]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 16),
                    Wrap(spacing: 16, runSpacing: 8, children: [
                      if (detail.year.isNotEmpty)
                        _statChip(
                            Icons.calendar_today_rounded, detail.year),
                      if (detail.voteAverage != null)
                        _statChip(Icons.star_rounded,
                            '${detail.formattedRating} / 10'),
                      if (detail.voteCount != null)
                        _statChip(Icons.how_to_vote_rounded,
                            '${_fmtCount(detail.voteCount!)} votes'),
                      if (detail.numberOfSeasons != null)
                        _statChip(Icons.layers_rounded,
                            '${detail.numberOfSeasons} Seasons'),
                    ]),
                    const SizedBox(height: 16),
                    if (credits.creators.isNotEmpty)
                      Text(
                          'Created by ${credits.creators.map((c) => c.name).join(', ')}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(children: [
                      if (hasWebsite) ...[
                        Focus(
                          focusNode: _btnNodes[0],
                          child: _HeroButton(
                            label: 'Website',
                            icon: Icons.open_in_new_rounded,
                            isFocused: _section == 1 && _btnIndex == 0,
                            bgColor: Colors.white,
                            fgColor: Colors.black,
                            onPressed: () => _launchUrl(detail.homepage!),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Focus(
                        focusNode: _btnNodes[1],
                        child: _HeroButton(
                          label: 'TMDB',
                          icon: Icons.link_rounded,
                          isFocused: _section == 1 &&
                              _btnIndex == (hasWebsite ? 1 : 0),
                          bgColor: const Color(0xFF01B4E4),
                          fgColor: Colors.white,
                          onPressed: () => _launchUrl(
                              'https://www.themoviedb.org/tv/${detail.id}'),
                        ),
                      ),
                    ]),
                  ],
                )),
              ]),
        ),
      ]),
    );
  }

  // ── Card builders ────────────────────────────────────────────────────────────

  Widget _buildSeasonCard(BuildContext context, SeasonModel season, bool focused) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: focused
            ? Border.all(
                color: Theme.of(context).colorScheme.primary, width: 3)
            : null,
        boxShadow: focused
            ? [
                BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2)
              ]
            : [],
      ),
      child: Column(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: season.fullPosterPath.isNotEmpty
                ? Image.network(season.fullPosterPath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) =>
                        _seasonPlaceholder(context))
                : _seasonPlaceholder(context),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(season.name ?? 'Season ${season.seasonNumber}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
        if (season.episodeCount != null)
          Text('${season.episodeCount} Episodes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.6))),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _seasonPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
          child: Icon(Icons.tv_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }

  Widget _buildEpisodeCard(BuildContext context, EpisodeModel ep) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(children: [
        if (ep.fullStillPath.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(ep.fullStillPath,
                width: 160,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: 160,
                    height: 90,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest)),
          ),
        const SizedBox(width: 16),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'S${ep.seasonNumber} E${ep.episodeNumber}: ${ep.name ?? ''}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            if (ep.airDate != null && ep.airDate!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(ep.airDate!,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            if (ep.overview != null && ep.overview!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(ep.overview!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ),
          ],
        )),
      ]),
    );
  }

  Widget _buildCastCard(
      BuildContext context, SeriesCastModel actor, bool focused) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PersonDetailsPage(personId: actor.id))),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: focused
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 3)
              : null,
        ),
        child: Column(children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              boxShadow: focused
                  ? [
                      BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2)
                    ]
                  : [],
            ),
            child: actor.fullProfilePath.isNotEmpty
                ? ClipOval(
                    child: Image.network(actor.fullProfilePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)))
                : Icon(Icons.person_rounded,
                    size: 48,
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Text(actor.name ?? '',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(actor.character ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.6)),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _buildVideoCard(
      BuildContext context, SeriesVideoModel video, bool focused) {
    return GestureDetector(
      onTap: () {
        if (video.youtubeUrl.isNotEmpty) _launchUrl(video.youtubeUrl);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 300,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: focused
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 3)
              : null,
          boxShadow: focused
              ? [
                  BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2)
                ]
              : [],
        ),
        child: Stack(children: [
          if (video.youtubeThumbnail.isNotEmpty)
            ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(video.youtubeThumbnail,
                    width: 300,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox())),
          Container(
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withOpacity(0.35))),
          const Positioned.fill(
              child: Center(
                  child: Icon(Icons.play_circle_fill_rounded,
                      size: 56, color: Colors.white))),
          Positioned(
              top: 8,
              left: 8,
              child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(video.type ?? 'Video',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)))),
          Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Text(video.name ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _crewChip(BuildContext context, SeriesCrewModel crew, String role,
      IconData icon) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PersonDetailsPage(personId: crew.id))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(crew.name ?? '',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text(role,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.6))),
          ]),
        ]),
      ),
    );
  }

  // ── Section header ───────────────────────────────────────────────────────────

  Widget _sectionHeader(BuildContext context, String title,
      {bool isFocused = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Row(children: [
        if (isFocused)
          Container(
              width: 4,
              height: 24,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2))),
        Text(title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isFocused
                    ? Theme.of(context).colorScheme.primary
                    : null)),
        if (isFocused) ...[
          const SizedBox(width: 12),
          Icon(Icons.keyboard_arrow_right_rounded,
              color: Theme.of(context).colorScheme.primary, size: 24),
        ],
      ]),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _infoChip(
      BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline_rounded,
          size: 80, color: Theme.of(context).colorScheme.error),
      const SizedBox(height: 16),
      Text('Error loading series',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text(message,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text('Go Back'),
      ),
    ]));
  }

  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ── Reusable hero action button ───────────────────────────────────────────────

class _HeroButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isFocused;
  final Color bgColor;
  final Color fgColor;
  final VoidCallback onPressed;

  const _HeroButton({
    required this.label,
    required this.icon,
    required this.isFocused,
    required this.bgColor,
    required this.fgColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()..scale(isFocused ? 1.06 : 1.0),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border:
              isFocused ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isFocused
              ? [
                  BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 12)
                ]
              : []),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
