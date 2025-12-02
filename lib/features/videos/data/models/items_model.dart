import 'package:streamapp/features/videos/data/models/summary_model.dart';

class ItemsModel {
  final List<SummaryModel> items;
  final String? nextPageToken;

  ItemsModel({
    required this.items,
    this.nextPageToken,
  });

  factory ItemsModel.fromJson(Map<String, dynamic> json) {
    return ItemsModel(
      items: (json['items'] as List?)
              ?.map((e) => SummaryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nextPageToken: json['nextPageToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'nextPageToken': nextPageToken,
    };
  }

  // Add this getter method
  List<SummaryModel> getSummaries() => items;
}
