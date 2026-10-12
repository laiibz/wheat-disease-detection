import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/news_service.dart';
import '../../services/mandi_service.dart';
import '../../theme/app_theme.dart';
import '../../services/language_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MarketHubScreen extends StatefulWidget {
  const MarketHubScreen({super.key});

  @override
  State<MarketHubScreen> createState() => _MarketHubScreenState();
}

class _MarketHubScreenState extends State<MarketHubScreen> {
  final NewsService _newsService = NewsService();
  List<NewsArticle> _articles = [];
  List<MandiPrice> _prices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final articles = await _newsService.fetchAgriNews();
      final prices = await _newsService.fetchMandiPrices();
      if (mounted) {
        setState(() {
          _articles = articles;
          _prices = prices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open news article")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageService>(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('market_updates')),
        centerTitle: true,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: theme.colorScheme.primary,
            child: CustomScrollView(
              slivers: [
                // 1. Mandi Rates Section
                SliverToBoxAdapter(
                  child: _buildSectionHeader(lang.translate('mandi_rates'), Icons.trending_up, theme),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final price = _prices[index];
                        return _buildPriceItem(price, theme, isDark);
                      },
                      childCount: _prices.length,
                    ),
                  ),
                ),

                // Spacing
                const SliverToBoxAdapter(child: SizedBox(height: 30)),

                // 2. Agri News Section
                SliverToBoxAdapter(
                  child: _buildSectionHeader(lang.translate('agri_news'), Icons.newspaper, theme),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final article = _articles[index];
                        return _buildNewsItem(article, theme, isDark);
                      },
                      childCount: _articles.length,
                    ),
                  ),
                ),
                
                // Bottom Spacing
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem(MandiPrice price, ThemeData theme, bool isDark) {
    final bool isPositive = price.change.startsWith('+');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.location_on, color: theme.colorScheme.primary, size: 18),
        ),
        title: Text(price.market, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Price per 1 KG"), // Specified as KG
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price.pricePerKg.contains("Rs.") ? price.pricePerKg : "Rs. ${price.pricePerKg}",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.primary)
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, 
                     color: isPositive ? Colors.greenAccent : Colors.redAccent, size: 12),
                const SizedBox(width: 4),
                Text(
                  price.change, 
                  style: TextStyle(
                    color: isPositive ? Colors.greenAccent : Colors.redAccent, 
                    fontSize: 12, 
                    fontWeight: FontWeight.bold
                  )
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsItem(NewsArticle article, ThemeData theme, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: isDark ? 0 : 2,
      child: InkWell(
        onTap: () => _launchUrl(article.url),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: article.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.white10),
              errorWidget: (context, url, error) => const Icon(Icons.image),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(article.source, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(article.publishedAt, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
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
