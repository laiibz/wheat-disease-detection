import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/botanical_background.dart';
import '../../utils/disease_data.dart';
import '../../services/language_service.dart';
import 'package:provider/provider.dart';

import 'package:cached_network_image/cached_network_image.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = "";

  Widget _imageFromData(String data) {
    if (data.isEmpty) return const Icon(Icons.grass, color: AppTheme.goldAccent);
    
    if (data.startsWith('data:image')) {
      try {
        final base64String = data.split(',').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
      } catch (e) {
        return const Icon(Icons.broken_image);
      }
    }
    
    if (data.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: data,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.black12),
        errorWidget: (context, url, error) => const Icon(Icons.broken_image),
      );
    }

    return const Icon(Icons.grass, color: AppTheme.goldAccent);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final langService = Provider.of<LanguageService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(langService.translate('analysis_history')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: () => _showClearAllConfirm(user?.uid, langService),
          )
        ],
      ),
      body: BotanicalBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: langService.translate('search_history'),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.sageGreen),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users').doc(user?.uid)
                    .collection('scan_history')
                    .orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text(langService.translate('no_history')));

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['disease'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                      final imageUrl = data['imageUrl'] as String? ?? "";
                      final String diseaseName = data['disease'] ?? "Scan";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(width: 50, height: 50, child: _imageFromData(imageUrl)),
                          ),
                          title: Text(langService.translate(diseaseName), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(DateFormat.yMMMd(langService.dateLocale).format(date), style: const TextStyle(color: AppTheme.sageGreen)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => _deleteRecord(docs[index].reference),
                          ),
                          onTap: () => _viewDetail(data, langService),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteRecord(DocumentReference ref) {
    ref.delete();
  }

  void _showClearAllConfirm(String? uid, LanguageService lang) {
    if (uid == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(lang.translate('clear_all')),
        content: Text(lang.translate('clear_all_warning')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.translate('cancel'))),
          TextButton(
            onPressed: () async {
              final collection = FirebaseFirestore.instance.collection('users').doc(uid).collection('scan_history');
              final snapshots = await collection.get();
              for (var doc in snapshots.docs) {
                await doc.reference.delete();
              }
              if (mounted) Navigator.pop(context);
            },
            child: Text(lang.translate('clear_all_btn'), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _viewDetail(Map<String, dynamic> data, LanguageService lang) {
    final theme = Theme.of(context);
    final imageUrl = data['imageUrl'] as String? ?? "";
    final String label = data['disease'] ?? "Unknown";
    final double confidence = (data['confidence'] ?? 0.0).toDouble();
    final info = DiseaseData.getInfo(label);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: theme.colorScheme.primary, width: 0.5)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: _imageFromData(imageUrl),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                lang.translate(label),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                "${lang.translate('confidence_score')}: ${(confidence * 100).toStringAsFixed(1)}%",
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: label == "Healthy" ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: label == "Healthy" ? Colors.green : Colors.red, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      label == "Healthy" ? Icons.check_circle : Icons.warning_rounded,
                      color: label == "Healthy" ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label == "Healthy" ? "STATUS: OPTIMAL HEALTH" : "STATUS: THREAT DETECTED",
                      style: TextStyle(
                        color: label == "Healthy" ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 40),
              
              _buildProfessionalInfo(lang.translate('description'), info.description, theme),
              _buildProfessionalInfo(lang.translate('symptoms'), info.symptoms, theme),
              _buildProfessionalInfo(lang.translate('treatment'), info.treatment, theme),
              _buildProfessionalInfo(lang.translate('prevention'), info.prevention, theme),
              
              if (label != "Healthy") ...[
                const Divider(height: 32),
                Text(
                  lang.translate('recommended_medicine').toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          info.medicineImageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.medication, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.recommendedMedicine,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Suggested Dosage & Application",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: Text(lang.translate('close')),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalInfo(String title, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              value,
              style: TextStyle(
                color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.9) : Colors.black87,
                height: 1.6,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
