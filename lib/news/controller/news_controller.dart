import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/news_article.dart';

/// Controller managing news feed state and business logic
class NewsController extends ChangeNotifier {
  String _selectedCategory = 'All';
  final Set<String> _bookmarkedArticles = {};
  bool _isLoading = false;
  List<NewsArticle> _cachedArticles = [];
  String? _error;

  // GNews API Configuration
  static const String _apiKey =
      '957406d6d5bd784c638befb73d058a94'; // Get from gnews.io
  static const String _baseUrl = 'https://gnews.io/api/v4';

  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Available news categories
  final List<String> categories = [
    'All',
    'Weather',
    'Market',
    'Technology',
    'Policy',
    'Crop Health',
  ];

  NewsController() {
    // Load articles on initialization
    fetchArticles();
  }

  /// Fetch articles from GNews API
  Future<void> fetchArticles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = {
        'q': 'agriculture farming crops',
        'lang': 'en',
        'country': 'in', // Focus on Indian news
        'max': '50',
        'apikey': _apiKey,
      };

      final uri = Uri.parse(
        '$_baseUrl/search',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = (data['articles'] as List)
            .map((article) => _convertToNewsArticle(article))
            .where((article) => article != null)
            .cast<NewsArticle>()
            .toList();

        _cachedArticles = articles;
        _error = null;
      } else {
        _error = 'Failed to load news. Status: ${response.statusCode}';
        _cachedArticles = _getStaticArticles();
      }
    } catch (e) {
      _error = 'Error fetching news: $e';
      _cachedArticles = _getStaticArticles();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Convert News API article to NewsArticle model
  NewsArticle? _convertToNewsArticle(Map<String, dynamic> apiArticle) {
    try {
      final title = apiArticle['title'] as String?;
      final description = apiArticle['description'] as String?;
      final content = apiArticle['content'] as String?;
      final imageUrl =
          apiArticle['image'] as String?; // GNews uses 'image' not 'urlToImage'
      final source = apiArticle['source']?['name'] as String?;
      final publishedAt = apiArticle['publishedAt'] as String?;

      // Skip articles with missing essential data
      if (title == null || title.isEmpty) return null;

      // GNews API truncates content, so combine description and content for better display
      String fullContent = '';
      if (content != null && content.isNotEmpty) {
        // Remove the truncation marker if present
        fullContent = content.replaceAll('[+', '').replaceAll(' chars]', '');
      }

      // If content is still too short, use description as well
      if (fullContent.length < 200 && description != null) {
        fullContent = description + '\n\n' + fullContent;
      }

      // If still no good content, use a placeholder
      if (fullContent.isEmpty) {
        fullContent =
            description ??
            'Full article content not available. Please visit the source for complete information.';
      }

      return NewsArticle(
        id: apiArticle['url']?.toString() ?? DateTime.now().toString(),
        title: title,
        description: description ?? 'No description available',
        content: fullContent,
        imageUrl:
            imageUrl ??
            _getDefaultImageForCategory(
              _categorizeArticle(title, description ?? ''),
            ),
        category: _categorizeArticle(title, description ?? ''),
        source: source ?? 'Unknown',
        publishedAt: publishedAt != null
            ? DateTime.parse(publishedAt)
            : DateTime.now(),
        tags: _extractTags(title, description ?? ''),
        viewCount: 0,
        isBookmarked: false,
      );
    } catch (e) {
      debugPrint('Error converting article: $e');
      return null;
    }
  }

  /// Get default image based on category (fallback when API doesn't provide image)
  String _getDefaultImageForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'weather':
        return 'https://images.unsplash.com/photo-1527482797697-8795b05a13fe?w=800&q=80';
      case 'market':
        return 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=800&q=80';
      case 'technology':
        return 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=800&q=80';
      case 'policy':
        return 'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=800&q=80';
      case 'crop health':
        return 'https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=800&q=80';
      default:
        return 'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=800&q=80';
    }
  }

  /// Categorize article based on content
  String _categorizeArticle(String title, String description) {
    final text = '$title $description'.toLowerCase();

    if (text.contains('weather') ||
        text.contains('rain') ||
        text.contains('monsoon') ||
        text.contains('climate')) {
      return 'Weather';
    } else if (text.contains('market') ||
        text.contains('price') ||
        text.contains('export') ||
        text.contains('trade')) {
      return 'Market';
    } else if (text.contains('technology') ||
        text.contains('ai') ||
        text.contains('drone') ||
        text.contains('digital')) {
      return 'Technology';
    } else if (text.contains('policy') ||
        text.contains('government') ||
        text.contains('scheme') ||
        text.contains('law')) {
      return 'Policy';
    } else if (text.contains('disease') ||
        text.contains('pest') ||
        text.contains('health') ||
        text.contains('crop protection')) {
      return 'Crop Health';
    }

    return 'Market'; // Default category
  }

  /// Extract relevant tags from article
  List<String> _extractTags(String title, String description) {
    final text = '$title $description'.toLowerCase();
    final tags = <String>[];

    final keywords = [
      'rice',
      'wheat',
      'cotton',
      'maize',
      'sugarcane',
      'farming',
      'agriculture',
      'monsoon',
      'irrigation',
      'organic',
      'export',
      'subsidy',
      'technology',
      'ai',
      'drone',
    ];

    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        tags.add(keyword);
      }
    }

    return tags.take(5).toList(); // Limit to 5 tags
  }

  /// Get articles with current filters
  List<NewsArticle> getArticles() {
    if (_selectedCategory == 'All') {
      return _cachedArticles;
    }

    return _cachedArticles
        .where((article) => article.category == _selectedCategory)
        .toList();
  }

  /// Change selected category filter
  void selectCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  /// Toggle bookmark status for an article
  void toggleBookmark(String articleId) {
    if (_bookmarkedArticles.contains(articleId)) {
      _bookmarkedArticles.remove(articleId);
    } else {
      _bookmarkedArticles.add(articleId);
    }
    notifyListeners();
  }

  /// Check if article is bookmarked
  bool isBookmarked(String articleId) {
    return _bookmarkedArticles.contains(articleId);
  }

  /// Get bookmarked articles
  List<NewsArticle> getBookmarkedArticles() {
    return _cachedArticles
        .where((article) => _bookmarkedArticles.contains(article.id))
        .toList();
  }

  /// Increment view count when article is opened
  void incrementViewCount(String articleId) {
    // In production, update this in Firebase or backend
    notifyListeners();
  }

  /// Search articles by query
  List<NewsArticle> searchArticles(String query) {
    if (query.isEmpty) return getArticles();

    final lowercaseQuery = query.toLowerCase();
    return _cachedArticles.where((article) {
      return article.title.toLowerCase().contains(lowercaseQuery) ||
          article.description.toLowerCase().contains(lowercaseQuery) ||
          article.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Refresh articles
  Future<void> refreshArticles() async {
    await fetchArticles();
  }

  /// Static articles for demo/fallback (keep existing method)
  List<NewsArticle> _getStaticArticles() {
    return [
      NewsArticle(
        id: '1',
        title: 'Monsoon Alert: Heavy Rainfall Expected in Tamil Nadu',
        description:
            'IMD predicts heavy to very heavy rainfall across Tamil Nadu for the next 48 hours. Farmers advised to take precautions.',
        content:
            '''The India Meteorological Department (IMD) has issued a heavy rainfall alert for Tamil Nadu over the next 48 hours. The cyclonic circulation over Bay of Bengal is expected to bring widespread precipitation across the region.

**Key Points:**
- Heavy to very heavy rainfall expected in Chennai, Kanchipuram, and Tiruvallur districts
- Farmers advised to postpone harvesting operations
- Ensure proper drainage in fields to prevent waterlogging
- Store harvested crops in dry, elevated areas
- Monitor weather updates regularly

**Agricultural Impact:**
The rainfall may benefit late-stage kharif crops but could damage standing paddy ready for harvest. Cotton and groundnut farmers should take immediate protective measures.

**Advisory:**
Contact your local agricultural officer for crop-specific guidance. Emergency helpline: 1800-425-1661''',
        imageUrl:
            'https://images.unsplash.com/photo-1527482797697-8795b05a13fe?w=800',
        category: 'Weather',
        source: 'IMD Chennai',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        tags: ['monsoon', 'rainfall', 'tamil nadu', 'weather alert'],
        viewCount: 1234,
      ),
      // ...existing static articles...
      NewsArticle(
        id: '2',
        title: 'Rice Prices Surge 15% in Wholesale Markets',
        description:
            'Wholesale rice prices show significant upward trend due to reduced supply and increased export demand.',
        content:
            '''Wholesale rice prices have surged by 15% in major agricultural markets across South India, with the benchmark variety touching ₹3,200 per quintal.

**Market Analysis:**
- Parboiled rice: ₹3,200/quintal (+12%)
- Raw rice: ₹2,900/quintal (+15%)
- Basmati rice: ₹8,500/quintal (+8%)

**Factors Driving Prices:**
1. Lower kharif production due to irregular monsoon
2. Increased export orders from Asian markets
3. Government procurement at higher MSP
4. Storage costs rising due to inflation

**Expert Opinion:**
Market analysts predict prices will stabilize after rabi harvest in March-April. Farmers holding stock may benefit from current high prices.

**Action for Farmers:**
Consider selling stored produce at current rates. Consult with agricultural market committees for best timing.''',
        imageUrl:
            'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=800',
        category: 'Market',
        source: 'Agricultural Market Intelligence',
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
        tags: ['rice', 'prices', 'market', 'wholesale'],
        viewCount: 892,
      ),
    ];
  }
}
