class FormattedTextModel {
  final String type; // "html", "markdown", "plain"
  final String content;

  FormattedTextModel({
    required this.type,
    required this.content,
  });

  factory FormattedTextModel.fromJson(Map<String, dynamic> json) {
    // Handle sealed class format from Kotlin
    if (json.containsKey('html')) {
      return FormattedTextModel(
        type: 'html',
        content: json['html']['content'] ?? '',
      );
    } else if (json.containsKey('markdown')) {
      return FormattedTextModel(
        type: 'markdown',
        content: json['markdown']['content'] ?? '',
      );
    } else if (json.containsKey('plain')) {
      return FormattedTextModel(
        type: 'plain',
        content: json['plain']['content'] ?? '',
      );
    }
    // Fallback for simple string format
    return FormattedTextModel(
      type: 'plain',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'content': content,
    };
  }
}
