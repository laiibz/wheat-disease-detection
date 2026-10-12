class DiseaseRisk {
  final String name;
  final double riskLevel; // 0.0 to 1.0
  final String advice;

  DiseaseRisk({required this.name, required this.riskLevel, required this.advice});
}

class RiskCalculator {
  static bool isWheatSeason() {
    final month = DateTime.now().month;
    // Pakistan Wheat (Rabi) Season: Oct (10) to April (4)
    // Sowing: Oct-Nov, Harvest: Mar-Apr
    return (month >= 10 || month <= 4);
  }

  static List<DiseaseRisk> calculateRisks(double temp, int humidity) {
    // If it's not wheat season, return zero risk for all
    if (!isWheatSeason()) {
      return [
        DiseaseRisk(
          name: "Off-Season",
          riskLevel: 0.0,
          advice: "Currently off-season for Wheat in Pakistan. No active disease threats detected.",
        )
      ];
    }

    List<DiseaseRisk> risks = [];

    // 1. Yellow Rust (Cool/Moist)
    double yellowRustRisk = 0.0;
    if (temp >= 8 && temp <= 18) {
      yellowRustRisk += 0.5;
      if (humidity > 70) yellowRustRisk += 0.4;
    }
    risks.add(DiseaseRisk(
      name: "Yellow Rust",
      riskLevel: yellowRustRisk.clamp(0.0, 1.0),
      advice: "Cool and moist weather favors Yellow Rust. Check lower leaves for yellow pustules.",
    ));

    // 2. Black Rust (Warm/Humid)
    double blackRustRisk = 0.0;
    if (temp >= 15 && temp <= 30) {
      blackRustRisk += 0.4;
      if (humidity > 60) blackRustRisk += 0.4;
    }
    risks.add(DiseaseRisk(
      name: "Black Rust",
      riskLevel: blackRustRisk.clamp(0.0, 1.0),
      advice: "Warm and humid conditions. Watch for dark brown/black spots on stems.",
    ));

    // 3. Leaf Blight
    double leafBlightRisk = 0.0;
    if (temp >= 20 && temp <= 32) {
      leafBlightRisk += 0.4;
      if (humidity > 75) leafBlightRisk += 0.5;
    }
    risks.add(DiseaseRisk(
      name: "Leaf Blight",
      riskLevel: leafBlightRisk.clamp(0.0, 1.0),
      advice: "High humidity and warmth increase Blight risk. Ensure proper drainage.",
    ));

    // 4. Fusarium Head Blight
    double fusariumRisk = 0.0;
    if (temp >= 20 && temp <= 26) {
      if (humidity > 80) fusariumRisk = 0.9;
      else if (humidity > 60) fusariumRisk = 0.5;
    }
    risks.add(DiseaseRisk(
      name: "Fusarium",
      riskLevel: fusariumRisk.clamp(0.0, 1.0),
      advice: "Warm, rainy weather during flowering is critical for Fusarium.",
    ));

    // 5. Smut
    double smutRisk = 0.0;
    if (temp >= 15 && temp <= 22 && humidity > 60) {
      smutRisk = 0.7;
    }
    risks.add(DiseaseRisk(
      name: "Smut",
      riskLevel: smutRisk.clamp(0.0, 1.0),
      advice: "Avoid overhead irrigation during flowering if Smut risk is high.",
    ));

    // 6. Aphids (Dry/Warm)
    double aphidRisk = 0.0;
    if (temp >= 18 && temp <= 28) {
      aphidRisk += 0.4;
      if (humidity < 50) aphidRisk += 0.4;
    }
    risks.add(DiseaseRisk(
      name: "Aphids",
      riskLevel: aphidRisk.clamp(0.0, 1.0),
      advice: "Dry and warm weather favors Aphid colonies. Check the spikes.",
    ));

    // Sort by highest risk
    risks.sort((a, b) => b.riskLevel.compareTo(a.riskLevel));
    return risks;
  }
}
