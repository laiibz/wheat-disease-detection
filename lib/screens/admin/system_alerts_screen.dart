import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/botanical_background.dart';
import 'package:intl/intl.dart';

class SystemAlertsScreen extends StatelessWidget {
  const SystemAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("System Alerts & Feedback")),
      body: BotanicalBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('user_feedback').orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No alerts found.", style: TextStyle(color: Colors.white54)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final alert = snapshot.data!.docs[index];
                final data = alert.data() as Map<String, dynamic>;
                final bool isFlagged = data['type'] == 'flagged_content';
                final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                return Card(
                  color: AppTheme.cardColor,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: isFlagged ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                      child: Icon(
                        isFlagged ? Icons.flag : Icons.feedback,
                        color: isFlagged ? Colors.redAccent : Colors.blueAccent,
                      ),
                    ),
                    title: Text(
                      isFlagged ? "Flagged Post" : "User Feedback",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Text(
                      "${DateFormat.yMMMd().format(date)} • ${data['status']?.toUpperCase() ?? 'PENDING'}",
                      style: TextStyle(color: data['status'] == 'resolved' ? Colors.green : AppTheme.sageGreen, fontSize: 12),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow("From:", data['userName'] ?? "Unknown"),
                            if (!isFlagged) _buildInfoRow("Email:", data['userEmail'] ?? "N/A"),
                            const SizedBox(height: 8),
                            const Text("Content:", style: TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              isFlagged ? (data['postCaption'] ?? "[No Caption]") : (data['message'] ?? ""),
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isFlagged && data['postOwnerId'] != null)
                                  TextButton.icon(
                                    onPressed: () => _suspendOwner(context, data['postOwnerId']),
                                    icon: const Icon(Icons.block, color: Colors.orangeAccent),
                                    label: const Text("SUSPEND OWNER", style: TextStyle(color: Colors.orangeAccent)),
                                  ),
                                if (data['status'] != 'resolved')
                                  TextButton.icon(
                                    onPressed: () => alert.reference.update({'status': 'resolved'}),
                                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                    label: const Text("RESOLVE", style: TextStyle(color: Colors.green)),
                                  ),
                                TextButton.icon(
                                  onPressed: () => _confirmDelete(context, alert.reference),
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  label: const Text("DELETE", style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppTheme.sageGreen, fontSize: 13)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _suspendOwner(BuildContext context, String uid) async {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text("Suspend Account"),
        content: TextField(
          controller: noteController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: "Reason for Suspension"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).update({
                'status': 'suspended',
                'adminNote': noteController.text.trim(),
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User suspended.")));
              }
            },
            child: const Text("SUSPEND"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DocumentReference ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkBotanicalGreen,
        title: const Text("Delete Alert?"),
        content: const Text("This will permanently remove this alert from the system."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              ref.delete();
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
