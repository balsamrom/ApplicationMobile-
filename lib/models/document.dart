class DocumentItem {
  int? id;
  int ownerId;
  int? petId;
  String title;
  String filePath;

  DocumentItem({this.id, required this.ownerId, this.petId, required this.title, required this.filePath});

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerId': ownerId,
        'petId': petId,
        'title': title,
        'filePath': filePath,
      };

  factory DocumentItem.fromMap(Map<String, dynamic> m) => DocumentItem(
        id: m['id'] as int?,
        ownerId: m['ownerId'] as int,
        petId: m['petId'] as int?,
        title: m['title'] as String,
        filePath: m['filePath'] as String,
      );
}
