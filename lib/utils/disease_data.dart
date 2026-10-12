class DiseaseInfo {
  final String description;
  final String symptoms;
  final String timing;
  final String treatment;
  final String prevention;
  final String imageUrl;
  final String recommendedMedicine;
  final String medicineImageUrl;

  DiseaseInfo({
    required this.description,
    required this.symptoms,
    required this.timing,
    required this.treatment,
    required this.prevention,
    required this.imageUrl,
    this.recommendedMedicine = "N/A",
    this.medicineImageUrl = "https://via.placeholder.com/150",
  });
}

class DiseaseData {
  static String normalize(String key) {
    return key.trim().replaceAll(" ", "_");
  }

  static final Map<String, DiseaseInfo> details = {
    "Aphid": DiseaseInfo(
      description: "Aphids (Susti/Sust Tela) are pear-shaped, soft-bodied insects that suck sap from the tender parts of the wheat plant, especially the ears (spikes). They excrete a sticky substance called honeydew, which leads to the growth of sooty mold, reducing photosynthesis.",
      symptoms: "Yellowing and curling of leaves, stunted plant growth, and sticky leaves. In severe infestations, the wheat ears fail to fill properly, resulting in shriveled grains.",
      timing: "Late January to early April, peaking when temperatures are between 15°C and 25°C. Populations explode during dry spells.",
      treatment: "If the population exceeds the economic threshold (5 aphids per tiller), apply systemic insecticides.",
      prevention: "Avoid over-application of nitrogenous fertilizers. Conserve natural enemies like Ladybird beetles and Hoverfly larvae.",
      imageUrl: "assets/images/diseases/aphid.jpg",
      recommendedMedicine: "Imidacloprid (Confidor) - 200ml/acre.",
      medicineImageUrl: "https://www.bayer.com.pk/sites/g/files/ywv721/f/styles/product_image/public/2022/10/Confidor.png",
    ),
    "Black_Rust": DiseaseInfo(
      description: "Stem Rust or Black Rust is a highly destructive fungal disease caused by Puccinia graminis. It attacks the stems and leaf sheaths, disrupting the flow of water and nutrients to the developing grain.",
      symptoms: "Elongated, reddish-brown to black pustules (uredinia) that erupt through the epidermis of the stem and leaf sheath. Stems often become brittle and break (lodge).",
      timing: "Usually appears late in the season (March-April) when temperatures rise above 20°C and humidity is high.",
      treatment: "Apply triazole-based fungicides immediately upon detection of the first pustules.",
      prevention: "Plant resistant wheat varieties (e.g., Akbar-19, Dilkash). Remove barberry bushes (alternate host) and avoid late sowing.",
      imageUrl: "assets/images/diseases/black_rust.jpg",
      recommendedMedicine: "Tebuconazole + Azoxystrobin (Custodia) - 200ml/acre.",
      medicineImageUrl: "https://via.placeholder.com/150",
    ),
    "Fusarium": DiseaseInfo(
      description: "Fusarium Head Blight (FHB) or Scab is a fungal disease that affects the wheat spike. It is particularly dangerous because it produces mycotoxins (like DON) that are toxic to humans and animals.",
      symptoms: "Bleaching of individual spikelets or the entire head while the rest of the plant is green. In humid conditions, pinkish-orange spores may be visible at the base of the glumes.",
      timing: "Infection occurs during the flowering stage (anthesis) when weather is warm and wet (rain or high humidity).",
      treatment: "Timed application of fungicides at the beginning of anthesis is critical. Post-infection treatments are less effective.",
      prevention: "Crop rotation with non-cereal crops. Deep plowing to bury crop residues. Use certified, fungicide-treated seeds.",
      imageUrl: "assets/images/diseases/fusarium.jpg",
      recommendedMedicine: "Thiophanate-methyl (Topsin-M) - 400g/acre.",
      medicineImageUrl: "https://via.placeholder.com/150",
    ),
    "Healthy": DiseaseInfo(
      description: "The crop shows no signs of disease or pest infestation. Proper management including timely sowing, balanced fertilization, and adequate irrigation ensures a healthy yield.",
      symptoms: "Uniform green color, sturdy stems, and fully developed spikes. No visible lesions or pests.",
      timing: "Maintaining health throughout the growth cycle from November to April.",
      treatment: "No medicinal treatment required. Continue regular monitoring and irrigation.",
      prevention: "Practice Integrated Pest Management (IPM) and maintain soil health through balanced NPK application.",
      imageUrl: "assets/images/diseases/healthy.jpg",
      recommendedMedicine: "Balanced Nutrition: Urea, DAP, and Potash as per soil requirements.",
      medicineImageUrl: "https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=500",
    ),
    "Leaf_Blight": DiseaseInfo(
      description: "Leaf Blight (Helminthosporium) is characterized by the formation of necrotic spots on the leaves. It reduces the photosynthetic area, leading to lower grain weight.",
      symptoms: "Small, oval, dark brown spots with a yellow halo. Spots enlarge and coalesce, eventually killing large areas of the leaf tissue, giving it a burnt appearance.",
      timing: "Common during the grain-filling stage (March) in conditions of high humidity and temperatures between 20°C and 25°C.",
      treatment: "Spray broad-spectrum fungicides if the disease starts moving up the plant toward the flag leaf.",
      prevention: "Use disease-free seed. Treat seeds with systemic fungicides. Ensure proper plant spacing for better aeration.",
      imageUrl: "assets/images/diseases/leaf_blight.jpeg",
      recommendedMedicine: "Difenoconazole + Azoxystrobin (Amistar Top) - 200ml/acre.",
      medicineImageUrl: "https://www.syngenta.pk/sites/g/files/zhg446/f/styles/syngenta_product_detail/public/2021/04/12/amistar_top.png?itok=v_M3yFmE",
    ),
    "Smut": DiseaseInfo(
      description: "Loose Smut is a seed-borne disease where the grains are replaced by a black, powdery mass of fungal spores. It is often not detected until heading.",
      symptoms: "The entire head is transformed into a mass of black spores. The spores are easily dispersed by wind, leaving only the bare rachis (stem) of the head.",
      timing: "Visible at the time of heading (February-March). Infection occurs during flowering in the previous generation.",
      treatment: "Foliar sprays are not effective. Seed treatment is the only effective chemical control.",
      prevention: "Mandatory seed treatment with systemic fungicides. Use of certified disease-free seeds.",
      imageUrl: "assets/images/diseases/smut.jpg",
      recommendedMedicine: "Tebuconazole + Azoxystrobin (Custodia) - 200ml/acre.",
      medicineImageUrl: "https://via.placeholder.com/150",
    ),
    "Yellow_Rust": DiseaseInfo(
      description: "Yellow Rust (Stripe Rust) is one of the most significant threats to wheat in Pakistan. It spreads via wind and can cause up to 50% yield loss in susceptible varieties.",
      symptoms: "Small, bright yellow pustules arranged in linear rows (stripes) on the leaves. A yellow dust (spores) easily rubs off onto fingers or clothing.",
      timing: "Cool, moist weather (10°C–15°C) from January to March. Heavy dews or intermittent rain favor rapid spread.",
      treatment: "Immediate application of triazole fungicides is necessary as soon as the first stripes are observed.",
      prevention: "Sow rust-resistant varieties. Avoid late-season irrigation if rust is present. Do not use over-doses of Urea.",
      imageUrl: "assets/images/diseases/yellow_rust.jpg",
      recommendedMedicine: "Tebuconazole + Azoxystrobin (Custodia) - 200ml/acre.",
      medicineImageUrl: "https://via.placeholder.com/150",
    ),
  };

  static final DiseaseInfo unknownDisease = DiseaseInfo(
    description: "No specific information available for this category.",
    symptoms: "Identification inconclusive.",
    timing: "-",
    treatment: "Consult a local agriculture extension officer.",
    prevention: "General field hygiene.",
    imageUrl: "https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=500",
    recommendedMedicine: "Consult Expert",
    medicineImageUrl: "https://via.placeholder.com/150",
  );

  static DiseaseInfo getInfo(String label) {
    final normalized = normalize(label);
    return details[normalized] ?? unknownDisease;
  }
}
