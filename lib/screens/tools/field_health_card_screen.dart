import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/health_card_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/botanical_background.dart';
import '../../services/language_service.dart';
import '../../services/tflite_service.dart';
import '../../services/storage_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

Widget _buildFlexibleImage(String data, {double? height, double width = double.infinity}) {
  if (data.isEmpty) return Container(height: height, width: width, color: Colors.grey[200], child: const Icon(Icons.image_not_supported));
  if (data.startsWith('data')) {
    try {
      final base64String = data.split(',').last;
      return Image.memory(base64Decode(base64String), height: height, width: width, fit: BoxFit.cover);
    } catch (e) {
      return const Icon(Icons.broken_image);
    }
  }
  return CachedNetworkImage(
    imageUrl: data,
    height: height,
    width: width,
    fit: BoxFit.cover,
    placeholder: (context, url) => Container(color: Colors.black12),
    errorWidget: (context, url, error) => const Icon(Icons.broken_image),
  );
}

class FieldHealthCardScreen extends StatefulWidget {
  const FieldHealthCardScreen({super.key});
  @override
  State<FieldHealthCardScreen> createState() => _FieldHealthCardScreenState();
}

class _FieldHealthCardScreenState extends State<FieldHealthCardScreen> {
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initLocationStream();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _initLocationStream() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    ).listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final lang = Provider.of<LanguageService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('field_health_card')),
        centerTitle: true,
      ),
      body: BotanicalBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('health_cards')
              .where('userId', isEqualTo: user?.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(lang, theme);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final card = HealthCard.fromMap(doc.id, doc.data() as Map<String, dynamic>);

                double? distance;
                if (_currentPosition != null) {
                  distance = Geolocator.distanceBetween(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    card.location.latitude,
                    card.location.longitude,
                  );
                }

                return _buildCardItem(context, card, lang, theme, isDark, distance);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(LanguageService lang, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            Text(lang.translate('no_health_cards'), textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(lang.translate('start_tracking_desc'), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(BuildContext context, HealthCard card, LanguageService lang, ThemeData theme, bool isDark, double? distance) {
    // Shared Threshold Constants
    const double arrivedThreshold = 4.0; 
    
    // Check if we are physically close enough
    bool isArrived = distance != null && distance <= arrivedThreshold;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: () => _showCardDetails(context, card, lang, theme),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildFlexibleImage(card.initialImageUrl, height: 140),
                Positioned(
                  top: 12, right: 12,
                  child: _buildStatusBadge(card.status, card.diseaseName, lang),
                ),
                if (distance != null)
                  Positioned(
                    bottom: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isArrived ? Colors.green : Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isArrived ? Colors.white : Colors.transparent, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isArrived ? Icons.verified : Icons.straighten, color: Colors.white, size: 12),
                          const SizedBox(width: 6),
                          Text(
                            isArrived ? "AT SPOT" : "${distance.toStringAsFixed(1)}m",
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      card.diseaseName.contains("Healthy") ? "HEALTHY" : card.initialSeverity,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(lang.translate(card.diseaseName), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Row(
                        children: [
                          Text(DateFormat.yMMMd(lang.dateLocale).format(card.createdAt), style: theme.textTheme.bodySmall),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _deleteCard(context, card.id, lang),
                            child: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: isArrived ? Colors.green : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "PINPOINT: ${card.location.latitude.toStringAsFixed(5)}, ${card.location.longitude.toStringAsFixed(5)}",
                        style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (!isArrived)
                        TextButton.icon(
                          onPressed: () => _openInMaps(context, card.location.latitude, card.location.longitude, distance),
                          icon: const Icon(Icons.navigation_rounded, size: 14),
                          label: const Text("NAVIGATE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: Colors.blueAccent,
                          ),
                        )
                      else
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    ],
                  ),
                  if (card.notesLog.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.speaker_notes, size: 12, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              card.notesLog.last.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
      case 'active':
        return Colors.redAccent;
      case 'moderate':
      case 'improving':
        return Colors.orangeAccent;
      case 'mild':
        return Colors.yellow[700]!;
      case 'recovered':
      case 'optimal health':
      case 'optimal':
        return Colors.greenAccent;
      default:
        return Colors.greenAccent;
    }
  }

  Widget _buildStatusBadge(String status, String diseaseName, LanguageService lang) {
    bool isHealthy = diseaseName.contains("Healthy");
    Color color;
    String label = status;

    if (isHealthy) {
      color = Colors.green;
      label = "SAFE";
    } else {
      switch (status) {
        case 'recovered':
          color = Colors.green;
          break;
        case 'improving':
          color = Colors.orange;
          break;
        default:
          color = Colors.redAccent;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
      ),
      child: Text(
        isHealthy ? label : lang.translate(label).toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  void _showCardDetails(BuildContext context, HealthCard card, LanguageService lang, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HealthCardDetailView(card: card, lang: lang, theme: theme),
    );
  }

  void _deleteCard(BuildContext context, String cardId, LanguageService lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('delete_record')),
        content: Text(lang.translate('confirm_delete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('health_cards').doc(cardId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(lang.translate('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _openInMaps(BuildContext context, double lat, double lng, double? distance) async {
    if (distance != null && distance <= 3.0) {
      _showSimpleFloatingDialog(context, "You're Here!", "You are already at the exact spot for this health card.");
      return;
    }
    // Using a more specific search query to show a labeled pin
    final Uri url = Uri.parse("google.navigation:q=$lat,$lng&mode=w");
    final Uri webUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    final Uri geoUrl = Uri.parse("geo:$lat,$lng?q=$lat,$lng(Wheat+Guard+Detection+Spot)");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else if (await canLaunchUrl(geoUrl)) {
      await launchUrl(geoUrl);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl);
    }
  }

  void _showSimpleFloatingDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1C3524).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.greenAccent, width: 2),
            boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.2), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user, color: Colors.greenAccent, size: 80),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                child: const Text("CLOSE"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthCardDetailView extends StatefulWidget {
  final HealthCard card;
  final LanguageService lang;
  final ThemeData theme;

  const _HealthCardDetailView({required this.card, required this.lang, required this.theme});

  @override
  State<_HealthCardDetailView> createState() => _HealthCardDetailViewState();
}

class _HealthCardDetailViewState extends State<_HealthCardDetailView> {
  bool _isProcessing = false;
  final stt.SpeechToText _speech = stt.SpeechToText();

  StreamSubscription<Position>? _positionStream;
  double? _distanceInMeters;
  bool _hasShownArrivalDialog = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _startLiveLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _showFloatingSuccess(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.theme.cardColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.greenAccent, width: 2),
            boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.2), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 80),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                child: const Text("AWESOME"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startLiveLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // Get current position once immediately to check if already arrived
    try {
      Position initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );
      _handleNewPosition(initialPos);
    } catch (e) { /* silent fail for initial catch */ }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 0),
    ).listen(_handleNewPosition);
  }

  void _handleNewPosition(Position position) {
    if (!mounted) return;
    final double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      widget.card.location.latitude,
      widget.card.location.longitude,
    );

    setState(() {
      _currentPosition = position;
      _distanceInMeters = distance;
    });

    const double arrivedThreshold = 4.0;
    if (distance <= arrivedThreshold) {
      double accuracy = position.accuracy;
      if (accuracy <= 8.0 && !_hasShownArrivalDialog) {
        _hasShownArrivalDialog = true;
        _showFloatingSuccess("Target Reached!", "GPS has stabilized and confirmed you are at the precise spot.");
      }
    } else if (distance > arrivedThreshold + 2.0) {
      _hasShownArrivalDialog = false;
    }
  }

  Future<void> _openInMapsFromDetail() async {
    if (_distanceInMeters != null && _distanceInMeters! <= 3.0) {
      _showFloatingSuccess("Already Arrived!", "You are currently standing at the exact saved location for this health card.");
      return;
    }
    final lat = widget.card.location.latitude;
    final lng = widget.card.location.longitude;
    final Uri url = Uri.parse("google.navigation:q=$lat,$lng&mode=w");
    final Uri webUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: widget.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          if (_distanceInMeters != null && _distanceInMeters! <= 4.0)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: (_currentPosition != null && _currentPosition!.accuracy > 10) ? Colors.amber : Colors.green, 
                borderRadius: BorderRadius.circular(16)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    (_currentPosition != null && _currentPosition!.accuracy > 10) ? Icons.sync : Icons.verified_user, 
                    color: Colors.white, 
                    size: 20
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      (_currentPosition != null && _currentPosition!.accuracy > 10) 
                          ? "WAITING FOR GPS PRECISION (±${_currentPosition!.accuracy.toInt()}m)" 
                          : "CONFIRMED: AT EXACT SPOT", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.lang.translate(widget.card.diseaseName),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Detection Location Secured on ${DateFormat.yMMMd(widget.lang.dateLocale).format(widget.card.createdAt)}",
                              style: widget.theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            if (_distanceInMeters != null && _distanceInMeters! > 3.0)
                              TextButton.icon(
                                onPressed: _openInMapsFromDetail,
                                icon: const Icon(Icons.directions, size: 16, color: Colors.blueAccent),
                                label: const Text("START NAVIGATION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                ),
                              )
                            else if (_distanceInMeters != null && _distanceInMeters! <= 3.0)
                              const Row(
                                children: [
                                  Icon(Icons.verified_rounded, size: 16, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text("YOU ARE AT THE PRECISE SPOT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          _buildProximityBadge(widget.theme),
                          if (_currentPosition != null) ...[
                            const SizedBox(height: 4),
                            Text("GPS ±${_currentPosition?.accuracy.toStringAsFixed(1)}m", style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                          ]
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 40),
                  _buildSectionTitle("Recovery Timeline"),
                  const SizedBox(height: 16),
                  _buildTimeline(widget.card),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("Treatment Logs"),
                      IconButton(
                        onPressed: _addNote,
                        icon: const Icon(Icons.add_comment, size: 20),
                        color: widget.theme.colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildNotesLog(widget.card),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.card.status != 'recovered')
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _addFollowUp,
              icon: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_a_photo),
              label: const Text("ADD FOLLOW-UP SCAN"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
            ),
        ],
      ),
    );
  }

  Widget _buildProximityBadge(ThemeData theme) {
    if (_distanceInMeters == null) return const SizedBox.shrink();

    const double arrivedThreshold = 4.0;
    const double nearbyThreshold = 12.0;

    bool isArrived = _distanceInMeters! <= arrivedThreshold;
    bool isNearby = _distanceInMeters! <= nearbyThreshold;
    
    // If accuracy is worse than distance, we aren't "sure" yet
    double accuracy = _currentPosition?.accuracy ?? 100.0;
    bool isConfidenceLow = accuracy > 10.0 && isArrived;

    if (isArrived && !isConfidenceLow) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: const Column(
          children: [
            Icon(Icons.verified, color: Colors.green, size: 20),
            SizedBox(height: 4),
            Text("ARRIVED", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
          ],
        ),
      );
    }

    Color color = isArrived ? Colors.amber : (isNearby ? Colors.orange : Colors.orangeAccent);
    IconData icon = isArrived ? Icons.hourglass_empty : (isNearby ? Icons.radar : Icons.track_changes);

    String status;
    if (isArrived) {
      status = "STABILIZING";
    } else if (isNearby) {
      status = "VERY CLOSE";
    } else if (_distanceInMeters! <= 50) {
      status = "NEARBY";
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: theme.colorScheme.primary, width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.track_changes, color: theme.colorScheme.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              "${(_distanceInMeters! / 1000).toStringAsFixed(2)} KM",
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesLog(HealthCard card) {
    if (card.notesLog.isEmpty) {
      return Text("No treatment notes recorded yet.", style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 13));
    }

    return Column(
      children: card.notesLog.map((note) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.theme.colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMd(widget.lang.dateLocale).add_jm().format(note.timestamp),
                  style: widget.theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Icon(Icons.mic, size: 14, color: widget.theme.colorScheme.primary.withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              note.text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Future<void> _addNote() async {
    final TextEditingController controller = TextEditingController();
    bool isListening = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: widget.theme.cardColor,
            title: const Text("Add Treatment Note"),
            content: TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.lang.translate('tap_to_speak'),
                suffixIcon: GestureDetector(
                  onTap: () async {
                    if (!isListening) {
                      bool available = await _speech.initialize();
                      if (available) {
                        setDialogState(() => isListening = true);
                        _speech.listen(
                          listenOptions: stt.SpeechListenOptions(
                            localeId: widget.lang.currentLocale.toLanguageTag(),
                          ),
                          onResult: (val) {
                            setDialogState(() => controller.text = val.recognizedWords);
                          }
                        );
                      }
                    } else {
                      _speech.stop();
                      setDialogState(() => isListening = false);
                    }
                  },
                  child: CircleAvatar(
                    backgroundColor: isListening ? Colors.redAccent : widget.theme.colorScheme.primary,
                    radius: 18,
                    child: Icon(isListening ? Icons.stop : Icons.mic, size: 18, color: Colors.black),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.lang.translate('cancel'))),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;

                  final note = NoteEntry(
                    text: controller.text.trim(),
                    timestamp: DateTime.now(),
                  );

                  await FirebaseFirestore.instance.collection('health_cards').doc(widget.card.id).update({
                    'notesLog': FieldValue.arrayUnion([note.toMap()]),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text(widget.lang.translate('submit')),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(color: widget.theme.colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12),
    );
  }

  Widget _buildTimeline(HealthCard card) {
    List<Widget> items = [];

    items.add(_timelineItem(
      title: "Initial Detection",
      subtitle: card.initialSeverity,
      score: card.initialDiseaseScore,
      date: card.createdAt,
      imageUrl: card.initialImageUrl,
      isFirst: true,
      isLast: card.followUps.isEmpty,
    ));

    for (int i = 0; i < card.followUps.length; i++) {
      final f = card.followUps[i];
      items.add(_timelineItem(
        title: "Follow-up Scan",
        subtitle: f.severity,
        score: f.diseaseScore,
        date: f.timestamp,
        imageUrl: f.imageUrl,
        isFirst: false,
        isLast: i == card.followUps.length - 1,
      ));
    }

    return Column(children: items);
  }

  Widget _timelineItem({required String title, required String subtitle, required double score, required DateTime date, required String imageUrl, required bool isFirst, required bool isLast}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: widget.theme.colorScheme.primary, shape: BoxShape.circle)),
          if (!isLast) Container(width: 2, height: 120, color: widget.theme.colorScheme.primary.withValues(alpha: 0.3)),
        ],
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(DateFormat.MMMd(widget.lang.dateLocale).format(date), style: widget.theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(subtitle).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _getSeverityColor(subtitle), width: 1),
                  ),
                  child: Text(subtitle.toUpperCase(), style: TextStyle(color: _getSeverityColor(subtitle), fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: 120, height: 80, child: _buildFlexibleImage(imageUrl)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ]);
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
      case 'active':
        return Colors.redAccent;
      case 'moderate':
      case 'improving':
        return Colors.orangeAccent;
      case 'mild':
        return Colors.yellow[700]!;
      case 'recovered':
      case 'optimal health':
      case 'optimal':
        return Colors.greenAccent;
      default:
        return Colors.greenAccent;
    }
  }

  Future<void> _addFollowUp() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);

    if (photo == null) return;

    setState(() => _isProcessing = true);

    try {
      final tflite = TFLiteService();
      final result = await tflite.runInferenceForHealthCard(File(photo.path), widget.card.diseaseName);

      final storage = StorageService();
      final String base64Image = await storage.uploadImage(File(photo.path), "health_followups");

      if (!mounted) return;
      setState(() => _isProcessing = false);

      _showVerificationDialog(result, base64Image);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  void _showVerificationDialog(Map<String, dynamic> result, String base64Image) {
    String selectedStatus = 'active';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: widget.theme.cardColor,
            title: const Text("Verify Field Progress"),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Compare the current state of your crop with the previous scan to update its status.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(height: 160, width: double.infinity, child: _buildFlexibleImage(base64Image)),
                  ),
                  const Divider(height: 40),
                  const Text("Based on your observation, select current status:", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Theme(
                    data: Theme.of(context).copyWith(canvasColor: isDark ? AppTheme.cardColor : Colors.white),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedStatus,
                      dropdownColor: isDark ? AppTheme.cardColor : Colors.white,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: [
                        DropdownMenuItem(value: 'active', child: Text("Still Active / Persistent", style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
                        DropdownMenuItem(value: 'improving', child: Text("Visually Improving", style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
                        DropdownMenuItem(value: 'recovered', child: Text("Fully Recovered", style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
                      ],
                      onChanged: (val) => setDialogState(() => selectedStatus = val!),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("DISCARD")),
              ElevatedButton(
                onPressed: () async {
                  final followUp = RecoveryCheckup(
                    timestamp: DateTime.now(),
                    resultLabel: result['label'],
                    confidence: result['confidence'],
                    diseaseScore: result['diseaseScore'],
                    severity: selectedStatus,
                    imageUrl: base64Image,
                  );

                  await FirebaseFirestore.instance.collection('health_cards').doc(widget.card.id).update({
                    'status': selectedStatus,
                    'followUps': FieldValue.arrayUnion([followUp.toMap()]),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Field status updated successfully."), backgroundColor: Colors.green));
                  }
                },
                child: const Text("SAVE STATUS"),
              ),
            ],
          );
        },
      ),
    );
  }
}
