// TV Series data models — mirrors movie_model.dart

class SeriesModel {
  final int id;
  final String? name;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final int? voteCount;
  final String? firstAirDate;
  final List<int>? genreIds;
  final double? popularity;
  final String? originalLanguage;

  SeriesModel({
    required this.id,
    this.name,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.voteCount,
    this.firstAirDate,
    this.genreIds,
    this.popularity,
    this.originalLanguage,
  });

  factory SeriesModel.fromJson(Map<String, dynamic> json) {
    return SeriesModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['original_name'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'],
      firstAirDate: json['first_air_date'],
      genreIds: (json['genre_ids'] as List?)?.cast<int>(),
      popularity: (json['popularity'] as num?)?.toDouble(),
      originalLanguage: json['original_language'],
    );
  }

  String get fullPosterPath =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  String get fullBackdropPath =>
      backdropPath != null
          ? 'https://image.tmdb.org/t/p/w1280$backdropPath'
          : '';

  String get year {
    if (firstAirDate == null || firstAirDate!.isEmpty) return '';
    return firstAirDate!.split('-').first;
  }

  String get formattedRating =>
      voteAverage != null ? voteAverage!.toStringAsFixed(1) : 'N/A';
}

class SeriesResponseModel {
  final int page;
  final List<SeriesModel> results;
  final int totalPages;
  final int totalResults;

  SeriesResponseModel({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory SeriesResponseModel.fromJson(Map<String, dynamic> json) {
    return SeriesResponseModel(
      page: json['page'] ?? 1,
      results: (json['results'] as List?)
              ?.map((e) => SeriesModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalPages: json['total_pages'] ?? 1,
      totalResults: json['total_results'] ?? 0,
    );
  }

  bool get hasMore => page < totalPages;
}

// ── Genre ──

class SeriesGenreModel {
  final int id;
  final String name;

  SeriesGenreModel({required this.id, required this.name});

  factory SeriesGenreModel.fromJson(Map<String, dynamic> json) {
    return SeriesGenreModel(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

// ── Production Company ──

class SeriesProductionCompanyModel {
  final int id;
  final String? name;
  final String? logoPath;

  SeriesProductionCompanyModel({required this.id, this.name, this.logoPath});

  factory SeriesProductionCompanyModel.fromJson(Map<String, dynamic> json) {
    return SeriesProductionCompanyModel(
      id: json['id'] ?? 0,
      name: json['name'],
      logoPath: json['logo_path'],
    );
  }

  String get fullLogoPath =>
      logoPath != null ? 'https://image.tmdb.org/t/p/w200$logoPath' : '';
}

// ── Network ──

class NetworkModel {
  final int id;
  final String? name;
  final String? logoPath;

  NetworkModel({required this.id, this.name, this.logoPath});

  factory NetworkModel.fromJson(Map<String, dynamic> json) {
    return NetworkModel(
      id: json['id'] ?? 0,
      name: json['name'],
      logoPath: json['logo_path'],
    );
  }

  String get fullLogoPath =>
      logoPath != null ? 'https://image.tmdb.org/t/p/w200$logoPath' : '';
}

// ── Season ──

class SeasonModel {
  final int id;
  final int seasonNumber;
  final String? name;
  final String? overview;
  final String? posterPath;
  final String? airDate;
  final int? episodeCount;

  SeasonModel({
    required this.id,
    required this.seasonNumber,
    this.name,
    this.overview,
    this.posterPath,
    this.airDate,
    this.episodeCount,
  });

  factory SeasonModel.fromJson(Map<String, dynamic> json) {
    return SeasonModel(
      id: json['id'] ?? 0,
      seasonNumber: json['season_number'] ?? 0,
      name: json['name'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      airDate: json['air_date'],
      episodeCount: json['episode_count'],
    );
  }

  String get fullPosterPath =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  String get year {
    if (airDate == null || airDate!.isEmpty) return '';
    return airDate!.split('-').first;
  }
}

// ── Episode ──

class EpisodeModel {
  final int id;
  final int episodeNumber;
  final int seasonNumber;
  final String? name;
  final String? overview;
  final String? stillPath;
  final String? airDate;
  final double? voteAverage;
  final int? runtime;

  EpisodeModel({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    this.name,
    this.overview,
    this.stillPath,
    this.airDate,
    this.voteAverage,
    this.runtime,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['id'] ?? 0,
      episodeNumber: json['episode_number'] ?? 0,
      seasonNumber: json['season_number'] ?? 0,
      name: json['name'],
      overview: json['overview'],
      stillPath: json['still_path'],
      airDate: json['air_date'],
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      runtime: json['runtime'],
    );
  }

  String get fullStillPath =>
      stillPath != null ? 'https://image.tmdb.org/t/p/w500$stillPath' : '';

  String get formattedRuntime {
    if (runtime == null || runtime == 0) return '';
    final h = runtime! ~/ 60;
    final m = runtime! % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

// ── Season Detail (full season with episodes) ──

class SeasonDetailModel {
  final int id;
  final int seasonNumber;
  final String? name;
  final String? overview;
  final String? posterPath;
  final String? airDate;
  final List<EpisodeModel> episodes;

  SeasonDetailModel({
    required this.id,
    required this.seasonNumber,
    this.name,
    this.overview,
    this.posterPath,
    this.airDate,
    this.episodes = const [],
  });

  factory SeasonDetailModel.fromJson(Map<String, dynamic> json) {
    return SeasonDetailModel(
      id: json['id'] ?? 0,
      seasonNumber: json['season_number'] ?? 0,
      name: json['name'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      airDate: json['air_date'],
      episodes: (json['episodes'] as List?)
              ?.map((e) => EpisodeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get fullPosterPath =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';
}

// ── Series Detail ──

class SeriesDetailModel {
  final int id;
  final String? name;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final int? voteCount;
  final String? firstAirDate;
  final String? lastAirDate;
  final List<SeriesGenreModel> genres;
  final String? status;
  final String? tagline;
  final String? homepage;
  final String? originalLanguage;
  final double? popularity;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final bool? inProduction;
  final List<int> episodeRunTime;
  final List<SeasonModel> seasons;
  final List<NetworkModel> networks;
  final List<SeriesProductionCompanyModel> productionCompanies;
  final EpisodeModel? lastEpisodeToAir;
  final EpisodeModel? nextEpisodeToAir;
  final List<String> spokenLanguages;

  SeriesDetailModel({
    required this.id,
    this.name,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.voteCount,
    this.firstAirDate,
    this.lastAirDate,
    this.genres = const [],
    this.status,
    this.tagline,
    this.homepage,
    this.originalLanguage,
    this.popularity,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.inProduction,
    this.episodeRunTime = const [],
    this.seasons = const [],
    this.networks = const [],
    this.productionCompanies = const [],
    this.lastEpisodeToAir,
    this.nextEpisodeToAir,
    this.spokenLanguages = const [],
  });

  factory SeriesDetailModel.fromJson(Map<String, dynamic> json) {
    return SeriesDetailModel(
      id: json['id'] ?? 0,
      name: json['name'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'],
      firstAirDate: json['first_air_date'],
      lastAirDate: json['last_air_date'],
      genres: (json['genres'] as List?)
              ?.map((e) => SeriesGenreModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status'],
      tagline: json['tagline'],
      homepage: json['homepage'],
      originalLanguage: json['original_language'],
      popularity: (json['popularity'] as num?)?.toDouble(),
      numberOfSeasons: json['number_of_seasons'],
      numberOfEpisodes: json['number_of_episodes'],
      inProduction: json['in_production'],
      episodeRunTime: (json['episode_run_time'] as List?)?.cast<int>() ?? [],
      seasons: (json['seasons'] as List?)
              ?.map((e) => SeasonModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      networks: (json['networks'] as List?)
              ?.map((e) => NetworkModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      productionCompanies: (json['production_companies'] as List?)
              ?.map((e) => SeriesProductionCompanyModel.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      lastEpisodeToAir: json['last_episode_to_air'] != null
          ? EpisodeModel.fromJson(
              json['last_episode_to_air'] as Map<String, dynamic>)
          : null,
      nextEpisodeToAir: json['next_episode_to_air'] != null
          ? EpisodeModel.fromJson(
              json['next_episode_to_air'] as Map<String, dynamic>)
          : null,
      spokenLanguages: (json['spoken_languages'] as List?)
              ?.map((e) =>
                  (e as Map<String, dynamic>)['english_name'] as String? ?? '')
              .where((l) => l.isNotEmpty)
              .toList() ??
          [],
    );
  }

  String get fullPosterPath =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  String get fullBackdropPath =>
      backdropPath != null
          ? 'https://image.tmdb.org/t/p/w1280$backdropPath'
          : '';

  String get year {
    if (firstAirDate == null || firstAirDate!.isEmpty) return '';
    return firstAirDate!.split('-').first;
  }

  String get formattedRating =>
      voteAverage != null ? voteAverage!.toStringAsFixed(1) : 'N/A';

  String get formattedRuntime {
    if (episodeRunTime.isEmpty) return '';
    final avg = episodeRunTime.reduce((a, b) => a + b) ~/ episodeRunTime.length;
    if (avg == 0) return '';
    final h = avg ~/ 60;
    final m = avg % 60;
    if (h > 0) return '${h}h ${m}m / ep';
    return '${m}m / ep';
  }
}

// ── Credits (reuse same structure as movies) ──

class SeriesCastModel {
  final int id;
  final String? name;
  final String? character;
  final String? profilePath;
  final String? knownForDepartment;
  final int? order;

  SeriesCastModel({
    required this.id,
    this.name,
    this.character,
    this.profilePath,
    this.knownForDepartment,
    this.order,
  });

  factory SeriesCastModel.fromJson(Map<String, dynamic> json) {
    return SeriesCastModel(
      id: json['id'] ?? 0,
      name: json['name'],
      character: json['character'] ?? json['roles']?[0]?['character'],
      profilePath: json['profile_path'],
      knownForDepartment: json['known_for_department'],
      order: json['order'],
    );
  }

  String get fullProfilePath =>
      profilePath != null
          ? 'https://image.tmdb.org/t/p/w185$profilePath'
          : '';
}

class SeriesCrewModel {
  final int id;
  final String? name;
  final String? job;
  final String? department;
  final String? profilePath;

  SeriesCrewModel({
    required this.id,
    this.name,
    this.job,
    this.department,
    this.profilePath,
  });

  factory SeriesCrewModel.fromJson(Map<String, dynamic> json) {
    return SeriesCrewModel(
      id: json['id'] ?? 0,
      name: json['name'],
      job: json['job'],
      department: json['department'],
      profilePath: json['profile_path'],
    );
  }
}

class SeriesCreditsModel {
  final List<SeriesCastModel> cast;
  final List<SeriesCrewModel> crew;

  SeriesCreditsModel({required this.cast, required this.crew});

  factory SeriesCreditsModel.fromJson(Map<String, dynamic> json) {
    return SeriesCreditsModel(
      cast: (json['cast'] as List?)
              ?.map((e) =>
                  SeriesCastModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      crew: (json['crew'] as List?)
              ?.map((e) =>
                  SeriesCrewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  List<SeriesCrewModel> get directors =>
      crew.where((c) => c.job == 'Director').toList();

  List<SeriesCrewModel> get writers =>
      crew.where((c) => c.department == 'Writing').toList();

  List<SeriesCrewModel> get creators =>
      crew.where((c) => c.job == 'Series Director' || c.job == 'Creator').toList();
}

// ── Series Videos ──

class SeriesVideoModel {
  final String? key;
  final String? name;
  final String? site;
  final String? type;
  final bool? official;

  SeriesVideoModel({this.key, this.name, this.site, this.type, this.official});

  factory SeriesVideoModel.fromJson(Map<String, dynamic> json) {
    return SeriesVideoModel(
      key: json['key'],
      name: json['name'],
      site: json['site'],
      type: json['type'],
      official: json['official'],
    );
  }

  String get youtubeUrl =>
      site == 'YouTube' && key != null
          ? 'https://www.youtube.com/watch?v=$key'
          : '';

  String get youtubeThumbnail =>
      site == 'YouTube' && key != null
          ? 'https://img.youtube.com/vi/$key/hqdefault.jpg'
          : '';
}
