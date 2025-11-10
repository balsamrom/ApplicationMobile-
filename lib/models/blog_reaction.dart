class BlogReaction {
  final int? id;
  final int blogId;
  final int userId;
  final String reactionType; // 'like', 'love', 'helpful', etc.
  final DateTime createdAt;

  BlogReaction({
    this.id,
    required this.blogId,
    required this.userId,
    required this.reactionType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'blogId': blogId,
      'userId': userId,
      'reactionType': reactionType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BlogReaction.fromMap(Map<String, dynamic> map) {
    return BlogReaction(
      id: map['id'] as int?,
      blogId: map['blogId'] as int,
      userId: map['userId'] as int,
      reactionType: map['reactionType'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  BlogReaction copyWith({
    int? id,
    int? blogId,
    int? userId,
    String? reactionType,
    DateTime? createdAt,
  }) {
    return BlogReaction(
      id: id ?? this.id,
      blogId: blogId ?? this.blogId,
      userId: userId ?? this.userId,
      reactionType: reactionType ?? this.reactionType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

