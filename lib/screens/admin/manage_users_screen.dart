import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/botanical_background.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Registry")),
      body: BotanicalBackground(
        child: Column(
          children: [
            _buildSearchField(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No users found"));

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? "").toString().toLowerCase();
                    final email = (data['email'] ?? "").toString().toLowerCase();
                    return name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final user = docs[index];
                      final data = user.data() as Map<String, dynamic>;
                      final String photoUrl = data['photoUrl'] as String? ?? "";
                      final bool isAdmin = data['role'] == 'admin';
                      final String status = data['status'] ?? 'active';
                      final int reports = data['reportCount'] ?? 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: status == 'suspended' ? Colors.redAccent.withOpacity(0.5) : (isAdmin ? AppTheme.goldAccent.withOpacity(0.3) : Colors.white.withOpacity(0.05))),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: AppTheme.sageGreen.withOpacity(0.2),
                                backgroundImage: _getProfileImage(photoUrl),
                                child: photoUrl.isEmpty ? Text(data['name']?[0]?.toUpperCase() ?? "?", style: const TextStyle(color: Colors.white)) : null,
                              ),
                              if (isAdmin)
                                const Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 8, backgroundColor: AppTheme.goldAccent, child: Icon(Icons.verified, size: 10, color: Colors.black))),
                              if (status == 'suspended')
                                const Positioned(right: 0, top: 0, child: CircleAvatar(radius: 8, backgroundColor: Colors.red, child: Icon(Icons.block, size: 10, color: Colors.white))),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['name'] ?? "Anonymous User", 
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                )
                              ),
                              if (reports > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent, width: 0.5)),
                                  child: Text("$reports REPORTS", style: const TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['email'] ?? "", 
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  Text("Role: ${isAdmin ? 'Administrator' : 'User'}", style: TextStyle(color: isAdmin ? AppTheme.goldAccent : AppTheme.sageGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                                  Text("Status: ${status.toUpperCase()}", style: TextStyle(color: status == 'active' ? Colors.greenAccent : (status == 'warned' ? Colors.orangeAccent : Colors.redAccent), fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          trailing: _buildActionMenu(context, user.id, data),
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

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search by name or email...",
          prefixIcon: const Icon(Icons.search, color: AppTheme.goldAccent),
          fillColor: AppTheme.cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context, String uid, Map<String, dynamic> data) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white54),
      color: AppTheme.darkBotanicalGreen,
      onSelected: (value) {
        if (value == 'edit') {
          _editUser(context, uid, data);
        } else if (value == 'role') {
          _toggleRole(uid, data['role']);
        } else if (value == 'status') {
          _showStatusDialog(context, uid, data);
        } else if (value == 'delete') {
          _confirmDelete(context, uid, data['name']);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 10), Text("Edit Info")]),
        ),
        PopupMenuItem(
          value: 'role',
          child: Row(children: [const Icon(Icons.security, size: 18, color: AppTheme.goldAccent), const SizedBox(width: 10), Text(data['role'] == 'admin' ? "Demote to User" : "Make Admin")]),
        ),
        const PopupMenuItem(
          value: 'status',
          child: Row(children: [Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange), SizedBox(width: 10), Text("Change Status")]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [Icon(Icons.delete_forever, size: 18, color: Colors.red), SizedBox(width: 10), Text("Delete Account")]),
        ),
      ],
    );
  }

  void _showStatusDialog(BuildContext context, String uid, Map<String, dynamic> data) {
    String selectedStatus = data['status'] ?? 'active';
    final noteController = TextEditingController(text: data['adminNote'] ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.cardColor,
            title: const Text("User Account Status"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  dropdownColor: AppTheme.darkBotanicalGreen,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Account Status", labelStyle: TextStyle(color: Colors.white70)),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text("Active (Normal)")),
                    DropdownMenuItem(value: 'warned', child: Text("Warned (Visible Warning)")),
                    DropdownMenuItem(value: 'suspended', child: Text("Suspended (Blocked)")),
                  ],
                  onChanged: (val) => setDialogState(() => selectedStatus = val!),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Admin Message",
                    hintText: "Explain why the account was warned/suspended...",
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                    'status': selectedStatus,
                    'adminNote': noteController.text.trim(),
                    if (selectedStatus == 'active') 'reportCount': 0, // Clear reports if set to active
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("UPDATE STATUS"),
              ),
            ],
          );
        }
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

  void _toggleRole(String uid, String? currentRole) async {
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': newRole});
  }

  void _editUser(BuildContext context, String uid, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text("Edit User Profile"),
        content: TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Display Name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).update({'name': nameController.text});
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("UPDATE"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String uid, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text("Security Alert"),
        content: Text("Proceed with permanent deletion of $name? All data for this user will be lost."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
