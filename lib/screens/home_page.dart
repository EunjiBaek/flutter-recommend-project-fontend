import 'dart:convert';
import 'dart:io';
import 'package:auth_app/components/%20%20common_app_bar.dart';
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
  Map<String, dynamic>? intent;
  List<Restaurant> restaurants = [];

  Future<Position> getCurrentPosition() async {
// 1️⃣ 위치 서비스 켜져있는지 확인
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('위치 서비스가 꺼져 있습니다.');
    }

    // 2️⃣ 현재 권한 상태 확인
    LocationPermission permission = await Geolocator.checkPermission();

    // 3️⃣ 권한 없으면 요청
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 4️⃣ 완전 거부된 경우
    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 영구적으로 거부되었습니다. 설정에서 허용해주세요.');
    }

    // 5️⃣ 여전히 거부된 경우
    if (permission == LocationPermission.denied) {
      throw Exception('위치 권한이 필요합니다.');
    }

    return await Geolocator.getCurrentPosition(
      // ignore: deprecated_member_use
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> recommendRestaurants() async {
    final message = inputController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      isLoading = true;
      restaurants = [];
      intent = null;
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
          'message': message,
          'lat': position.latitude,
          'lng': position.longitude,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? '추천 요청 실패');
      }

      final List items = data['restaurants'] ?? [];

      setState(() {
        intent = data['intent'];
        restaurants = items.map((e) => Restaurant.fromJson(e)).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('추천 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: const CommonAppBar(title: '맛집 추천'),
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
            if (intent != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // 연한 파랑
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${intent?['mood'] ?? ''} · ${intent?['recommendType'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (restaurants.isNotEmpty)
                      Text(
                        restaurants.first.reason,
                        style: const TextStyle(
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: ListView.builder(
                itemCount: restaurants.length,
                itemBuilder: (context, index) {
                  final item = restaurants[index];

                  return Card(
                    color: Colors.white,
                    elevation: 2, // 🔥 핵심
                    shadowColor: Colors.black12,
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
