import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/storage_service.dart';
import '../../widgets/botanical_background.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/language_service.dart';
import 'package:provider/provider.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langService = Provider.of<LanguageService>(context);

    return Scaffold(
      appBar: AppBar(title: Text(langService.translate('community_hub'))),
      body: BotanicalBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('community_posts').orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text(langService.translate('no_posts'), style: const TextStyle(color: AppTheme.sageGreen)));
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final post = snapshot.data!.docs[index];
                return _PostCard(post: post);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostDialog(context),
        backgroundColor: AppTheme.goldAccent,
        icon: const Icon(Icons.add_photo_alternate, color: Colors.black),
        label: Text(langService.translate('share_insight'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final status = doc.data()?['status'] ?? 'active';
      if (status == 'suspended') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text("Access Denied: Your account is currently suspended for policy violations."),
            ),
          );
        }
        return;
      }
    }

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const CreatePostSheet(),
      );
    }
  }
}

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key});

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final TextEditingController _captionController = TextEditingController();
  File? _selectedImage;
  bool _isPosting = false;
  final StorageService _storageService = StorageService();

  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) setState(() => _selectedImage = File(image.path));
  }

  Future<void> _submitPost() async {
    if (_captionController.text.isEmpty && _selectedImage == null) return;
    
    setState(() => _isPosting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final userData = userDoc.data();
      final String userName = userData?['name'] ?? user.displayName ?? "User";
      final String userPhoto = userData?['photoUrl'] ?? user.photoURL ?? "";

      String imageUrl = "";
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadImage(_selectedImage!, 'community_posts');
      }

      await FirebaseFirestore.instance.collection('community_posts').add({
        'userId': user.uid,
        'userName': userName,
        'userPhoto': userPhoto,
        'caption': _captionController.text,
        'imageUrl': imageUrl,
        'likes': [],
        'commentsCount': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error posting: $e")));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langService = Provider.of<LanguageService>(context);

    return Container(
      // Ensure the sheet takes up available space but doesn't overflow
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.darkBotanicalGreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(langService.translate('share_insight'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.goldAccent)),
              const SizedBox(height: 20),
              TextField(
                controller: _captionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: langService.translate('what_is_on_mind'),
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: AppTheme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedImage != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_selectedImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 8, top: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 20)),
                      ),
                    )
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("ADD IMAGE"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.sageGreen,
                    side: const BorderSide(color: AppTheme.sageGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                ),
              const SizedBox(height: 24),
              _isPosting 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.goldAccent))
                : ElevatedButton(onPressed: _submitPost, child: Text(langService.translate('post'))),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final QueryDocumentSnapshot post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final data = post.data() as Map<String, dynamic>;
    final user = FirebaseAuth.instance.currentUser;
    final List likes = data['likes'] ?? [];
    final bool isLiked = likes.contains(user?.uid);
    final String imageUrl = data['imageUrl'] as String? ?? "";
    final String userPhoto = data['userPhoto'] as String? ?? "";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.sageGreen,
                  backgroundImage: _getImageProvider(userPhoto),
                  child: userPhoto.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['userName'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(
                      data['timestamp'] != null 
                        ? DateFormat.yMMMd().format((data['timestamp'] as Timestamp).toDate())
                        : "Just now",
                      style: const TextStyle(fontSize: 12, color: AppTheme.sageGreen),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onPressed: () => _showPostOptions(context, post, Provider.of<LanguageService>(context, listen: false)),
                )
              ],
            ),
          ),
          if (data['caption'] != null && data['caption'] != "")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(data['caption'], style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white)),
            ),
          if (imageUrl != "")
            GestureDetector(
              onTap: () => _showFullScreenImage(context, imageUrl),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  child: _buildPostImage(imageUrl),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : AppTheme.sageGreen),
                  onPressed: () => _toggleLike(post.id, user?.uid, isLiked),
                ),
                Text("${likes.length}", style: const TextStyle(color: AppTheme.sageGreen)),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.sageGreen),
                  onPressed: () => _showComments(context, post),
                ),
                Text("${data['commentsCount'] ?? 0}", style: const TextStyle(color: AppTheme.sageGreen)),
              ],
            ),
          )
        ],
      ),
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
            Hero(
              tag: imageUrl,
              child: _buildPostImage(imageUrl),
            ),
            Positioned(
              top: 40, right: 20,
              child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
            ),
          ],
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
        return Image.memory(base64Decode(base64String), width: double.infinity, fit: BoxFit.contain);
      } catch (e) {
        return const SizedBox();
      }
    }
    return CachedNetworkImage(
      imageUrl: data,
      width: double.infinity,
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(height: 200, color: Colors.white10),
      errorWidget: (context, url, error) => const SizedBox(),
    );
  }

  void _toggleLike(String postId, String? uid, bool isLiked) {
    if (uid == null) return;
    DocumentReference ref = FirebaseFirestore.instance.collection('community_posts').doc(postId);
    if (isLiked) {
      ref.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      ref.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  void _showPostOptions(BuildContext context, QueryDocumentSnapshot post, LanguageService lang) {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = post['userId'] == user?.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkBotanicalGreen,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOwner)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: Text(lang.translate('delete'), style: const TextStyle(color: Colors.white)),
              onTap: () {
                post.reference.delete();
                Navigator.pop(context);
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.orangeAccent),
              title: Text(lang.translate('report_post'), style: const TextStyle(color: Colors.white)),
              onTap: () {
                _reportPost(post);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post reported to admin.")));
              },
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _reportPost(QueryDocumentSnapshot post) async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      final postData = post.data() as Map<String, dynamic>;
      await FirebaseFirestore.instance.collection('user_feedback').add({
        'type': 'flagged_content',
        'postId': post.id,
        'postOwnerId': postData['userId'], // Added this
        'postCaption': postData['caption'],
        'reportedBy': user?.uid,
        'reporterName': user?.displayName ?? "Anonymous",
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      
      // Increment report count on the user document
      if (postData['userId'] != null) {
        await FirebaseFirestore.instance.collection('users').doc(postData['userId']).update({
          'reportCount': FieldValue.increment(1)
        });
      }
    } catch (e) {
      print("Reporting error: $e");
    }
  }

  void _showComments(BuildContext context, QueryDocumentSnapshot post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(post: post),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final QueryDocumentSnapshot post;
  const _CommentsSheet({required this.post});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.data()?['status'] == 'suspended') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Your account is suspended.")));
          Navigator.pop(context);
        }
        return;
      }
    }

    setState(() => _isSending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final userData = userDoc.data();
      final String userName = userData?['name'] ?? user.displayName ?? "User";
      final String userPhoto = userData?['photoUrl'] ?? user.photoURL ?? "";

      await widget.post.reference.collection('comments').add({
        'userId': user.uid,
        'userName': userName,
        'userPhoto': userPhoto,
        'text': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      await widget.post.reference.update({
        'commentsCount': FieldValue.increment(1),
      });

      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.darkBotanicalGreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.goldAccent)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.post.reference.collection('comments').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No comments yet.", style: TextStyle(color: Colors.white54)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final comment = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final String photo = comment['userPhoto'] ?? "";
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.sageGreen,
                            backgroundImage: _getImageProvider(photo),
                            child: photo.isEmpty ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comment['userName'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.goldAccent, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(comment['text'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  comment['timestamp'] != null 
                                    ? DateFormat.yMMMd().add_jm().format((comment['timestamp'] as Timestamp).toDate())
                                    : "Just now",
                                  style: const TextStyle(fontSize: 10, color: Colors.white30),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Add a comment...",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                _isSending 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.goldAccent))
                  : IconButton(
                      icon: const Icon(Icons.send, color: AppTheme.goldAccent),
                      onPressed: _addComment,
                    ),
              ],
            ),
          ),
        ],
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
}
