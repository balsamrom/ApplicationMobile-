import 'package:flutter/material.dart';
import '../models/blog.dart';
import '../models/owner.dart';
import '../db/database_helper.dart';
import '../widgets/blog_card.dart';
import 'blog_detail_screen.dart';

class BlogListScreen extends StatefulWidget {
  final Owner owner;

  const BlogListScreen({super.key, required this.owner});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  List<Blog> _allBlogs = [];
  List<Blog> _filteredBlogs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Tous';

  final List<String> _categories = [
    'Tous',
    'Santé',
    'Nutrition',
    'Comportement',
    'Soins',
    'Conseils',
    'Autres',
  ];

  @override
  void initState() {
    super.initState();
    _loadBlogs();
  }

  Future<void> _loadBlogs() async {
    setState(() => _isLoading = true);
    try {
      final blogs = await DatabaseHelper.instance.getAllBlogs();
      
      // Enrichir les blogs avec les infos du vétérinaire
      for (var blog in blogs) {
        final vet = await DatabaseHelper.instance.getOwnerById(blog.veterinaryId);
        if (vet != null) {
          blog = blog.copyWith(
            veterinaryName: vet.name,
            veterinaryPhoto: vet.photoPath,
          );
        }
      }

      setState(() {
        _allBlogs = blogs;
        _applyFilters();
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

  void _applyFilters() {
    setState(() {
      _filteredBlogs = _allBlogs.where((blog) {
        final matchesSearch = _searchQuery.isEmpty ||
            blog.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            blog.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (blog.veterinaryName ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
        final matchesCategory =
            _selectedCategory == 'Tous' || blog.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Blogs Vétérinaires',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un blog...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _applyFilters();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),

          // Filtres par catégorie
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                        _applyFilters();
                      });
                    },
                    selectedColor: Colors.teal.withOpacity(0.3),
                    checkmarkColor: Colors.teal,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Liste des blogs
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBlogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty ||
                                      _selectedCategory != 'Tous'
                                  ? 'Aucun blog trouvé'
                                  : 'Aucun blog disponible',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBlogs,
                        child: ListView.builder(
                          itemCount: _filteredBlogs.length,
                          itemBuilder: (context, index) {
                            final blog = _filteredBlogs[index];
                            return FutureBuilder<int>(
                              future: DatabaseHelper.instance
                                  .getBlogReactionCount(blog.id!),
                              builder: (context, snapshot) {
                                final reactionCount = snapshot.data ?? 0;
                                return FutureBuilder<bool>(
                                  future: DatabaseHelper.instance.hasUserReacted(
                                    blog.id!,
                                    widget.owner.id!,
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
                                              owner: widget.owner,
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
                      ),
          ),
        ],
      ),
    );
  }
}

