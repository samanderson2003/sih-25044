import 'package:flutter/material.dart';
import '../model/news_article.dart';

/// Controller managing news feed state and business logic
class NewsController extends ChangeNotifier {
  String _selectedCategory = 'All';
  final Set<String> _bookmarkedArticles = {};
  bool _isLoading = false;

  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  /// Available news categories
  final List<String> categories = [
    'All',
    'Weather',
    'Market',
    'Technology',
    'Policy',
    'Crop Health',
  ];

  /// Get static news articles (replace with Firebase later)
  List<NewsArticle> getArticles() {
    final allArticles = _getStaticArticles();

    if (_selectedCategory == 'All') {
      return allArticles;
    }

    return allArticles
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
    final allArticles = _getStaticArticles();
    return allArticles
        .where((article) => _bookmarkedArticles.contains(article.id))
        .toList();
  }

  /// Increment view count when article is opened
  void incrementViewCount(String articleId) {
    // In production, update this in Firebase
    notifyListeners();
  }

  /// Search articles by query
  List<NewsArticle> searchArticles(String query) {
    if (query.isEmpty) return getArticles();

    final lowercaseQuery = query.toLowerCase();
    return _getStaticArticles().where((article) {
      return article.title.toLowerCase().contains(lowercaseQuery) ||
          article.description.toLowerCase().contains(lowercaseQuery) ||
          article.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Static articles for demo (replace with Firebase stream)
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
      NewsArticle(
        id: '3',
        title: 'AI-Powered Drone Technology Revolutionizes Pest Detection',
        description:
            'New AI drones can detect pest infestations 2 weeks earlier than manual inspection, improving crop yield by 20%.',
        content:
            '''Agricultural technology startup AgriDrone has launched an AI-powered drone system that detects pest infestations up to two weeks before they become visible to the naked eye.

**Technology Highlights:**
- Multispectral imaging with AI analysis
- Real-time pest hotspot mapping
- Mobile app integration for instant alerts
- Coverage: 50 acres per hour

**Impact on Farming:**
Early trials in Punjab and Haryana showed:
- 20% increase in crop yield
- 30% reduction in pesticide usage
- 50% faster pest detection
- Cost savings of ₹15,000 per acre

**Availability:**
Service available on rental basis at ₹500/acre. Government subsidy of 40% available under Digital Agriculture Mission.

**How to Access:**
Register at www.agridrone.in or contact local Krishi Vigyan Kendra for demonstrations.''',
        imageUrl:
            'https://images.unsplash.com/photo-1473968512647-3e447244af8f?w=800',
        category: 'Technology',
        source: 'AgriTech India',
        publishedAt: DateTime.now().subtract(const Duration(hours: 8)),
        tags: ['drone', 'ai', 'pest detection', 'technology'],
        viewCount: 2156,
      ),
      NewsArticle(
        id: '4',
        title: 'Government Announces ₹10,000 Crore Farm Insurance Scheme',
        description:
            'New comprehensive insurance covers crop damage, livestock loss, and equipment damage with 60% premium subsidy.',
        content:
            '''The Ministry of Agriculture has announced a ₹10,000 crore comprehensive farm insurance scheme providing multi-risk coverage to farmers.

**Coverage Details:**
- Crop loss due to natural calamities
- Livestock mortality
- Farm equipment damage
- Post-harvest losses
- Income protection during disasters

**Premium Subsidy:**
- Small farmers (< 2 hectares): 60% subsidy
- Medium farmers (2-4 hectares): 40% subsidy
- Large farmers (> 4 hectares): 20% subsidy

**Enrollment Process:**
1. Visit nearest Jan Seva Kendra
2. Carry Aadhaar, land records
3. Complete online form
4. Pay subsidized premium
5. Get instant policy certificate

**Claims:**
Digital claims process through mobile app. Settlement within 15 days of assessment.

**Deadline:** Enroll before January 31, 2026 for kharif season coverage.''',
        imageUrl:
            'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=800',
        category: 'Policy',
        source: 'Ministry of Agriculture',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        tags: ['insurance', 'government scheme', 'policy', 'subsidy'],
        viewCount: 3421,
      ),
      NewsArticle(
        id: '5',
        title: 'Yellow Rust Alert: Wheat Farmers in Punjab on High Alert',
        description:
            'Fungal disease yellow rust detected in several districts. Immediate preventive measures recommended.',
        content:
            '''Yellow rust (Puccinia striiformis) has been detected in wheat crops across Ludhiana, Patiala, and Sangrur districts of Punjab, raising concerns among farmers.

**Symptoms to Watch:**
- Yellow-orange pustules on leaves
- Parallel stripes pattern
- Premature leaf drying
- Reduced grain size

**Immediate Action Required:**
1. Spray recommended fungicides:
   - Propiconazole 25% EC @ 500ml/acre
   - Tebuconazole 50% + Trifloxystrobin 25% WG @ 200g/acre
2. Ensure proper drainage
3. Avoid excessive nitrogen fertilizer
4. Monitor fields every 3 days

**Prevention:**
- Use resistant varieties: HD-3086, PBW-343
- Maintain optimal plant spacing
- Remove infected plants immediately
- Follow crop rotation

**Expert Consultation:**
Contact Punjab Agricultural University helpline: 0161-240-1960

**Financial Support:**
Crop insurance claims accepted for yellow rust damage. Document damage with photos.''',
        imageUrl:
            'https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=800',
        category: 'Crop Health',
        source: 'Punjab Agricultural University',
        publishedAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        tags: ['wheat', 'disease', 'yellow rust', 'alert', 'punjab'],
        viewCount: 1876,
      ),
      NewsArticle(
        id: '6',
        title: 'Cotton Export Demand Boosts Farmer Income by 25%',
        description:
            'International demand for Indian cotton reaches 5-year high, creating opportunities for farmers.',
        content:
            '''Indian cotton exports have surged to a 5-year high, with international buyers increasing orders by 40% compared to last year, significantly boosting farmer incomes.

**Market Highlights:**
- Current price: ₹8,200/quintal (raw cotton)
- Export price: ₹9,500/quintal (premium quality)
- Major buyers: Bangladesh, China, Vietnam
- Projected growth: 15% in next quarter

**Quality Requirements for Export:**
- Fiber length: minimum 28mm
- Moisture content: below 8%
- Trash content: below 5%
- Color: bright white to light spotted

**How to Access Export Market:**
1. Register with Cotton Corporation of India
2. Get quality certification from Textiles Committee
3. Join farmer producer organizations (FPOs)
4. Contact export houses through e-NAM portal

**Success Story:**
Farmer cooperative in Vidarbha earned additional ₹12 lakhs through direct export linkage.

**Support Available:**
APEDA provides technical and financial assistance for export quality production.''',
        imageUrl:
            'https://images.unsplash.com/photo-1615460549969-36fa19521a4f?w=800',
        category: 'Market',
        source: 'Cotton Association of India',
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
        tags: ['cotton', 'export', 'market', 'prices'],
        viewCount: 1543,
      ),
    ];
  }
}
