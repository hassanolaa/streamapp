class IptvCountryModel {
  final String name;
  final String code;
  final List<String> languages;
  final String flag;

  const IptvCountryModel({
    required this.name,
    required this.code,
    this.languages = const [],
    required this.flag,
  });

  factory IptvCountryModel.fromJson(Map<String, dynamic> json) {
    return IptvCountryModel(
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      languages: (json['languages'] as List<dynamic>?)?.cast<String>() ?? [],
      flag: json['flag'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'languages': languages,
      'flag': flag,
    };
  }

  @override
  String toString() => 'IptvCountryModel(name: $name, code: $code, flag: $flag)';
}
