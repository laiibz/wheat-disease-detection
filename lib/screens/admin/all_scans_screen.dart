import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../widgets/botanical_background.dart';
import '../../utils/disease_data.dart';

class AllScansScreen extends StatelessWidget {
  const AllScansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Global Scans")),
      body: BotanicalBackground(
        child: StreamBuilder<QuerySnapshot>(
          // Removed orderBy to avoid missing index error in collectionGroup
          stream: FirebaseFirestore.instance.collectionGroup('scan_history').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        "Database Error: ${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "This usually happens if a Firestore Index is missing. Please check your Firebase Console.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No scans found in database."));

            // Sort in memory to avoid index requirements
            final docs = List.from(snapshot.data!.docs);
            docs.sort((a, b) {
              final aT = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              final bT = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              if (aT == null) return 1;
              if (bT == null) return -1;
              return bT.compareTo(aT);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final String imageUrl = data['imageUrl'] as String? ?? "";
                final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                final String displayId = doc.id.length > 5 ? doc.id.substring(0, 5) : doc.id;

                return Card(
                  color: AppTheme.cardColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 50, height: 50,
                        child: _buildImage(imageUrl),
                      ),
                    ),
                    title: Text(data['disease'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text("${DateFormat.yMMMd().format(date)} • ID: $displayId...", style: const TextStyle(color: AppTheme.sageGreen, fontSize: 12)),
                    onTap: () => _viewDetail(context, data),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _confirmDeleteScan(BuildContext context, DocumentReference ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkBotanicalGreen,
        title: const Text("Delete Scan Record?"),
        content: const Text("This will permanently remove this diagnostic record from the user's history and global database."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              await ref.delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) return const Icon(Icons.grass, color: AppTheme.goldAccent);

    if (url.startsWith('data:image')) {
      try {
        final base64String = url.split(',').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
      } catch (_) {
        return const Icon(Icons.broken_image);
      }
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: Colors.black12, child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.redAccent),
    );
  }

  void _viewDetail(BuildContext context, Map<String, dynamic> data) {
    final imageUrl = data['imageUrl'] as String? ?? "";
    final info = DiseaseData.getInfo(data['disease'] ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: AppTheme.darkBotanicalGreen, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: _buildImage(imageUrl),
                ),
              ),
              const SizedBox(height: 24),
              Text(data['disease'] ?? "Unknown", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.goldAccent)),
              const Divider(color: Colors.white10, height: 40),
              _buildInfo("Description", info.description),
              _buildInfo("Symptoms", info.symptoms),
              _buildInfo("Treatment", info.treatment),
              _buildInfo("Prevention", info.prevention),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("CLOSE")),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white70, height: 1.4)),
        ],
      ),
    );
  }
}
