import 'package:auth_app/models/restaurant.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RestaurantMapPage extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantMapPage({
    super.key,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    final position = LatLng(restaurant.lat, restaurant.lng);

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: position,
          zoom: 16,
        ),
        markers: {
          Marker(
            markerId: MarkerId(restaurant.placeId),
            position: position,
            infoWindow: InfoWindow(
              title: restaurant.name,
              snippet: restaurant.address,
            ),
          ),
        },
      ),
    );
  }
}
