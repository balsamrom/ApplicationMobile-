class Blog {
  final int? id;
  final int veterinaryId;
  final String title;
  final String content;
  final String? imagePath;
  final String category;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? veterinaryName;
  final String? veterinaryPhoto;

  Blog({
    this.id,
    required this.veterinaryId,
    required this.title,
    required this.content,
    this.imagePath,
    required this.category,
    required this.createdAt,
    this.updatedAt,
    this.veterinaryName,
    this.veterinaryPhoto,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'veterinaryId': veterinaryId,
      'title': title,
      'content': content,
      'imagePath': imagePath,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'veterinaryName': veterinaryName,
      'veterinaryPhoto': veterinaryPhoto,
    };
  }

  factory Blog.fromMap(Map<String, dynamic> map) {
    return Blog(
      id: map['id'] as int?,
      veterinaryId: map['veterinaryId'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      imagePath: map['imagePath'] as String?,
      category: map['category'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      veterinaryName: map['veterinaryName'] as String?,
      veterinaryPhoto: map['veterinaryPhoto'] as String?,
    );
  }

  Blog copyWith({
    int? id,
    int? veterinaryId,
    String? title,
    String? content,
    String? imagePath,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? veterinaryName,
    String? veterinaryPhoto,
  }) {
    return Blog(
      id: id ?? this.id,
      veterinaryId: veterinaryId ?? this.veterinaryId,
      title: title ?? this.title,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      veterinaryName: veterinaryName ?? this.veterinaryName,
      veterinaryPhoto: veterinaryPhoto ?? this.veterinaryPhoto,
    );
  }
}

