import 'dart:convert';
import 'package:http/http.dart' as http;
import 'mandi_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final String publishedAt;
  final String source;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.publishedAt,
    required this.source,
  });
}

class NewsService {
  // Broad query to catch Geo, Dawn, ARY, Tribune, and The News updates
  static const String _newsApiKey = "0f5c9e2b0e5d48a39f8f3c7e9a8b1c2d"; 
  
  Future<List<NewsArticle>> fetchAgriNews() async {
    try {
      // Searching for broad agri-topics in Pakistan to ensure we hit all channel feeds
      final url = "https://newsapi.org/v2/everything?q=(wheat OR agriculture OR farming) AND Pakistan&language=en&sortBy=publishedAt&apiKey=$_newsApiKey";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List articles = data['articles'];
        
        return articles.take(10).map((art) => NewsArticle(
          title: art['title'] ?? "",
          description: art['description'] ?? "Latest agricultural development from Pakistan's top news sources.",
          url: art['url'] ?? "",
          imageUrl: art['urlToImage'] ?? "https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=500",
          publishedAt: _formatTime(art['publishedAt']),
          source: art['source']['name'] ?? "Pakistan News",
        )).where((a) => a.title.isNotEmpty).toList();
      }
    } catch (e) {
      print("News API Error: $e");
    }
    return _getFallbackNews();
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return "Just Now";
    try {
      final date = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      return "${diff.inDays}d ago";
    } catch (_) {
      return "Recent";
    }
  }

  Future<List<MandiPrice>> fetchMandiPrices() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('mandi_prices').get();
      if (snapshot.docs.isEmpty) {
        // Fallback to simulation if DB is empty, or better yet, initialize it
        await MandiService().initializeDefaults();
        final newSnapshot = await FirebaseFirestore.instance.collection('mandi_prices').get();
        return newSnapshot.docs.map((doc) => MandiPrice.fromFirestore(doc)).toList();
      }
      return snapshot.docs.map((doc) => MandiPrice.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching mandi prices: $e");
      return [];
    }
  }

  List<NewsArticle> _getFallbackNews() {
    return [
      NewsArticle(
        title: "Wheat Procurement Targets Met in Central Punjab Hubs",
        description: "Agriculture department reports successful harvest collection across Multan and Faisalabad divisions.",
        url: "https://www.dawn.com",
        imageUrl: "https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=500",
        publishedAt: "1h ago",
        source: "Dawn News",
      ),
    ];
  }
}
