import 'package:streamapp/features/videos/data/models/items_model.dart';

class SearchResultModel {
  final ItemsModel items;
  final String? suggestion;
  final bool? isCorrected;

  SearchResultModel({
    required this.items,
    this.suggestion,
    this.isCorrected,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      items: ItemsModel.fromJson(json['items']),
      suggestion: json['suggestion'],
      isCorrected: json['isCorrected'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.toJson(),
      'suggestion': suggestion,
      'isCorrected': isCorrected,
    };
  }
}
