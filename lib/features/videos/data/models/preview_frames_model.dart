class PreviewFramesModel {
  final List<String> pagesUrls;
  final int frameWidth;
  final int frameHeight;
  final int framesCount;
  final int durationPerFrame;
  final int framesPerPageX;
  final int framesPerPageY;

  PreviewFramesModel({
    required this.pagesUrls,
    required this.frameWidth,
    required this.frameHeight,
    required this.framesCount,
    required this.durationPerFrame,
    required this.framesPerPageX,
    required this.framesPerPageY,
  });

  factory PreviewFramesModel.fromJson(Map<String, dynamic> json) {
    return PreviewFramesModel(
      pagesUrls: List<String>.from(json['pagesUrls'] ?? []),
      frameWidth: json['frameWidth'] ?? 0,
      frameHeight: json['frameHeight'] ?? 0,
      framesCount: json['framesCount'] ?? 0,
      durationPerFrame: json['durationPerFrame'] ?? 0,
      framesPerPageX: json['framesPerPageX'] ?? 0,
      framesPerPageY: json['framesPerPageY'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pagesUrls': pagesUrls,
      'frameWidth': frameWidth,
      'frameHeight': frameHeight,
      'framesCount': framesCount,
      'durationPerFrame': durationPerFrame,
      'framesPerPageX': framesPerPageX,
      'framesPerPageY': framesPerPageY,
    };
  }
}
