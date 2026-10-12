import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/botanical_background.dart';
import '../chat/chat_screen.dart';
import '../../services/navigation_service.dart';
import '../../services/language_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/weather_risk_widget.dart';
import '../../widgets/agri_updates_widget.dart';
import '../tools/field_health_card_screen.dart';
import '../tools/dosage_calculator_screen.dart';
import '../tools/wheat_library_screen.dart';
import '../tools/experts_list_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final navService = Provider.of<NavigationService>(context, listen: false);
    final langService = Provider.of<LanguageService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: BotanicalBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              // Refresh logic
            },
            color: theme.colorScheme.primary,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context, user, navService, langService, themeService, theme),
                  const SizedBox(height: 10),
                  if (user != null) _buildAccountStatusBanner(user.uid, theme),
                  const SizedBox(height: 24),
                  
                  _buildHeader(langService.translate('field_intel'), Icons.analytics_outlined, theme),
                  const SizedBox(height: 12),
                  const WeatherRiskWidget(),
                  const SizedBox(height: 16),
                  _buildQuickMenu(context, theme, langService),
                  const SizedBox(height: 16),
                  _buildStatsGrid(user, navService, langService, theme),
                  
                  const SizedBox(height: 32),

                  _buildHeader(langService.translate('market_updates'), Icons.newspaper_outlined, theme),
                  const SizedBox(height: 12),
                  const AgriUpdatesWidget(),
                  
                  const SizedBox(height: 32),

                  _buildSectionTitle(langService.translate('recent_insights'), () => navService.setIndex(2), langService, theme),
                  const SizedBox(height: 12),
                  _buildRecentScans(user, navService, langService, theme),
                  
                  const SizedBox(height: 32),

                  _buildSectionTitle(langService.translate('farmer_community'), () => navService.setIndex(3), langService, theme),
                  const SizedBox(height: 12),
                  _buildCommunityCard(context, navService, langService, theme),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chat_fab',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
        backgroundColor: theme.colorScheme.primary,
        elevation: 4,
        child: Icon(Icons.forum_outlined, color: theme.colorScheme.onPrimary, size: 24),
      ),
    );
  }

  Widget _buildAccountStatusBanner(String uid, ThemeData theme) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String status = data['status'] ?? 'active';
        final String message = data['adminNote'] ?? '';

        if (status == 'active') return const SizedBox.shrink();

        final isSuspended = status == 'suspended';
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSuspended ? Colors.red.withOpacity(0.08) : Colors.amber.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isSuspended ? Colors.redAccent.withOpacity(0.4) : Colors.amberAccent.withOpacity(0.4), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSuspended ? Colors.redAccent.withOpacity(0.2) : Colors.amberAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuspended ? Icons.gavel_rounded : Icons.shield_moon_rounded, 
                      color: isSuspended ? Colors.redAccent : Colors.amberAccent, 
                      size: 24
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSuspended ? "ACCOUNT RESTRICTION" : "ACCOUNT NOTICE",
                          style: TextStyle(
                            color: isSuspended ? Colors.redAccent : Colors.amberAccent, 
                            fontWeight: FontWeight.w900, 
                            fontSize: 14, 
                            letterSpacing: 2
                          ),
                        ),
                        Text(
                          isSuspended ? "Community Access Revoked" : "Professional Standard Warning",
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.white10, height: 1),
              ),
              const Text(
                "OFFICIAL COMMUNICATION:",
                style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Text(
                message.isNotEmpty ? message : "Your account activity has been flagged as inconsistent with our professional community standards. Please review the terms of service.",
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5, fontStyle: FontStyle.italic),
              ),
              if (isSuspended) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.redAccent, size: 14),
                      SizedBox(width: 8),
                      Expanded(child: Text("Interactive features are currently disabled.", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, User? user, NavigationService nav, LanguageService lang, ThemeService themeService, ThemeData theme) {
    if (user == null) return const SizedBox.shrink();
    final isDark = theme.brightness == Brightness.dark;
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        String name = user.displayName ?? "User";
        String photoUrl = "";
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['name'] ?? name;
          photoUrl = data?['photoUrl'] ?? "";
        }
        
        return Row(
          children: [
            GestureDetector(
              onTap: () => nav.setIndex(4),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary, width: 2),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.cardColor,
                  backgroundImage: _getImageProvider(photoUrl),
                  child: photoUrl.isEmpty ? Icon(Icons.person, color: theme.colorScheme.secondary) : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.translate('welcome_back'), style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? AppTheme.sageGreen : Colors.black54)),
                  Text(
                    name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : theme.colorScheme.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => themeService.toggleTheme(),
              icon: Icon(
                themeService.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                color: theme.colorScheme.primary,
              ),
              tooltip: themeService.isDarkMode ? "Sunlight Mode" : "Dark Mode",
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickMenu(BuildContext context, ThemeData theme, LanguageService lang) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _quickMenuCard(
                context,
                lang.translate('field_health_card'),
                Icons.assignment_turned_in_outlined,
                Colors.blueAccent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FieldHealthCardScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickMenuCard(
                context,
                lang.translate('dosage'),
                Icons.calculate_outlined,
                Colors.orangeAccent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DosageCalculatorScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quickMenuCard(
                context,
                lang.translate('contact_expert'),
                Icons.support_agent_outlined,
                Colors.redAccent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertsListScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickMenuCard(
                context,
                lang.translate('wheat_encyclopedia'),
                Icons.menu_book_outlined,
                AppTheme.goldAccent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WheatLibraryScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickMenuCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap, {bool isFullWidth = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primaryColor.withOpacity(0.8), size: 22),
            const SizedBox(height: 12),
            Text(
              title, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 13,
                color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: isDark ? theme.colorScheme.primary.withOpacity(0.6) : theme.colorScheme.primary.withOpacity(0.8),
        letterSpacing: 2.0,
      ),
    );
  }

  ImageProvider? _getImageProvider(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      final base64String = url.split(',').last;
      return MemoryImage(base64Decode(base64String));
    }
    return NetworkImage(url);
  }

  Widget _buildStatsGrid(User? user, NavigationService nav, LanguageService lang, ThemeData theme) {
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scan_history')
          .snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int healthy = 0;
        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
          healthy = snapshot.data!.docs.where((doc) => 
            (doc['disease'] as String).contains("Healthy")).length;
        }
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => nav.setIndex(2),
                child: _statCard(lang.translate('total_scans'), total.toString(), Icons.analytics_outlined, theme),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => nav.setIndex(2, filter: "Healthy"),
                child: _statCard(lang.translate('healthy'), healthy.toString(), Icons.verified_user_outlined, theme, color: Colors.greenAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, ThemeData theme, {Color? color}) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value, 
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 28, 
              color: isDark ? Colors.white : theme.colorScheme.primary
            )
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(), 
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.w900, 
              color: isDark ? AppTheme.sageGreen : Colors.black45,
              letterSpacing: 1.2
            )
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, VoidCallback onSeeAll, LanguageService lang, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleLarge?.copyWith(color: isDark ? Colors.white : theme.colorScheme.primary)),
        TextButton(
          onPressed: onSeeAll, 
          child: Text(
            lang.translate('see_all'), 
            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentScans(User? user, NavigationService nav, LanguageService lang, ThemeData theme) {
    if (user == null) return const SizedBox.shrink();
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scan_history')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonScans();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState(lang.translate('recent_scans_empty'), theme);
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final String imageUrl = data['imageUrl'] ?? "";
            final String diseaseName = data['disease'] ?? "Unknown";

            return GestureDetector(
              onTap: () => nav.setIndex(2),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 50,
                        height: 50,
                        color: theme.scaffoldBackgroundColor,
                        child: _buildScanImage(imageUrl),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.translate(diseaseName), 
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87
                          )
                        ),
                        Text("${((data['confidence'] ?? 0) * 100).toStringAsFixed(1)}% ${lang.translate('confidence_score')}", style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: theme.colorScheme.primary.withOpacity(0.5)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSkeletonScans() {
    return Column(
      children: List.generate(3, (index) => Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.05),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      )),
    );
  }

  Widget _buildScanImage(String url) {
    if (url.isEmpty) return const Icon(Icons.grass, color: AppTheme.goldAccent, size: 20);
    
    if (url.startsWith('data:image')) {
      try {
        final base64String = url.split(',').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
      } catch (e) {
        return const Icon(Icons.broken_image, size: 20);
      }
    }
    
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 20),
    );
  }

  Widget _buildCommunityCard(BuildContext context, NavigationService nav, LanguageService lang, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => nav.setIndex(3),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
              ? [theme.cardColor, theme.cardColor.withOpacity(0.8)]
              : [Colors.white, Colors.white.withOpacity(0.9)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.translate('farmer_community'), 
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold, 
                      color: isDark ? Colors.white : theme.colorScheme.primary
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lang.translate('join_network'), 
                    style: TextStyle(
                      color: isDark ? AppTheme.sageGreen : Colors.black54,
                      fontSize: 13
                    )
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1), style: BorderStyle.solid),
      ),
      child: Center(
        child: Text(message, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
      ),
    );
  }
}
