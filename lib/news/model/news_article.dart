import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model representing an agricultural news article
class NewsArticle {
  final String id;
  final String title;
  final String description;
  final String content;
  final String imageUrl;
  final String category; // e.g., 'Weather', 'Market', 'Technology', 'Policy'
  final String source;
  final DateTime publishedAt;
  final List<String> tags;
  final int viewCount;
  final bool isBookmarked;

  NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.imageUrl,
    required this.category,
    required this.source,
    required this.publishedAt,
    this.tags = const [],
    this.viewCount = 0,
    this.isBookmarked = false,
  });

  /// Create NewsArticle from Firestore document
  factory NewsArticle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NewsArticle(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'General',
      source: data['source'] ?? 'Unknown',
      publishedAt:
          (data['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: List<String>.from(data['tags'] ?? []),
      viewCount: data['viewCount'] ?? 0,
      isBookmarked: data['isBookmarked'] ?? false,
    );
  }

  /// Convert NewsArticle to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'imageUrl': imageUrl,
      'category': category,
      'source': source,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'tags': tags,
      'viewCount': viewCount,
      'isBookmarked': isBookmarked,
    };
  }

  /// Create a copy with modified fields
  NewsArticle copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    String? imageUrl,
    String? category,
    String? source,
    DateTime? publishedAt,
    List<String>? tags,
    int? viewCount,
    bool? isBookmarked,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      source: source ?? this.source,
      publishedAt: publishedAt ?? this.publishedAt,
      tags: tags ?? this.tags,
      viewCount: viewCount ?? this.viewCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  /// Get category color
  Color getCategoryColor() {
    switch (category.toLowerCase()) {
      case 'weather':
        return const Color(0xFF2196F3); // Blue
      case 'market':
        return const Color(0xFF4CAF50); // Green
      case 'technology':
        return const Color(0xFF9C27B0); // Purple
      case 'policy':
        return const Color(0xFFFF9800); // Orange
      case 'crop health':
        return const Color(0xFFE91E63); // Pink
      default:
        return const Color(0xFF607D8B); // Grey
    }
  }

  /// Get category icon
  IconData getCategoryIcon() {
    switch (category.toLowerCase()) {
      case 'weather':
        return Icons.cloud;
      case 'market':
        return Icons.trending_up;
      case 'technology':
        return Icons.lightbulb;
      case 'policy':
        return Icons.gavel;
      case 'crop health':
        return Icons.eco;
      default:
        return Icons.article;
    }
  }
}
