import 'package:flutter/material.dart';
import '../../services/mandi_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/botanical_background.dart';

class ManagePricesScreen extends StatefulWidget {
  const ManagePricesScreen({super.key});

  @override
  State<ManagePricesScreen> createState() => _ManagePricesScreenState();
}

class _ManagePricesScreenState extends State<ManagePricesScreen> {
  final MandiService _mandiService = MandiService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Wheat Prices"),
      ),
      body: BotanicalBackground(
        child: StreamBuilder<List<MandiPrice>>(
          stream: _mandiService.getMandiPrices(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("No markets found", style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _mandiService.initializeDefaults(),
                      child: const Text("Initialize Defaults"),
                    )
                  ],
                ),
              );
            }

            final prices = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: prices.length,
              itemBuilder: (context, index) {
                final price = prices[index];
                return _buildPriceCard(price, theme);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(null),
        backgroundColor: AppTheme.goldAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildPriceCard(MandiPrice price, ThemeData theme) {
    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(price.market, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("Price: ${price.pricePerKg} | Change: ${price.change}", 
                     style: const TextStyle(color: Colors.white70)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.sageGreen),
              onPressed: () => _showEditDialog(price),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _mandiService.deleteMarket(price.id),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(MandiPrice? price) {
    final marketController = TextEditingController(text: price?.market ?? '');
    final priceController = TextEditingController(text: price?.pricePerKg ?? '');
    final changeController = TextEditingController(text: price?.change ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkBotanicalGreen,
        title: Text(price == null ? "Add Market" : "Edit Price", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: marketController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Market/City Name", labelStyle: TextStyle(color: Colors.white70)),
            ),
            TextField(
              controller: priceController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(labelText: "Price (e.g. Rs. 95.0)", labelStyle: TextStyle(color: Colors.white70)),
            ),
            TextField(
              controller: changeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Price Change (e.g. +1.2 or -0.5)", labelStyle: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (price == null) {
                _mandiService.addMarket(
                  marketController.text,
                  priceController.text,
                  changeController.text,
                );
              } else {
                _mandiService.updatePrice(
                  price.id,
                  marketController.text,
                  priceController.text,
                  changeController.text,
                );
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
