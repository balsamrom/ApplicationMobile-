import 'package:flutter/material.dart';
import '../../models/blog.dart';
import '../../models/owner.dart';
import '../../db/database_helper.dart';
import '../../widgets/blog_card.dart';
import 'create_edit_blog_screen.dart';
import '../blog_detail_screen.dart';

class VetBlogManagementScreen extends StatefulWidget {
  final Owner vet;

  const VetBlogManagementScreen({super.key, required this.vet});

  @override
  State<VetBlogManagementScreen> createState() =>
      _VetBlogManagementScreenState();
}

class _VetBlogManagementScreenState extends State<VetBlogManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Blog> _myBlogs = [];
  List<Blog> _allBlogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBlogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBlogs() async {
    setState(() => _isLoading = true);
    try {
      final myBlogs = await DatabaseHelper.instance
          .getBlogsByVeterinary(widget.vet.id!);
      final allBlogs = await DatabaseHelper.instance.getAllBlogs();

      // Enrichir les blogs avec les infos du vétérinaire
      for (var blog in myBlogs) {
        final vet = await DatabaseHelper.instance.getOwnerById(blog.veterinaryId);
        if (vet != null) {
          blog = blog.copyWith(
            veterinaryName: vet.name,
            veterinaryPhoto: vet.photoPath,
          );
        }
      }

      for (var blog in allBlogs) {
        final vet = await DatabaseHelper.instance.getOwnerById(blog.veterinaryId);
        if (vet != null) {
          blog = blog.copyWith(
            veterinaryName: vet.name,
            veterinaryPhoto: vet.photoPath,
          );
        }
      }

      setState(() {
        _myBlogs = myBlogs;
        _allBlogs = allBlogs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement blogs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _deleteBlog(Blog blog) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le blog'),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer ce blog ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseHelper.instance.deleteBlog(blog.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Blog supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          _loadBlogs();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestion des Blogs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.article), text: 'Mes Blogs'),
            Tab(icon: Icon(Icons.library_books), text: 'Tous les Blogs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Mes Blogs
          _buildMyBlogsTab(),
          // Tous les Blogs
          _buildAllBlogsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateEditBlogScreen(vet: widget.vet),
            ),
          );
          if (result == true) {
            _loadBlogs();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Blog'),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildMyBlogsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myBlogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Vous n\'avez pas encore créé de blog',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur le bouton + pour créer votre premier blog',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBlogs,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _myBlogs.length,
        itemBuilder: (context, index) {
          final blog = _myBlogs[index];
          return FutureBuilder<int>(
            future: DatabaseHelper.instance.getBlogReactionCount(blog.id!),
            builder: (context, snapshot) {
              final reactionCount = snapshot.data ?? 0;
              return Dismissible(
                key: Key('blog_${blog.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                confirmDismiss: (direction) async {
                  await _deleteBlog(blog);
                  return false; // Already handled in _deleteBlog
                },
                child: Stack(
                  children: [
                    BlogCard(
                      blog: blog,
                      reactionCount: reactionCount,
                      isReacted: false,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlogDetailScreen(
                              blog: blog,
                              owner: widget.vet,
                            ),
                          ),
                        );
                        if (result == true) {
                          _loadBlogs();
                        }
                      },
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreateEditBlogScreen(
                                    vet: widget.vet,
                                    blog: blog,
                                  ),
                                ),
                              );
                              if (result == true) {
                                _loadBlogs();
                              }
                            },
                            tooltip: 'Modifier',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAllBlogsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allBlogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun blog disponible',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBlogs,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _allBlogs.length,
        itemBuilder: (context, index) {
          final blog = _allBlogs[index];
          return FutureBuilder<int>(
            future: DatabaseHelper.instance.getBlogReactionCount(blog.id!),
            builder: (context, snapshot) {
              final reactionCount = snapshot.data ?? 0;
              return FutureBuilder<bool>(
                future: DatabaseHelper.instance.hasUserReacted(
                  blog.id!,
                  widget.vet.id!,
                ),
                builder: (context, snapshot2) {
                  final isReacted = snapshot2.data ?? false;
                  return BlogCard(
                    blog: blog,
                    reactionCount: reactionCount,
                    isReacted: isReacted,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlogDetailScreen(
                            blog: blog,
                            owner: widget.vet,
                          ),
                        ),
                      );
                      _loadBlogs(); // Refresh reactions
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

