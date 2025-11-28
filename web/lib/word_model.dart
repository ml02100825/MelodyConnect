class Word {
  final String word;
  final String pronunciation;
  final String partOfSpeech;
  final String status;
  final List<String> meanings;

  Word({
    required this.word,
    required this.pronunciation,
    required this.partOfSpeech,
    required this.status,
    required this.meanings,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      word: json['word'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      partOfSpeech: json['partOfSpeech'] ?? '',
      status: json['status'] ?? '',
      meanings: List<String>.from(json['meanings'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'pronunciation': pronunciation,
      'partOfSpeech': partOfSpeech,
      'status': status,
      'meanings': meanings,
    };
  }
}