import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/features/movies/data/models/movie_model.dart';
import 'package:streamapp/features/movies/presentation/cubit/movies_cubit.dart';
import 'package:streamapp/features/movies/presentation/cubit/movies_state.dart';
import 'package:streamapp/features/movies/presentation/pages/movie_details_page.dart';
import 'package:streamapp/features/movies/presentation/widgets/movie_card_widget.dart';

class PersonDetailsPage extends StatelessWidget {
  final int personId;
  const PersonDetailsPage({super.key, required this.personId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MoviesCubit(repository: sl())..loadPersonDetails(personId),
      child: const _PersonDetailsContent(),
    );
  }
}

class _PersonDetailsContent extends StatefulWidget {
  const _PersonDetailsContent();
  @override
  State<_PersonDetailsContent> createState() => _PersonDetailsContentState();
}

class _PersonDetailsContentState extends State<_PersonDetailsContent> {
  // ── Sections: 0=back  1=acting row  2=crew row
  int _section = 0;

  int _actingIndex = 0;
  final _actingScroll = ScrollController();

  int _crewIndex = 0;
  final _crewScroll = ScrollController();

  final _backNode   = FocusNode();
  final _pageScroll = ScrollController();

  bool _isBioExpanded = false;

  // Cached loaded state
  List<MovieModel> _castMovies = [];
  List<MovieModel> _crewMovies = [];

  int get _maxSection {
    int max = 0;
    if (_castMovies.isNotEmpty) max = 1;
    if (_crewMovies.isNotEmpty) max = 2;
    return max;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _backNode.requestFocus());
  }

  @override
  void dispose() {
    _backNode.dispose();
    _actingScroll.dispose();
    _crewScroll.dispose();
    _pageScroll.dispose();
    super.dispose();
  }

  void _goSection(int s) {
    if (s < 0 || s > _maxSection) return;
    setState(() => _section = s);
    if (s == 0) _backNode.requestFocus();
    _scrollPageToSection(s);
  }

  void _scrollPageToSection(int s) {
    if (!_pageScroll.hasClients) return;
    final offset = switch (s) {
      0 => 0.0,
      1 => 700.0,
      2 => 1100.0,
      _ => 0.0,
    };
    _pageScroll.animateTo(
      offset.clamp(0.0, _pageScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollRow(ScrollController ctrl, int index, {double itemW = 216}) {
    if (!ctrl.hasClients) return;
    final target = (index * itemW - 80.0).clamp(0.0, ctrl.position.maxScrollExtent);
    ctrl.animateTo(target,
        duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    switch (_section) {
      // ── 0: back button ──────────────────────────────────────────────────────
      case 0:
        if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowRight) {
          _goSection(1);
          return KeyEventResult.handled;
        }

      // ── 1: acting row ────────────────────────────────────────────────────────
      case 1:
        final maxAct = _castMovies.length.clamp(0, 30) - 1;
        if (key == LogicalKeyboardKey.arrowUp) {
          _goSection(0); return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          _goSection(2); return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft && _actingIndex > 0) {
          setState(() => _actingIndex--);
          _scrollRow(_actingScroll, _actingIndex);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight && _actingIndex < maxAct) {
          setState(() => _actingIndex++);
          _scrollRow(_actingScroll, _actingIndex);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.enter) {
          final movie = _castMovies[_actingIndex];
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => MovieDetailsPage(movieId: movie.id)));
          return KeyEventResult.handled;
        }

      // ── 2: crew row ──────────────────────────────────────────────────────────
      case 2:
        final maxCrew = _crewMovies.length.clamp(0, 30) - 1;
        if (key == LogicalKeyboardKey.arrowUp) {
          _goSection(1); return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft && _crewIndex > 0) {
          setState(() => _crewIndex--);
          _scrollRow(_crewScroll, _crewIndex);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight && _crewIndex < maxCrew) {
          setState(() => _crewIndex++);
          _scrollRow(_crewScroll, _crewIndex);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.enter) {
          final movie = _crewMovies[_crewIndex];
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => MovieDetailsPage(movieId: movie.id)));
          return KeyEventResult.handled;
        }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (_, event) => _handleKey(event),
      child: Scaffold(
        body: BlocBuilder<MoviesCubit, MoviesState>(
          builder: (context, state) {
            if (state is MoviesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MoviesError) {
              return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 80, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading person',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(state.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Go Back'),
                  ),
                ],
              ));
            }
            if (state is PersonDetailLoaded) {
              final seenIds = <int>{};
              _castMovies = state.credits.cast
                  .where((m) => m.posterPath != null && seenIds.add(m.id))
                  .toList()
                ..sort((a, b) => (b.popularity ?? 0).compareTo(a.popularity ?? 0));
              _crewMovies = state.credits.crew
                  .where((m) => m.posterPath != null && !seenIds.contains(m.id))
                  .toList()
                ..sort((a, b) => (b.popularity ?? 0).compareTo(a.popularity ?? 0));
              return _buildContent(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PersonDetailLoaded state) {
    final person = state.person;

    return SingleChildScrollView(
      controller: _pageScroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(context, person),
          const SizedBox(height: 40),

          // Personal Info chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Wrap(spacing: 24, runSpacing: 16, children: [
              if (person.knownForDepartment != null)
                _infoCard(context, Icons.work_rounded, 'Known For',
                    person.knownForDepartment!),
              if (person.birthday != null)
                _infoCard(context, Icons.cake_rounded, 'Born',
                    '${person.birthday}${person.age.isNotEmpty ? ' (age ${person.age})' : ''}'),
              if (person.deathday != null)
                _infoCard(context, Icons.event_rounded, 'Died', person.deathday!),
              if (person.placeOfBirth != null)
                _infoCard(context, Icons.location_on_rounded,
                    'Place of Birth', person.placeOfBirth!),
              if (person.gender != null)
                _infoCard(context,
                  person.gender == 1
                      ? Icons.female_rounded
                      : person.gender == 2
                          ? Icons.male_rounded
                          : Icons.person_rounded,
                  'Gender',
                  person.gender == 1
                      ? 'Female'
                      : person.gender == 2
                          ? 'Male'
                          : 'Other'),
            ]),
          ),
          const SizedBox(height: 40),

          // Biography
          if (person.biography != null && person.biography!.isNotEmpty) ...[
            Padding(padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text('Biography',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold))),
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(person.biography!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
                      maxLines: _isBioExpanded ? null : 6,
                      overflow: _isBioExpanded ? TextOverflow.clip : TextOverflow.ellipsis),
                  if (person.biography!.length > 300) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => setState(() => _isBioExpanded = !_isBioExpanded),
                      child: Text(
                        _isBioExpanded ? 'Show less' : 'Read full biography',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 40),
          ],

          // Also Known As
          if (person.alsoKnownAs != null && person.alsoKnownAs!.isNotEmpty) ...[
            Padding(padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text('Also Known As',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Wrap(spacing: 8, runSpacing: 8,
                children: person.alsoKnownAs!.take(10).map((name) => Chip(
                  label: Text(name),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                )).toList()),
            ),
            const SizedBox(height: 40),
          ],

          // Acting filmography (section 1)
          if (_castMovies.isNotEmpty) ...[
            _sectionHeader(context, '🎭 Acting',
                count: _castMovies.length, isFocused: _section == 1),
            const SizedBox(height: 16),
            SizedBox(
              height: 340,
              child: ListView.builder(
                controller: _actingScroll,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 52),
                itemCount: _castMovies.length.clamp(0, 30),
                itemBuilder: (context, i) {
                  final movie = _castMovies[i];
                  return MovieCardWidget(
                    movie: movie,
                    isFocused: i == _actingIndex && _section == 1,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => MovieDetailsPage(movieId: movie.id))),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Crew filmography (section 2)
          if (_crewMovies.isNotEmpty) ...[
            _sectionHeader(context, '🎬 Behind the Camera',
                count: _crewMovies.length, isFocused: _section == 2),
            const SizedBox(height: 16),
            SizedBox(
              height: 340,
              child: ListView.builder(
                controller: _crewScroll,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 52),
                itemCount: _crewMovies.length.clamp(0, 30),
                itemBuilder: (context, i) {
                  final movie = _crewMovies[i];
                  return MovieCardWidget(
                    movie: movie,
                    isFocused: i == _crewIndex && _section == 2,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => MovieDetailsPage(movieId: movie.id))),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Hero section ─────────────────────────────────────────────────────────────

  Widget _buildHeroSection(BuildContext context, PersonDetailModel person) {
    return Container(
      padding: const EdgeInsets.fromLTRB(60, 40, 60, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Column(children: [
        // Back button row
        Row(children: [
          Focus(
            focusNode: _backNode,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: _section == 0
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
                    : null,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          const Spacer(),
        ]),
        const SizedBox(height: 20),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Profile image
          Container(
            width: 220, height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.2), blurRadius: 20,
                  offset: const Offset(0, 10))],
            ),
            child: person.fullProfilePath.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(16),
                    child: Image.network(person.fullProfilePath, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(context)))
                : _placeholder(context),
          ),
          const SizedBox(width: 40),

          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(person.name ?? 'Unknown',
                style: Theme.of(context).textTheme.displayMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (person.knownForDepartment != null)
              Text(person.knownForDepartment!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 8, children: [
              if (person.birthday != null)
                _quickChip(context, Icons.cake_rounded, person.birthday!),
              if (person.age.isNotEmpty)
                _quickChip(context, Icons.person_rounded, 'Age: ${person.age}'),
              if (person.placeOfBirth != null)
                _quickChip(context, Icons.location_on_rounded, person.placeOfBirth!),
              if (person.popularity != null)
                _quickChip(context, Icons.trending_up_rounded,
                    'Popularity: ${person.popularity!.toStringAsFixed(0)}'),
            ]),
          ])),
        ]),
      ]),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Center(child: Icon(Icons.person_rounded, size: 80,
        color: Theme.of(context).colorScheme.onSurfaceVariant));
  }

  // ── Section header with active indicator ──────────────────────────────────

  Widget _sectionHeader(BuildContext context, String title,
      {int count = 0, bool isFocused = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Row(children: [
        if (isFocused)
          Container(width: 4, height: 24, margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              )),
        Text(title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isFocused ? Theme.of(context).colorScheme.primary : null)),
        if (count > 0) ...[
          const SizedBox(width: 12),
          Text('$count titles',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5))),
        ],
        if (isFocused) ...[
          const Spacer(),
          Icon(Icons.keyboard_arrow_right_rounded,
              color: Theme.of(context).colorScheme.primary, size: 24),
        ],
      ]),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _infoCard(BuildContext context, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6))),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(value,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ]),
      ]),
    );
  }

  Widget _quickChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(text, style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}
