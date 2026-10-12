import 'package:cloud_firestore/cloud_firestore.dart';

class MandiPrice {
  final String id;
  final String market;
  final String commodity;
  final String pricePerKg;
  final String change;

  MandiPrice({
    required this.id,
    required this.market,
    required this.commodity,
    required this.pricePerKg,
    required this.change,
  });

  factory MandiPrice.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return MandiPrice(
      id: doc.id,
      market: data['market'] ?? '',
      commodity: data['commodity'] ?? 'Wheat',
      pricePerKg: data['pricePerKg'] ?? '0',
      change: data['change'] ?? '0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'market': market,
      'commodity': commodity,
      'pricePerKg': pricePerKg,
      'change': change,
    };
  }
}

class MandiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<MandiPrice>> getMandiPrices() {
    return _db.collection('mandi_prices').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => MandiPrice.fromFirestore(doc)).toList());
  }

  Future<void> updatePrice(String id, String market, String price, String change) {
    return _db.collection('mandi_prices').doc(id).update({
      'market': market,
      'pricePerKg': price,
      'change': change,
    });
  }

  Future<void> addMarket(String market, String price, String change) {
    return _db.collection('mandi_prices').add({
      'market': market,
      'commodity': 'Wheat',
      'pricePerKg': price,
      'change': change,
    });
  }
  
  Future<void> deleteMarket(String id) {
    return _db.collection('mandi_prices').doc(id).delete();
  }

  // Helper to initialize with default data if empty
  Future<void> initializeDefaults() async {
    var snapshot = await _db.collection('mandi_prices').get();
    if (snapshot.docs.isEmpty) {
      final List<Map<String, String>> defaults = [
        {"market": "Multan", "pricePerKg": "92.0", "change": "+0.5"},
        {"market": "Lahore", "pricePerKg": "94.5", "change": "-0.2"},
        {"market": "Faisalabad", "pricePerKg": "93.0", "change": "+1.1"},
        {"market": "Sargodha", "pricePerKg": "91.5", "change": "+0.3"},
        {"market": "Gujranwala", "pricePerKg": "93.8", "change": "-0.5"},
      ];
      for (var hub in defaults) {
        await addMarket(hub['market']!, hub['pricePerKg']!, hub['change']!);
      }
    }
  }
}
