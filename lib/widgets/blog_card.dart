import 'package:flutter/material.dart';
import 'dart:io';
import '../models/blog.dart';
import 'package:intl/intl.dart';

class BlogCard extends StatelessWidget {
  final Blog blog;
  final VoidCallback onTap;
  final int? reactionCount;
  final bool? isReacted;

  const BlogCard({
    super.key,
    required this.blog,
    required this.onTap,
    this.reactionCount,
    this.isReacted,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'fr');
    final timeFormat = DateFormat('HH:mm', 'fr');

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du blog
            if (blog.imagePath != null && blog.imagePath!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: blog.imagePath != null &&
                        File(blog.imagePath!).existsSync()
                    ? Image.file(
                        File(blog.imagePath!),
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.article,
                          size: 60,
                          color: Colors.grey,
                        ),
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
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      blog.category,
                      style: const TextStyle(
                        color: Colors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Titre
                  Text(
                    blog.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Contenu (preview)
                  Text(
                    blog.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Footer avec auteur et date
                  Row(
                    children: [
                      // Photo de l'auteur
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: blog.veterinaryPhoto != null &&
                                File(blog.veterinaryPhoto!).existsSync()
                            ? FileImage(File(blog.veterinaryPhoto!))
                            : null,
                        child: blog.veterinaryPhoto == null ||
                                !File(blog.veterinaryPhoto!).existsSync()
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      // Nom de l'auteur
                      Expanded(
                        child: Text(
                          blog.veterinaryName ?? 'Vétérinaire',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // Date
                      Text(
                        '${dateFormat.format(blog.createdAt)} à ${timeFormat.format(blog.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  // Réactions
                  if (reactionCount != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(
                            isReacted == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: isReacted == true ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$reactionCount',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
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

