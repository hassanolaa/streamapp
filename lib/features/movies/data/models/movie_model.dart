class MovieModel {
  final int id;
  final String? title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final int? voteCount;
  final String? releaseDate;
  final List<int>? genreIds;
  final double? popularity;
  final String? originalLanguage;
  final bool? adult;
  final bool? video;

  MovieModel({
    required this.id,
    this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.voteCount,
    this.releaseDate,
    this.genreIds,
    this.popularity,
    this.originalLanguage,
    this.adult,
    this.video,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'],
      releaseDate: json['release_date'] ?? json['first_air_date'],
      genreIds: (json['genre_ids'] as List?)?.cast<int>(),
      popularity: (json['popularity'] as num?)?.toDouble(),
      originalLanguage: json['original_language'],
      adult: json['adult'],
      video: json['video'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'release_date': releaseDate,
      'genre_ids': genreIds,
      'popularity': popularity,
      'original_language': originalLanguage,
      'adult': adult,
      'video': video,
    };
  }

  String get fullPosterPath =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  String get fullBackdropPath =>
      backdropPath != null
          ? 'https://image.tmdb.org/t/p/w1280$backdropPath'
          : '';

  String get year {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    return releaseDate!.split('-').first;
  }

  String get formattedRating {
    if (voteAverage == null) return 'N/A';
    return voteAverage!.toStringAsFixed(1);
  }
}

class MoviesResponseModel {
  final int page;
  final List<MovieModel> results;
  final int totalPages;
  final int totalResults;

  MoviesResponseModel({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory MoviesResponseModel.fromJson(Map<String, dynamic> json) {
    return MoviesResponseModel(
      page: json['page'] ?? 1,
      results: (json['results'] as List?)
              ?.map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalPages: json['total_pages'] ?? 1,
      totalResults: json['total_results'] ?? 0,
    );
  }

  bool get hasMore => page < totalPages;
}

class GenreModel {
  final int id;
  final String name;

  GenreModel({required this.id, required this.name});

  factory GenreModel.fromJson(Map<String, dynamic> json) {
    return GenreModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

// ── Movie Detail (full info from /movie/{id}) ──

class MovieDetailModel {
  final int id;
  final String? title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final int? voteCount;
  final String? releaseDate;
  final List<GenreModel> genres;
  final int? runtime;
  final int? budget;
  final int? revenue;
  final String? status;
  final String? tagline;
  final String? homepage;
  final String? originalLanguage;
  final String? imdbId;
  final double? popularity;
  final List<ProductionCompanyModel> productionCompanies;
  final List<String> spokenLanguages;

  MovieDetailModel({
    required this.id,
    this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.voteCount,
    this.releaseDate,
    this.genres = const [],
    this.runtime,
    this.budget,
    this.revenue,
    this.status,
    this.tagline,
    this.homepage,
    this.originalLanguage,
    this.imdbId,
    this.popularity,
    this.productionCompanies = const [],
    this.spokenLanguages = const [],
  });

  factory MovieDetailModel.fromJson(Map<String, dynamic> json) {
    return MovieDetailModel(
      id: json['id'] ?? 0,
      title: json['title'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'],
      releaseDate: json['release_date'],
      genres: (json['genres'] as List?)
              ?.map((e) => GenreModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      runtime: json['runtime'],
      budget: json['budget'],
      revenue: json['revenue'],
      status: json['status'],
      tagline: json['tagline'],
      homepage: json['homepage'],
      originalLanguage: json['original_language'],
      imdbId: json['imdb_id'],
      popularity: (json['popularity'] as num?)?.toDouble(),
      productionCompanies: (json['production_companies'] as List?)
              ?.map((e) =>
                  ProductionCompanyModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      spokenLanguages: (json['spoken_languages'] as List?)
              ?.map((e) => (e as Map<String, dynamic>)['english_name'] as String? ?? '')
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
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    return releaseDate!.split('-').first;
  }

  String get formattedRating =>
      voteAverage != null ? voteAverage!.toStringAsFixed(1) : 'N/A';

  String get formattedRuntime {
    if (runtime == null || runtime == 0) return '';
    final h = runtime! ~/ 60;
    final m = runtime! % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String get formattedBudget => _formatCurrency(budget);
  String get formattedRevenue => _formatCurrency(revenue);

  String _formatCurrency(int? amount) {
    if (amount == null || amount == 0) return 'N/A';
    if (amount >= 1000000000) {
      return '\$${(amount / 1000000000).toStringAsFixed(1)}B';
    }
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\$$amount';
  }
}

class ProductionCompanyModel {
  final int id;
  final String? name;
  final String? logoPath;
  final String? originCountry;

  ProductionCompanyModel({
    required this.id,
    this.name,
    this.logoPath,
    this.originCountry,
  });

  factory ProductionCompanyModel.fromJson(Map<String, dynamic> json) {
    return ProductionCompanyModel(
      id: json['id'] ?? 0,
      name: json['name'],
      logoPath: json['logo_path'],
      originCountry: json['origin_country'],
    );
  }

  String get fullLogoPath =>
      logoPath != null ? 'https://image.tmdb.org/t/p/w200$logoPath' : '';
}

// ── Cast & Crew ──

class CastModel {
  final int id;
  final String? name;
  final String? character;
  final String? profilePath;
  final String? knownForDepartment;
  final int? order;

  CastModel({
    required this.id,
    this.name,
    this.character,
    this.profilePath,
    this.knownForDepartment,
    this.order,
  });

  factory CastModel.fromJson(Map<String, dynamic> json) {
    return CastModel(
      id: json['id'] ?? 0,
      name: json['name'],
      character: json['character'],
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

class CrewModel {
  final int id;
  final String? name;
  final String? job;
  final String? department;
  final String? profilePath;

  CrewModel({
    required this.id,
    this.name,
    this.job,
    this.department,
    this.profilePath,
  });

  factory CrewModel.fromJson(Map<String, dynamic> json) {
    return CrewModel(
      id: json['id'] ?? 0,
      name: json['name'],
      job: json['job'],
      department: json['department'],
      profilePath: json['profile_path'],
    );
  }

  String get fullProfilePath =>
      profilePath != null
          ? 'https://image.tmdb.org/t/p/w185$profilePath'
          : '';
}

class CreditsModel {
  final List<CastModel> cast;
  final List<CrewModel> crew;

  CreditsModel({required this.cast, required this.crew});

  factory CreditsModel.fromJson(Map<String, dynamic> json) {
    return CreditsModel(
      cast: (json['cast'] as List?)
              ?.map((e) => CastModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      crew: (json['crew'] as List?)
              ?.map((e) => CrewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  List<CrewModel> get directors =>
      crew.where((c) => c.job == 'Director').toList();

  List<CrewModel> get writers =>
      crew.where((c) => c.department == 'Writing').toList();
}

// ── Movie Videos (trailers etc.) ──

class MovieVideoModel {
  final String? key;
  final String? name;
  final String? site;
  final String? type;
  final bool? official;

  MovieVideoModel({
    this.key,
    this.name,
    this.site,
    this.type,
    this.official,
  });

  factory MovieVideoModel.fromJson(Map<String, dynamic> json) {
    return MovieVideoModel(
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

// ── Person Detail ──

class PersonDetailModel {
  final int id;
  final String? name;
  final String? biography;
  final String? birthday;
  final String? deathday;
  final String? placeOfBirth;
  final String? profilePath;
  final String? knownForDepartment;
  final double? popularity;
  final String? homepage;
  final List<String>? alsoKnownAs;
  final int? gender;

  PersonDetailModel({
    required this.id,
    this.name,
    this.biography,
    this.birthday,
    this.deathday,
    this.placeOfBirth,
    this.profilePath,
    this.knownForDepartment,
    this.popularity,
    this.homepage,
    this.alsoKnownAs,
    this.gender,
  });

  factory PersonDetailModel.fromJson(Map<String, dynamic> json) {
    return PersonDetailModel(
      id: json['id'] ?? 0,
      name: json['name'],
      biography: json['biography'],
      birthday: json['birthday'],
      deathday: json['deathday'],
      placeOfBirth: json['place_of_birth'],
      profilePath: json['profile_path'],
      knownForDepartment: json['known_for_department'],
      popularity: (json['popularity'] as num?)?.toDouble(),
      homepage: json['homepage'],
      alsoKnownAs: (json['also_known_as'] as List?)?.cast<String>(),
      gender: json['gender'],
    );
  }

  String get fullProfilePath =>
      profilePath != null
          ? 'https://image.tmdb.org/t/p/w500$profilePath'
          : '';

  String get age {
    if (birthday == null || birthday!.isEmpty) return '';
    try {
      final birth = DateTime.parse(birthday!);
      final now = deathday != null && deathday!.isNotEmpty
          ? DateTime.parse(deathday!)
          : DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age.toString();
    } catch (_) {
      return '';
    }
  }
}

class PersonCreditsModel {
  final List<MovieModel> cast;
  final List<MovieModel> crew;

  PersonCreditsModel({required this.cast, required this.crew});

  factory PersonCreditsModel.fromJson(Map<String, dynamic> json) {
    return PersonCreditsModel(
      cast: (json['cast'] as List?)
              ?.map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      crew: (json['crew'] as List?)
              ?.map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
