class IptvChannelModel {
  final String id;
  final String name;
  final List<String> altNames;
  final String? network;
  final List<String> owners;
  final String? country;
  final List<String> categories;
  final bool isNsfw;
  final String? launched;
  final String? closed;
  final String? replacedBy;
  final String? website;

  const IptvChannelModel({
    required this.id,
    required this.name,
    this.altNames = const [],
    this.network,
    this.owners = const [],
    this.country,
    this.categories = const [],
    this.isNsfw = false,
    this.launched,
    this.closed,
    this.replacedBy,
    this.website,
  });

  factory IptvChannelModel.fromJson(Map<String, dynamic> json) {
    return IptvChannelModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      altNames: (json['alt_names'] as List<dynamic>?)?.cast<String>() ?? [],
      network: json['network'] as String?,
      owners: (json['owners'] as List<dynamic>?)?.cast<String>() ?? [],
      country: json['country'] as String?,
      categories: (json['categories'] as List<dynamic>?)?.cast<String>() ?? [],
      isNsfw: json['is_nsfw'] as bool? ?? false,
      launched: json['launched'] as String?,
      closed: json['closed'] as String?,
      replacedBy: json['replaced_by'] as String?,
      website: json['website'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'alt_names': altNames,
      'network': network,
      'owners': owners,
      'country': country,
      'categories': categories,
      'is_nsfw': isNsfw,
      'launched': launched,
      'closed': closed,
      'replaced_by': replacedBy,
      'website': website,
    };
  }

  bool get isActive => closed == null || closed!.isEmpty;

  @override
  String toString() => 'IptvChannelModel(id: $id, name: $name, country: $country)';
}
