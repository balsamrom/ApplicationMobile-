import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/owner.dart';
import '../models/document.dart';
import '../db/database_helper.dart';

class DocumentScreen extends StatefulWidget {
  final Owner owner;
  const DocumentScreen({super.key, required this.owner});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  List<DocumentItem> docs = [];
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    final list = await DatabaseHelper.instance.getDocumentsForOwner(widget.owner.id!);
    setState(() => docs = list);
  }

  Future<void> _addDocument() async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final doc = DocumentItem(ownerId: widget.owner.id!, petId: null, title: 'Doc ${DateTime.now().toIso8601String()}', filePath: picked.path);
    await DatabaseHelper.instance.insertDocument(doc);
    _loadDocs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      floatingActionButton: FloatingActionButton(onPressed: _addDocument, child: const Icon(Icons.upload_file)),
      body: docs.isEmpty ? const Center(child: Text('Aucun document')) : ListView.builder(itemCount: docs.length, itemBuilder: (_, i) {
        final d = docs[i];
        return ListTile(leading: d.filePath.endsWith('.pdf') ? const Icon(Icons.picture_as_pdf) : Image.file(File(d.filePath), width: 40, height: 40, fit: BoxFit.cover), title: Text(d.title), subtitle: Text(d.petId == null ? 'Propriétaire' : 'Animal ${d.petId}'));
      }),
    );
  }
}
