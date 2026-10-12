import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_guidance_screen.dart';
import '../../services/tflite_service.dart';
import '../../services/storage_service.dart';
import '../tools/dosage_calculator_screen.dart';
import '../tools/experts_list_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/botanical_background.dart';
import '../../utils/disease_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

class DetectScreen extends StatefulWidget {
  const DetectScreen({super.key});
  @override State<DetectScreen> createState() => _DetectScreenState();
}

class _DetectScreenState extends State<DetectScreen> with SingleTickerProviderStateMixin {
  File? _image;
  bool _isLoading = false;
  String? _detectedLabel;
  double? _confidence;

  final TFLiteService   _tfliteService  = TFLiteService();
  final ImagePicker     _picker         = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final XFile? selected = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraGuidanceScreen()));
      if (selected != null) _processSelectedImage(selected);
    } else {
      final XFile? selected = await _picker.pickImage(source: source, imageQuality: 85);
      if (selected != null) _processSelectedImage(selected);
    }
  }

  void _processSelectedImage(XFile selected) async {
    setState(() {
      _isLoading = true;
      _image = File(selected.path);
      _detectedLabel = null;
      _confidence = null;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    await _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    if (_image == null || !mounted) return;
    setState(() { _isLoading = true; _detectedLabel = null; _confidence = null; });
    try {
      final startTime = DateTime.now();
      final result = await _tfliteService.runInference(_image!);
      final endTime = DateTime.now();
      final difference = endTime.difference(startTime).inMilliseconds;
      if (difference < 1500) await Future.delayed(Duration(milliseconds: 1500 - difference));
      if (!mounted) return;
      final String rawLabel = result["label"] ?? "Unknown";
      final double confidence = (result["confidence"] as num?)?.toDouble() ?? 0.0;
      final bool isUnknown = rawLabel == "Unknown" || rawLabel == "Error";
      final bool isNotWheat = rawLabel == "Not_Wheat";
      final bool isDisease = !isUnknown && !isNotWheat;
      setState(() { _isLoading = false; _detectedLabel = rawLabel == "Error" ? "Unknown" : rawLabel; _confidence = confidence; });
      _showResult(result: result, image: _image!, isUnknown: isUnknown, isNotWheat: isNotWheat, isDisease: isDisease);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Analysis failed: $e")));
      }
    }
  }

  void _showResult({required Map<String, dynamic> result, required File image, required bool isUnknown, required bool isNotWheat, required bool isDisease}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResultWindow(result: result, localImage: image, isUnknown: isUnknown, isNotWheat: isNotWheat, isDisease: isDisease),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langService = Provider.of<LanguageService>(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(langService.translate('disease_analysis'), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          BotanicalBackground(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_image != null) _buildImagePreview(theme) else _buildImagePlaceholder(theme),
                    const SizedBox(height: 32),
                    if (_detectedLabel != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _detectedLabel == "Unknown" ? langService.translate('image_unclear') : (_detectedLabel == "Not_Wheat" ? langService.translate('not_wheat') : langService.translate(_detectedLabel!)),
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                            if (_confidence != null && _detectedLabel != "Unknown")
                              Text("${(_confidence! * 100).toStringAsFixed(1)}% AI Accuracy", style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else
                      Text(langService.translate('position_wheat'), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 48),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => _pickImage(ImageSource.camera),
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
                          child: Text(langService.translate('capture_camera').toUpperCase()),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 60),
                            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                          ),
                          child: Text(langService.translate('upload_gallery').toUpperCase()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(langService, theme),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    return Container(
      height: 320, width: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.primary, width: 3),
        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 15))],
        image: DecorationImage(image: FileImage(_image!), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Container(
      height: 260, width: 260,
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1), width: 1),
      ),
      child: Center(
        child: Text(
          "READY TO SCAN", 
          style: TextStyle(
            color: theme.colorScheme.primary.withOpacity(0.4), 
            fontWeight: FontWeight.w900, 
            fontSize: 12, 
            letterSpacing: 3
          )
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(LanguageService lang, ThemeData theme) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        color: theme.brightness == Brightness.dark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.85),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 80, 
                width: 80, 
                child: CircularProgressIndicator(
                  strokeWidth: 2, 
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)
                )
              ),
              const SizedBox(height: 48),
              Text(
                lang.translate('analyzing').toUpperCase(), 
                style: TextStyle(
                  color: theme.colorScheme.primary, 
                  fontSize: 14, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 5
                )
              ),
              const SizedBox(height: 12),
              Text(
                "AI NEURAL PROCESSING", 
                style: TextStyle(
                  color: theme.colorScheme.primary.withOpacity(0.4), 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultWindow extends StatefulWidget {
  final Map<String, dynamic> result;
  final File localImage;
  final bool isUnknown;
  final bool isNotWheat;
  final bool isDisease;
  const _ResultWindow({required this.result, required this.localImage, required this.isUnknown, required this.isNotWheat, required this.isDisease});
  @override State<_ResultWindow> createState() => _ResultWindowState();
}

class _ResultWindowState extends State<_ResultWindow> {
  String _saveStatus = "SAVING DATA...";
  bool _saveFinished = false;

  @override
  void initState() {
    super.initState();
    if (widget.isDisease) _saveToCloud();
    else setState(() { _saveStatus = ""; _saveFinished = true; });
  }

  Future<void> _saveToCloud() async {
    final lang = Provider.of<LanguageService>(context, listen: false);
    try {
      final storage = StorageService();
      final String base64Image = await storage.uploadImage(widget.localImage, "scan_history");
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { setState(() => _saveStatus = "NOT LOGGED IN"); return; }
      final String label = widget.result["label"] ?? "Unknown";
      final double confidence = (widget.result["confidence"] as num?)?.toDouble() ?? 0.0;
      await FirebaseFirestore.instance.collection("users").doc(user.uid).collection("scan_history").add({
        "disease": label, "confidence": confidence, "imageUrl": base64Image, "timestamp": FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({ "totalScans": FieldValue.increment(1), if (label == "Healthy") "healthyScans": FieldValue.increment(1) });
      if (mounted) setState(() { _saveStatus = "RECORD SECURED"; _saveFinished = true; });
    } catch (e) { if (mounted) setState(() => _saveStatus = "SAVE ERROR"); }
  }

  void _showCreateHealthCardDialog(BuildContext context, String disease, double confidence) {
    final lang = Provider.of<LanguageService>(context, listen: false);
    final theme = Theme.of(context);
    final speech = stt.SpeechToText();
    final controller = TextEditingController();
    bool isListening = false;
    bool isSaving = false;
    String selectedSeverity = "Mild";
    bool isHealthy = disease == "Healthy";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = theme.brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: theme.cardColor,
              scrollable: true,
              title: Row(children: [Icon(Icons.add_chart_rounded, color: theme.colorScheme.primary), const SizedBox(width: 12), Expanded(child: Text(lang.translate('create_health_card'), style: const TextStyle(fontSize: 18)))]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isHealthy) ...[
                    const Align(alignment: Alignment.centerLeft, child: Text("INFECTION SEVERITY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5, color: Colors.grey))),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedSeverity,
                      dropdownColor: theme.cardColor,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: const [DropdownMenuItem(value: "Mild", child: Text("Mild")), DropdownMenuItem(value: "Moderate", child: Text("Moderate")), DropdownMenuItem(value: "Severe", child: Text("Severe"))],
                      onChanged: (val) => setDialogState(() => selectedSeverity = val!),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Align(alignment: Alignment.centerLeft, child: Text("TREATMENT & VOICE NOTES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5, color: Colors.grey))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller, maxLines: 3,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Speak or type treatment details...",
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () async {
                            if (!isListening) {
                              if (await speech.initialize()) {
                                setDialogState(() => isListening = true);
                                speech.listen(
                                  localeId: lang.currentLocale.toLanguageTag(),
                                  onResult: (val) => setDialogState(() => controller.text = val.recognizedWords),
                                );
                              }
                            } else {
                              speech.stop();
                              setDialogState(() => isListening = false);
                            }
                          },
                          child: CircleAvatar(
                            backgroundColor: isListening ? Colors.redAccent : theme.colorScheme.primary,
                            radius: 18,
                            child: Icon(isListening ? Icons.stop : Icons.mic, size: 18, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isSaving) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Expanded(child: Text("Securing pinpoint GPS location...", style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: Text(lang.translate('cancel'))),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    setDialogState(() => isSaving = true);
                    try {
                      // Requesting high accuracy location
                      Position pos = await Geolocator.getCurrentPosition(
                        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
                        timeLimit: const Duration(seconds: 15),
                      );
                      
                      final storage = StorageService();
                      String base64Image = await storage.uploadImage(widget.localImage, "health_cards");
                      
                      await FirebaseFirestore.instance.collection('health_cards').add({
                        'userId': FirebaseAuth.instance.currentUser?.uid,
                        'diseaseName': disease,
                        'initialConfidence': confidence,
                        'initialSeverity': isHealthy ? "Optimal" : selectedSeverity,
                        'initialImageUrl': base64Image,
                        'location': GeoPoint(pos.latitude, pos.longitude),
                        'createdAt': FieldValue.serverTimestamp(),
                        'status': isHealthy ? 'safe' : 'active',
                        'followUps': [],
                        'notesLog': [{'text': controller.text.trim(), 'timestamp': DateTime.now()}],
                        'initialDiseaseScore': confidence, // Storing for timeline
                      });
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        _showInitialSuccess(context, disease);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text("Location Error: $e")));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 12)),
                  child: isSaving ? const Text("SECURING...") : const Text("SUBMIT SPOT"),
                ),
              ],
            );
          }
      ),
    );
  }

  void _showInitialSuccess(BuildContext context, String disease) {
    showDialog(
        context: context,
        builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                    color: const Color(0xFF0E1F16).withOpacity(0.98),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.greenAccent, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.1),
                          blurRadius: 30
                      )
                    ]
                ),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.greenAccent, size: 90),
                      const SizedBox(height: 24),
                      const Text("SUCCESS", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
                      const SizedBox(height: 12),
                      Text("Professional tracking for $disease has been successfully initiated with pinpoint accuracy.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 32),
                      ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 55)), child: const Text("CONTINUE"))
                    ]
                )
            )
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageService>(context);
    final isDark = theme.brightness == Brightness.dark;
    final double confidence = (widget.result['confidence'] as num?)?.toDouble() ?? 0.0;
    final String label = widget.result['label'] ?? "Unknown";

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(40)), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1), width: 1)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.colorScheme.onSurface.withOpacity(0.1), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.file(widget.localImage, height: 180, width: double.infinity, fit: BoxFit.cover)),
            const SizedBox(height: 20),
            if (widget.isDisease && _saveStatus.isNotEmpty) Text(_saveStatus, style: TextStyle(color: _saveFinished ? Colors.greenAccent : theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(widget.isUnknown ? lang.translate('image_unclear') : (widget.isNotWheat ? lang.translate('not_wheat') : lang.translate(label)), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            if (!widget.isUnknown) Text("${(confidence * 100).toStringAsFixed(1)}% Match Probability", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600)),
            const Divider(height: 40),
            if (widget.isDisease) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
                decoration: BoxDecoration(
                  color: label == "Healthy" ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05), 
                  borderRadius: BorderRadius.circular(12), 
                  border: Border.all(color: label == "Healthy" ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3), width: 1)
                ), 
                child: Text(
                  label == "Healthy" ? "HEALTH STATUS: OPTIMAL" : "SECURITY THREAT DETECTED", 
                  style: TextStyle(
                    color: label == "Healthy" ? Colors.green : Colors.red, 
                    fontWeight: FontWeight.w900, 
                    fontSize: 11, 
                    letterSpacing: 1.5
                  )
                )
              ),
              const SizedBox(height: 24),
              _buildDiseaseInfo(lang, theme, label),
              const SizedBox(height: 32),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DosageCalculatorScreen(initialDisease: label))), icon: const Icon(Icons.calculate_rounded, size: 18), label: const Text("DOSAGE"))),
                const SizedBox(width: 16),
                Expanded(child: ElevatedButton.icon(onPressed: () => _showCreateHealthCardDialog(context, label, confidence), icon: const Icon(Icons.add_chart_rounded, size: 18, color: Colors.black), label: const Text("TRACK SPOT"))),
              ]),
            ] else ...[
              Text(widget.isUnknown ? "The AI system requires a clearer photo of the wheat leaf to proceed." : "This object does not match our Wheat Biological Database.", style: const TextStyle(color: Colors.grey, height: 1.5)),
            ],
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1), foregroundColor: theme.colorScheme.onSurface), child: Text(lang.translate('close'))),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseInfo(LanguageService lang, ThemeData theme, String label) {
    final info = DiseaseData.getInfo(label);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _infoBlock("Biological Description", info.description, theme),
      _infoBlock("Visible Symptoms", info.symptoms, theme),
      _infoBlock("Recommended Treatment", info.treatment, theme),
      if (label != "Healthy") ...[
        const Divider(height: 40),
        const Text("PHARMACEUTICAL RECOMMENDATION", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2, color: Colors.grey)),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1))), child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(info.medicineImageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.medication_rounded, size: 40, color: Colors.grey))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(info.recommendedMedicine, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const Text("Certified Product", style: TextStyle(color: Colors.grey, fontSize: 12))]))])),
      ]
    ]);
  }

  Widget _infoBlock(String title, String content, ThemeData theme) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 4, height: 14, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 10), Text(title.toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5))]), const SizedBox(height: 8), Text(content, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8), height: 1.5, fontSize: 14))]));
  }
}
