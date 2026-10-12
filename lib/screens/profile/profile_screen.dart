import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/language_service.dart';
import '../../theme/app_theme.dart';

import 'my_feedback_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  bool _isUploading = false;

  Future<void> _updateProfilePic(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 50);
    
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // We use the same Base64 method to stay on the free plan
        String base64Image = await _storageService.uploadImage(File(image.path), 'profile_pics');
        
        if (base64Image.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'photoUrl': base64Image,
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture updated!")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImageSourceOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt, color: theme.colorScheme.primary),
            title: const Text("Take a Photo"),
            onTap: () {
              Navigator.pop(context);
              _updateProfilePic(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library, color: theme.colorScheme.primary),
            title: const Text("Choose from Gallery"),
            onTap: () {
              Navigator.pop(context);
              _updateProfilePic(ImageSource.gallery);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<User?>(context);
    final langService = Provider.of<LanguageService>(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(langService.translate('my_profile')),
        backgroundColor: isDark ? Colors.transparent : theme.primaryColor,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final String photoUrl = userData?['photoUrl'] ?? "";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: theme.colorScheme.primary,
                      child: CircleAvatar(
                        radius: 62,
                        backgroundColor: theme.cardColor,
                        backgroundImage: _getProfileImage(photoUrl),
                        child: photoUrl.isEmpty ? Icon(Icons.person, size: 60, color: theme.colorScheme.secondary) : null,
                      ),
                    ),
                    if (_isUploading)
                      Positioned.fill(child: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceOptions,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: theme.colorScheme.primary,
                          child: Icon(Icons.camera_alt, size: 18, color: theme.colorScheme.onPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  userData?['name'] ?? "User",
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                ),
                if (userData?['role'] == 'admin')
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(20)),
                    child: Text("ADMINISTRATOR", style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                const SizedBox(height: 8),
                Text(userData?['email'] ?? "", style: theme.textTheme.bodyMedium),
                Divider(height: 60, color: isDark ? Colors.white10 : Colors.black12),
                
                _buildProfileItem(Icons.analytics_outlined, langService.translate('total_scans'), "${userData?['totalScans'] ?? 0}", theme),
                _buildProfileItem(Icons.calendar_month_outlined, langService.translate('member_since'), _formatDate(userData?['createdAt'], langService.dateLocale), theme),
                
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyFeedbackScreen())),
                  child: _buildProfileItem(
                    Icons.history_edu_outlined, 
                    langService.translate('my_feedback'), 
                    "",
                    theme,
                  ),
                ),

                GestureDetector(
                  onTap: () => _showLanguageDialog(context, langService),
                  child: _buildProfileItem(
                    Icons.language, 
                    langService.translate('language'), 
                    langService.translate('lang_${langService.currentLanguage.name}'),
                    theme,
                  ),
                ),

                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _showEditName(context, userData?['name']),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: Text(langService.translate('edit_name').toUpperCase()),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _showFeedbackDialog(context, langService),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                  ),
                  child: Text(langService.translate('send_feedback').toUpperCase()),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.read<AuthService>().signOut(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: Text(langService.translate('logout').toUpperCase()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  ImageProvider? _getProfileImage(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      final base64String = url.split(',').last;
      return MemoryImage(base64Decode(base64String));
    }
    return NetworkImage(url);
  }

  String _formatDate(dynamic date, String locale) {
    if (date == null) return "N/A";
    if (date is Timestamp) return DateFormat.yMMMd(locale).format(date.toDate());
    return "N/A";
  }

  Widget _buildProfileItem(IconData icon, String label, String value, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: theme.cardColor, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))
      ),
      child: Row(
        children: [
          Text(
            label.toUpperCase(), 
            style: TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.w900, 
              color: isDark ? AppTheme.sageGreen : Colors.black54,
              letterSpacing: 1.2
            )
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (value.isEmpty) Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.primary.withOpacity(0.5)),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, LanguageService lang) {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: theme.cardColor,
            title: Text(lang.translate('send_feedback')),
            content: TextField(
              controller: controller,
              maxLines: 4,
              enabled: !isSending,
              style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: lang.translate('feedback_hint'),
                hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.pop(context), 
                child: Text(lang.translate('cancel'), style: TextStyle(color: theme.colorScheme.secondary))
              ),
              ElevatedButton(
                onPressed: isSending ? null : () async {
                  if (controller.text.trim().isEmpty) return;
                  
                  setDialogState(() => isSending = true);
                  
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) throw "You must be logged in to send feedback.";

                    await FirebaseFirestore.instance.collection('user_feedback').add({
                      'type': 'user_feedback',
                      'userId': user.uid,
                      'userName': user.displayName ?? "Anonymous",
                      'userEmail': user.email ?? "N/A",
                      'message': controller.text.trim(),
                      'timestamp': FieldValue.serverTimestamp(),
                      'status': 'pending',
                    });
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(lang.translate('feedback_sent')))
                      );
                    }
                  } catch (e) {
                    setDialogState(() => isSending = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e"))
                    );
                  }
                },
                child: isSending 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(lang.translate('submit')),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageService langService) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(langService.translate('select_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption(context, langService, AppLanguage.english, "English", theme),
            _languageOption(context, langService, AppLanguage.urdu, "اردو (Urdu)", theme),
            _languageOption(context, langService, AppLanguage.punjabi, "پنجابی (Punjabi)", theme),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(BuildContext context, LanguageService langService, AppLanguage lang, String label, ThemeData theme) {
    final isSelected = langService.currentLanguage == lang;
    return ListTile(
      title: Text(label, style: TextStyle(color: isSelected ? theme.colorScheme.primary : null, fontWeight: isSelected ? FontWeight.bold : null)),
      trailing: isSelected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
      onTap: () {
        langService.setLanguage(lang);
        Navigator.pop(context);
      },
    );
  }

  void _showEditName(BuildContext context, String? currentName) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: const Text("Update Name"),
        content: TextField(
          controller: controller, 
          style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87),
          decoration: const InputDecoration(labelText: "Full Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: TextStyle(color: theme.colorScheme.secondary))),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'name': controller.text});
                Navigator.pop(context);
              }
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }
}
