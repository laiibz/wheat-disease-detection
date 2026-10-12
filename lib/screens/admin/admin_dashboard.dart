import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/botanical_background.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'manage_users_screen.dart';
import 'manage_posts_screen.dart';
import 'all_scans_screen.dart';
import 'system_alerts_screen.dart';
import 'manage_prices_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Command Center"),
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
            onPressed: () => context.read<AuthService>().signOut(),
          )
        ],
      ),
      body: BotanicalBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildStatsGrid(),
              const SizedBox(height: 40),
              const Text(
                "SYSTEM MANAGEMENT",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.sageGreen, letterSpacing: 1.5),
              ),
              const SizedBox(height: 20),
              _buildModernMenuCard(
                context,
                title: "User Registry",
                subtitle: "Manage accounts, roles and permissions",
                icon: Icons.people_outline,
                color: Colors.blueAccent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
              ),
              _buildModernMenuCard(
                context,
                title: "Community Moderation",
                subtitle: "Monitor and manage public discussions",
                icon: Icons.forum_outlined,
                color: Colors.orangeAccent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePostsScreen())),
              ),
              _buildModernMenuCard(
                context,
                title: "Global Analytics",
                subtitle: "Detailed report of all diagnosis events",
                icon: Icons.analytics_outlined,
                color: Colors.greenAccent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllScansScreen())),
              ),
              _buildModernMenuCard(
                context,
                title: "Market Prices",
                subtitle: "Update city-wise wheat rates",
                icon: Icons.currency_exchange,
                color: AppTheme.goldAccent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePricesScreen())),
              ),
              _buildModernMenuCard(
                context,
                title: "System Alerts",
                subtitle: "Flagged content and user feedback",
                icon: Icons.notifications_active_outlined,
                color: Colors.redAccent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemAlertsScreen())),
              ),
              const SizedBox(height: 40),
              _buildSystemInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("System Overview", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Container(width: 60, height: 4, decoration: BoxDecoration(color: AppTheme.goldAccent, borderRadius: BorderRadius.circular(2))),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.25, // Adjusted for more height
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _StatBox(
          label: "TOTAL USERS",
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          icon: Icons.person_add_alt_1,
          color: Colors.blue,
        ),
        _StatBox(
          label: "POSTS",
          stream: FirebaseFirestore.instance.collection('community_posts').snapshots(),
          icon: Icons.chat_outlined,
          color: Colors.orange,
        ),
        _StatBox(
          label: "DIAGNOSES",
          stream: FirebaseFirestore.instance.collectionGroup('scan_history').snapshots(),
          icon: Icons.biotech_outlined,
          color: Colors.green,
        ),
        _StatBox(
          label: "SYSTEM ALERTS",
          stream: FirebaseFirestore.instance.collection('user_feedback').where('status', isEqualTo: 'pending').snapshots(),
          icon: Icons.notifications_none,
          color: Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildModernMenuCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.goldAccent.withOpacity(0.8), size: 24),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.sageGreen)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: AppTheme.goldAccent),
          SizedBox(width: 8),
          Text("Admin Protocol v1.0.4 - Secure Connection", style: TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final Stream<QuerySnapshot>? stream;
  final String? countOverride;
  final IconData icon;
  final Color color;

  const _StatBox({required this.label, this.stream, this.countOverride, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stream != null)
            StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return Text(count.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white));
              },
            )
          else
            Text(countOverride ?? "0", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.sageGreen, letterSpacing: 1.2)),
        ],
      ),
    );
  }
}
