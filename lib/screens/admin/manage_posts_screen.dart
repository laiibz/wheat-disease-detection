import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/botanical_background.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ManagePostsScreen extends StatelessWidget {
  const ManagePostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Moderate Community")),
      body: BotanicalBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('community_posts').orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No posts found", style: TextStyle(color: Colors.white)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final post = snapshot.data!.docs[index];
                final data = post.data() as Map<String, dynamic>;
                final String imageUrl = data['imageUrl'] as String? ?? "";
                final String userPhoto = data['userPhoto'] as String? ?? "";

                return Card(
                  color: AppTheme.cardColor,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.sageGreen,
                          backgroundImage: _getImageProvider(userPhoto),
                          child: (data['userName'] != null && (data['userName'] as String).isNotEmpty) 
                              ? Text((data['userName'] as String)[0].toUpperCase()) 
                              : const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(data['userName'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("ID: ${post.id}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        trailing: PopupMenuButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'delete', child: Text("Delete Post", style: TextStyle(color: Colors.red))),
                          ],
                          onSelected: (value) {
                            if (value == 'delete') _deletePost(context, post.id);
                          },
                        ),
                      ),
                      if (imageUrl.isNotEmpty)
                        GestureDetector(
                          onTap: () => _showFullScreenImage(context, imageUrl),
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.black12,
                            child: _buildPostImage(imageUrl),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(data['caption'] ?? "", style: const TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  ImageProvider? _getImageProvider(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      final base64String = url.split(',').last;
      return MemoryImage(base64Decode(base64String));
    }
    return CachedNetworkImageProvider(url);
  }

  Widget _buildPostImage(String data) {
    if (data.startsWith('data:image')) {
      try {
        final base64String = data.split(',').last;
        return Image.memory(base64Decode(base64String), width: double.infinity, fit: BoxFit.cover);
      } catch (e) {
        return const Center(child: Icon(Icons.broken_image, color: Colors.red));
      }
    }
    return CachedNetworkImage(
      imageUrl: data,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: Colors.white10),
      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black.withOpacity(0.9), width: double.infinity, height: double.infinity),
            ),
            _buildPostImage(imageUrl),
            Positioned(
              top: 40, right: 20,
              child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePost(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkBotanicalGreen,
        title: const Text("Permanently Delete?"),
        content: const Text("This will remove the post from the community forever."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('community_posts').doc(postId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
