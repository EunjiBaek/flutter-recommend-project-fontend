import 'dart:convert';
import 'dart:io';
import 'package:auth_app/models/restaurant.dart';
import 'package:auth_app/providers/auth_provider.dart';
import 'package:auth_app/screens/login_page.dart';
import 'package:auth_app/screens/restaurant_map_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

String getBaseUrl() {
  if (Platform.isAndroid) {
    return "http://10.0.2.2:8000";
  } else if (Platform.isIOS) {
    return "http://localhost:8000";
  } else {
    // 나중에 운영환경으로 바꿈
    return "http://localhost:8000";
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String baseUrl = getBaseUrl();
  final TextEditingController inputController = TextEditingController();

  bool isLoading = false;
  List<Restaurant> restaurants = [];

  Future<Position> getCurrentPosition() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw Exception('위치 권한이 필요합니다.');
    }

    return await Geolocator.getCurrentPosition(
      // ignore: deprecated_member_use
      desiredAccuracy: LocationAccuracy.high,
    );
  }


  Future<void> recommendRestaurants() async {
    if (inputController.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      restaurants = [];
    });

    try {
      final position = await getCurrentPosition();

      final response = await http.post(
        Uri.parse('$baseUrl/api/restaurants/recommend'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': inputController.text.trim(),
          'lat': position.latitude,
          'lng': position.longitude,
        }),
      );

      final data = jsonDecode(response.body);

      final List items = data['restaurants'] ?? [];

      setState(() {
        restaurants = items.map((e) => Restaurant.fromJson(e)).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('추천 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(
        title: const Text('맛집 추천'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: inputController,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '예: 나 오늘 면종류가 땡겨',
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: isLoading ? null : recommendRestaurants,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading) const CircularProgressIndicator(),
            if (!isLoading && restaurants.isEmpty)
              const Text('추천받고 싶은 음식을 입력해보세요.'),
            Expanded(
              child: ListView.builder(
                itemCount: restaurants.length,
                itemBuilder: (context, index) {
                  final item = restaurants[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('⭐ ${item.rating} · ${item.distance}m'),
                          const SizedBox(height: 6),
                          Text(item.address),
                          const SizedBox(height: 10),
                          Text(
                            item.reason,
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RestaurantMapPage(
                                      restaurant: item,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.map),
                              label: const Text('지도로 보기'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
