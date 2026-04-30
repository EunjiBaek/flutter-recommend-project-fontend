class Restaurant {
  final String name;
  final double rating;
  final String address;
  final String placeId;
  final int distance;
  final String reason;
  final double lat;
  final double lng;

  Restaurant({
    required this.name,
    required this.rating,
    required this.address,
    required this.placeId,
    required this.distance,
    required this.reason,
    required this.lat,
    required this.lng,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      name: json['name'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      address: json['address'] ?? '',
      placeId: json['placeId'] ?? '',
      distance: json['distance'] ?? 0,
      reason: json['reason'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }
}
