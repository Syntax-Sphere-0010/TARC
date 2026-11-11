class Moment {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final DateTime date;
  final String note;

  const Moment({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'imageUrl': imageUrl,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Moment.fromMap(Map<String, dynamic> map) {
    return Moment(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String? ?? 'General',
      imageUrl: map['imageUrl'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String? ?? '',
    );
  }

  Moment copyWith({
    String? id,
    String? title,
    String? category,
    String? imageUrl,
    DateTime? date,
    String? note,
  }) {
    return Moment(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
