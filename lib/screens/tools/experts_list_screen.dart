import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/expert_data.dart';
import '../../widgets/botanical_background.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';

class ExpertsListScreen extends StatelessWidget {
  const ExpertsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageService>(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('ask_expert_title')),
      ),
      body: BotanicalBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ExpertData.experts.length,
          itemBuilder: (context, index) {
            final expert = ExpertData.experts[index];
            return _buildExpertCard(context, expert, theme, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildExpertCard(BuildContext context, ExpertInfo expert, ThemeData theme, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.business_center_outlined, color: theme.colorScheme.primary, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expert.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        expert.role,
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expert.specialization,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchPhone(expert.phone),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text("Call"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchEmail(expert.email),
                    icon: const Icon(Icons.email, size: 18),
                    label: const Text("Email"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchWhatsApp(expert.phone),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text("Chat"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _launchPhone(String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _launchEmail(String email) async {
    final Uri url = Uri.parse("mailto:$email?subject=WheatGuard Consultation");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _launchWhatsApp(String phone) async {
    final Uri url = Uri.parse("https://wa.me/$phone");
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
