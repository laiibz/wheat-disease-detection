import 'package:flutter/material.dart';
import '../../utils/dosage_calculator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/botanical_background.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';

class DosageCalculatorScreen extends StatefulWidget {
  final String? initialDisease;
  const DosageCalculatorScreen({super.key, this.initialDisease});

  @override
  State<DosageCalculatorScreen> createState() => _DosageCalculatorScreenState();
}

class _DosageCalculatorScreenState extends State<DosageCalculatorScreen> {
  final TextEditingController _areaController = TextEditingController();
  String _selectedUnit = 'Acre';
  String _selectedDisease = 'Yellow_Rust';
  DosageResult? _result;

  // Matching your TFLite model exactly
  final List<String> _diseases = [
    'Yellow_Rust',
    'Black_Rust',
    'Leaf_Blight',
    'Aphid',
    'Fusarium',
    'Smut'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDisease != null && _diseases.contains(widget.initialDisease)) {
      _selectedDisease = widget.initialDisease!;
    }
  }

  void _calculate() {
    if (_areaController.text.isEmpty) return;
    double area = double.tryParse(_areaController.text) ?? 0;
    if (area <= 0) return;

    setState(() {
      _result = DosageCalculator.calculate(
        area: area,
        areaUnit: _selectedUnit,
        disease: _selectedDisease,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageService>(context);

    return Scaffold(
      appBar: AppBar(title: Text(lang.translate('dosage'))),
      body: BotanicalBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputCard(theme, lang),
              const SizedBox(height: 24),
              if (_result != null) _buildResultCard(theme, lang),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(ThemeData theme, LanguageService lang) {
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Field Information", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _areaController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: const InputDecoration(labelText: "Area", hintText: "0.0", isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    isExpanded: true,
                    dropdownColor: theme.cardColor,
                    items: ['Acre', 'Bigha', 'Kanal'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) => setState(() => _selectedUnit = val!),
                    decoration: const InputDecoration(labelText: "Unit", isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedDisease,
              isExpanded: true,
              dropdownColor: theme.cardColor,
              items: _diseases.map((d) => DropdownMenuItem(value: d, child: Text(lang.translate(d)))).toList(),
              onChanged: (val) => setState(() => _selectedDisease = val!),
              decoration: const InputDecoration(labelText: "Disease", isDense: true),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("CALCULATE"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme, LanguageService lang) {
    return Card(
      color: theme.colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recommended Plan", style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const Divider(height: 20),
            _buildRow("Medicine", _result!.chemicalName, theme),
            _buildRow("Amount", "${_result!.amount.toStringAsFixed(0)} ${_result!.unit}", theme),
            _buildRow("Water", "${_result!.water.toStringAsFixed(0)} Liters", theme),
            const SizedBox(height: 16),
            Text(_result!.advice, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
