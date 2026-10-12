import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/news_service.dart';
import '../theme/app_theme.dart';
import '../services/language_service.dart';
import '../screens/home/market_hub_screen.dart';

class AgriUpdatesWidget extends StatefulWidget {
  const AgriUpdatesWidget({super.key});

  @override
  State<AgriUpdatesWidget> createState() => _AgriUpdatesWidgetState();
}

class _AgriUpdatesWidgetState extends State<AgriUpdatesWidget> {
  final NewsService _newsService = NewsService();
  String _topHeadline = "";
  String _latestPrice = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreviewData();
  }

  Future<void> _loadPreviewData() async {
    try {
      final articles = await _newsService.fetchAgriNews();
      final prices = await _newsService.fetchMandiPrices();
      if (mounted) {
        setState(() {
          if (articles.isNotEmpty) _topHeadline = articles[0].title;
          if (prices.isNotEmpty) _latestPrice = "${prices[0].market}: ${prices[0].pricePerKg}";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageService>(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MarketHubScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.trending_up, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.translate('market_updates'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _topHeadline.isNotEmpty ? _topHeadline : _latestPrice,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.primary.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
