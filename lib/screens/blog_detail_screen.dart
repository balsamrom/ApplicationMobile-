import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/blog.dart';
import '../models/owner.dart';
import '../models/blog_reaction.dart';
import '../db/database_helper.dart';
import 'veterinary/veterinary_detail_screen.dart';

class BlogDetailScreen extends StatefulWidget {
  final Blog blog;
  final Owner owner;

  const BlogDetailScreen({
    super.key,
    required this.blog,
    required this.owner,
  });

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  bool _isReacted = false;
  int _reactionCount = 0;
  Owner? _veterinary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final hasReacted = await DatabaseHelper.instance.hasUserReacted(
        widget.blog.id!,
        widget.owner.id!,
      );
      final count = await DatabaseHelper.instance.getBlogReactionCount(
        widget.blog.id!,
      );
      final vet = await DatabaseHelper.instance.getOwnerById(
        widget.blog.veterinaryId,
      );

      setState(() {
        _isReacted = hasReacted;
        _reactionCount = count;
        _veterinary = vet;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement données: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleReaction() async {
    try {
      if (_isReacted) {
        await DatabaseHelper.instance.removeBlogReaction(
          widget.blog.id!,
          widget.owner.id!,
        );
        setState(() {
          _isReacted = false;
          _reactionCount = _reactionCount > 0 ? _reactionCount - 1 : 0;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réaction retirée'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        final reaction = BlogReaction(
          blogId: widget.blog.id!,
          userId: widget.owner.id!,
          reactionType: 'like',
          createdAt: DateTime.now(),
        );
        await DatabaseHelper.instance.addBlogReaction(reaction);
        setState(() {
          _isReacted = true;
          _reactionCount++;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❤️ Vous avez aimé ce blog'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur réaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _contactVeterinary() async {
    if (_veterinary == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: _veterinary!.photoPath != null &&
                          File(_veterinary!.photoPath!).existsSync()
                      ? FileImage(File(_veterinary!.photoPath!))
                      : null,
                  child: _veterinary!.photoPath == null ||
                          !File(_veterinary!.photoPath!).existsSync()
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${_veterinary!.name}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_veterinary!.email != null)
                        Text(
                          _veterinary!.email!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_veterinary!.phone != null && _veterinary!.phone!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.teal),
                title: const Text('Appeler'),
                subtitle: Text(_veterinary!.phone!),
                onTap: () async {
                  final uri = Uri.parse('tel:${_veterinary!.phone}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                  Navigator.pop(context);
                },
              ),
            if (_veterinary!.email != null && _veterinary!.email!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.email, color: Colors.teal),
                title: const Text('Envoyer un email'),
                subtitle: Text(_veterinary!.email!),
                onTap: () async {
                  final uri = Uri.parse('mailto:${_veterinary!.email}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.teal),
              title: const Text('Voir le profil complet'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VeterinaryDetailScreen(
                      veterinary: _veterinary!,
                      owner: widget.owner,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Blog',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (widget.blog.imagePath != null &&
                widget.blog.imagePath!.isNotEmpty)
              widget.blog.imagePath != null &&
                      File(widget.blog.imagePath!).existsSync()
                  ? Image.file(
                      File(widget.blog.imagePath!),
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.article,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Catégorie
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.blog.category,
                      style: const TextStyle(
                        color: Colors.teal,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Titre
                  Text(
                    widget.blog.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Auteur et date
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: widget.blog.veterinaryPhoto != null &&
                                File(widget.blog.veterinaryPhoto!).existsSync()
                            ? FileImage(File(widget.blog.veterinaryPhoto!))
                            : null,
                        child: widget.blog.veterinaryPhoto == null ||
                                !File(widget.blog.veterinaryPhoto!).existsSync()
                            ? const Icon(Icons.person, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.blog.veterinaryName ?? 'Vétérinaire',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${dateFormat.format(widget.blog.createdAt)} à ${timeFormat.format(widget.blog.createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Contenu
                  Text(
                    widget.blog.content,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  Row(
                    children: [
                      // Réaction
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleReaction,
                          icon: Icon(
                            _isReacted ? Icons.favorite : Icons.favorite_border,
                            color: _isReacted ? Colors.red : Colors.white,
                          ),
                          label: Text(
                            '$_reactionCount',
                            style: TextStyle(
                              color: _isReacted ? Colors.red : Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isReacted ? Colors.red[50] : Colors.teal,
                            foregroundColor:
                                _isReacted ? Colors.red : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Contacter
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _contactVeterinary,
                          icon: const Icon(Icons.contact_mail),
                          label: const Text('Contacter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

