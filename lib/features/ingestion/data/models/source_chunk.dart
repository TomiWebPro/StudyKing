class SourceChunk {
  final int chunkIndex;
  final int? pageStart;
  final int? pageEnd;
  final String text;
  final String? heading;

  SourceChunk({
    required this.chunkIndex,
    this.pageStart,
    this.pageEnd,
    required this.text,
    this.heading,
  });

  Map<String, dynamic> toJson() => {
    'chunkIndex': chunkIndex,
    'pageStart': pageStart,
    'pageEnd': pageEnd,
    'text': text,
    'heading': heading,
  };

  factory SourceChunk.fromJson(Map<String, dynamic> json) => SourceChunk(
    chunkIndex: json['chunkIndex'] as int,
    pageStart: json['pageStart'] as int?,
    pageEnd: json['pageEnd'] as int?,
    text: json['text'] as String? ?? '',
    heading: json['heading'] as String?,
  );
}
