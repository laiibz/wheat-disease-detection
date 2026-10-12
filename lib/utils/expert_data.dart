class ExpertInfo {
  final String name;
  final String role;
  final String phone;
  final String email;
  final String imageUrl;
  final String specialization;

  ExpertInfo({
    required this.name,
    required this.role,
    required this.phone,
    required this.email,
    required this.imageUrl,
    required this.specialization,
  });
}

class ExpertData {
  // Using a professional placeholder for AgroOne Experts
  static const String _logoUrl = "https://images.unsplash.com/photo-1594776208137-aa2d9d3d4ca3?w=400";

  static final List<ExpertInfo> experts = [
    ExpertInfo(
      name: "Waajid Tanveer",
      role: "CEO AgroOne",
      phone: "03009643579",
      email: "waajidtanveer@gmail.com",
      imageUrl: _logoUrl,
      specialization: "Director Sales & Marketing",
    ),
    ExpertInfo(
      name: "Maghfoor Shahid",
      role: "Zonal Manager AgroOne",
      phone: "03345116735",
      email: "maghfoorshahid@gmail.com",
      specialization: "Narowal Region",
      imageUrl: _logoUrl,
    ),
    ExpertInfo(
      name: "Saifullah",
      role: "Zonal Manager AgroOne",
      phone: "03004429726",
      email: "saifullah@gmail.com",
      specialization: "Bhalwal Region",
      imageUrl: _logoUrl,
    ),
  ];
}
