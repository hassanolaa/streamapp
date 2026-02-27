import 'package:equatable/equatable.dart';
import 'package:streamapp/features/iptv/data/models/iptv_country_model.dart';
import 'package:streamapp/features/iptv/data/models/iptv_enriched_channel.dart';

abstract class IptvState extends Equatable {
  @override
  List<Object?> get props => [];
}

class IptvInitial extends IptvState {}

class IptvLoading extends IptvState {}

class IptvCatalogsLoaded extends IptvState {
  /// Channels grouped by country code.
  final Map<String, List<IptvEnrichedChannel>> channelsByCountry;

  /// All countries metadata (for flag/name lookup).
  final List<IptvCountryModel> countries;

  IptvCatalogsLoaded({
    required this.channelsByCountry,
    required this.countries,
  });

  @override
  List<Object?> get props => [channelsByCountry, countries];
}

class IptvSearchSuccess extends IptvState {
  final List<IptvEnrichedChannel> results;
  final String query;

  IptvSearchSuccess({required this.results, required this.query});

  @override
  List<Object?> get props => [results, query];
}

class IptvError extends IptvState {
  final String message;

  IptvError(this.message);

  @override
  List<Object?> get props => [message];
}
