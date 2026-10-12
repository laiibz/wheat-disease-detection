class DosageResult {
  final String chemicalName;
  final double amount;
  final double water;
  final String unit;
  final String advice;

  DosageResult({
    required this.chemicalName,
    required this.amount,
    required this.water,
    required this.unit,
    required this.advice,
  });
}

class DosageCalculator {
  static DosageResult calculate({
    required double area,
    required String areaUnit,
    required String disease,
  }) {
    // Standardize to Acres
    double acres = area;
    if (areaUnit == 'Bigha') acres = area * 0.25;
    if (areaUnit == 'Kanal') acres = area * 0.125;

    String chem = "";
    double perAcreChem = 0.0;
    double perAcreWater = 120.0; // Standard for Pakistan
    String unit = "ml";
    String advice = "";

    switch (disease) {
      case 'Yellow_Rust':
      case 'Black_Rust':
      case 'Smut':
        chem = "Tebuconazole + Azoxystrobin (Custodia)";
        perAcreChem = 200.0;
        advice = "Apply 200ml per acre. Ensure thorough coverage of the foliage, especially at the first sign of pustules.";
        break;
      case 'Aphid':
        chem = "Imidacloprid (Confidor)";
        perAcreChem = 200.0;
        perAcreWater = 100.0;
        advice = "Spray 200ml per acre when aphid population reaches the economic threshold. Best applied in early morning.";
        break;
      case 'Fusarium':
        chem = "Thiophanate-methyl (Topsin-M)";
        perAcreChem = 400.0;
        unit = "grams";
        advice = "Apply 400g per acre at the beginning of flowering (anthesis) to protect the spikes.";
        break;
      case 'Leaf_Blight':
        chem = "Difenoconazole + Azoxystrobin (Amistar Top)";
        perAcreChem = 200.0;
        perAcreWater = 100.0;
        advice = "Apply 200ml per acre when lesions are first observed to prevent spread to the flag leaf.";
        break;
      default:
        chem = "Consult Agronomist";
        advice = "No specific dosage found. Please consult with a local agriculture expert.";
    }

    return DosageResult(
      chemicalName: chem,
      amount: perAcreChem * acres,
      water: perAcreWater * acres,
      unit: unit,
      advice: advice,
    );
  }
}
