import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/botanical_background.dart';
import '../../utils/disease_data.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WheatLibraryScreen extends StatefulWidget {
  const WheatLibraryScreen({super.key});

  @override
  State<WheatLibraryScreen> createState() => _WheatLibraryScreenState();
}

class _WheatLibraryScreenState extends State<WheatLibraryScreen> {
  // Model-aligned diseases
  final List<String> _diseases = [
    'Aphid',
    'Black_Rust',
    'Fusarium',
    'Leaf_Blight',
    'Smut',
    'Yellow_Rust',
    'Healthy'
  ];

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredDiseases = _diseases
        .where((d) => lang.translate(d).toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('wheat_encyclopedia')),
        centerTitle: true,
      ),
      body: BotanicalBackground(
        child: CustomScrollView(
          slivers: [
            // 1. Search & Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildGeneralInfoCard(theme, lang, isDark),
                    const SizedBox(height: 20),
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: lang.translate('search_diseases'),
                        prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Disease List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final disease = filteredDiseases[index];
                    return _buildDiseaseCard(context, disease, lang, theme, isDark);
                  },
                  childCount: filteredDiseases.length,
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard(ThemeData theme, LanguageService lang, bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: isDark 
              ? [theme.cardColor, const Color(0xFF1B3D26)] 
              : [Colors.white, const Color(0xFFF0F4F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  lang.translate('wheat_pakistan_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              lang.translate('wheat_pakistan_desc'),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const Divider(height: 30),
            _buildSmallInfo(lang.translate('popular_varieties'), lang.translate('varieties_list'), theme),
            const SizedBox(height: 12),
            _buildSmallInfo(lang.translate('critical_stages'), lang.translate('stages_desc'), theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallInfo(String title, String content, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        Text(content, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildDiseaseCard(BuildContext context, String label, LanguageService lang, ThemeData theme, bool isDark) {
    final info = DiseaseData.getInfo(label);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.eco, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(
          lang.translate(label),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageWidget(info.imageUrl),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection(lang.translate('description'), info.description, theme),
                    _buildInfoSection(lang.translate('symptoms'), info.symptoms, theme),
                    _buildInfoSection(lang.translate('timing'), info.timing, theme),
                    _buildInfoSection(lang.translate('treatment'), info.treatment, theme),
                    _buildInfoSection(lang.translate('prevention'), info.prevention, theme),
                    
                    if (label != "Healthy") ...[
                      const Divider(height: 32),
                      Text(
                        lang.translate('recommended_medicine'),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                info.medicineImageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.medication),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                info.recommendedMedicine,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildImageWidget(String url) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black12,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: url.startsWith('assets/')
          ? Image.asset(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildImageError(),
            )
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              errorWidget: (context, url, error) => _buildImageError(),
            ),
    );
  }

  Widget _buildImageError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 40),
        const SizedBox(height: 8),
        Text("Image loading...", style: TextStyle(color: Colors.white24, fontSize: 12)),
      ],
    );
  }

  Widget _buildInfoSection(String title, String content, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(content, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}
