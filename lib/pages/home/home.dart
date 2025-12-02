import 'dart:async'; // 👈 thêm

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frontend_daktmt/apis/api_refreshtoken.dart';
import 'package:frontend_daktmt/apis/api_home.dart'; // 👈 thêm
import 'package:frontend_daktmt/custom_card.dart';
import 'package:frontend_daktmt/pages/home/widget/chart.dart';
import 'package:frontend_daktmt/pages/home/widget/map.dart';
import 'package:frontend_daktmt/pages/home/widget/toggle.dart';
import 'package:frontend_daktmt/responsive.dart';
import 'package:frontend_daktmt/nav_bar/nav_bar_left.dart';
import 'package:frontend_daktmt/nav_bar/nav_bar_right.dart';
import 'package:latlong2/latlong.dart'; // 👈 dùng cho fetchLocationData
// import 'package:frontend_daktmt/widgets/cabinet_selector_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widget/gauge.dart';
import 'package:frontend_daktmt/pages/noitification/noitification.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double humidity = 0.0;
  double temperature = 0.0;
  double latitude = 0.0;
  double longitude = 0.0;
  String token = "";

  List<FlSpot> humiditySpots = [];
  List<String> dates = [];
  bool loading = true;

  Timer? _sensorTimer; // 👈 timer tự update sau 10 phút

  @override
  void initState() {
    super.initState();
    // Load nhanh từ SharedPreferences (overview sau khi chọn tủ)
    _loadFromPrefsOnce();

    // Gọi API lần đầu để có dữ liệu mới nhất
    fetchSensorData();

    // Timer refresh token toàn app (trong api_refreshtoken.dart)
    startRefreshTokenTimer();

    // Tự động gọi API sensor mỗi 10 phút
    _sensorTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      fetchSensorData();
    });
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();
    super.dispose();
  }

  /// Lần đầu vào Home: đọc dữ liệu đã lưu sẵn từ SharedPreferences
  Future<void> _loadFromPrefsOnce() async {
    logger.i("Loading sensor data from SharedPreferences");
    try {
      final prefs = await SharedPreferences.getInstance();

      token = prefs.getString('accessToken') ?? '';
      final double humidityData = prefs.getDouble('humidity') ?? 0.0;
      final double temperatureData = prefs.getDouble('temperature') ?? 0.0;

      String? savedLocation = prefs.getString('location');
      if (savedLocation == null || savedLocation.isEmpty) {
        logger
            .w("No location in SharedPreferences. Using default value (Thu Duc).");
        savedLocation = "10.8797474-106.8064651";
      }

      final List<String> coordinates = savedLocation.split('-');
      double fetchedLatitude = 0.0;
      double fetchedLongitude = 0.0;

      if (coordinates.length == 2) {
        fetchedLatitude = double.tryParse(coordinates[0]) ?? 0.0;
        fetchedLongitude = double.tryParse(coordinates[1]) ?? 0.0;
      } else {
        logger.e("Invalid location format in prefs: $savedLocation");
      }

      if (!mounted) return;
      setState(() {
        humidity = humidityData;
        temperature = temperatureData;
        latitude = fetchedLatitude;
        longitude = fetchedLongitude;
      });
    } catch (error) {
      logger.e("Error loading sensor data from prefs: $error");
    }
  }

  /// Gọi API theo cabinetId hiện tại, sau đó cập nhật state + prefs
  Future<void> fetchSensorData() async {
    logger.i("Fetching sensor data from API started");
    try {
      final prefs = await SharedPreferences.getInstance();

      token = prefs.getString('accessToken') ?? '';
      final String? cabinetId = prefs.getString('selectedCabinetId');

      if (token.isEmpty || cabinetId == null) {
        logger.w(
            "Missing token or selectedCabinetId. token: ${token.isNotEmpty}, cabinetId: $cabinetId");
        return;
      }

      // Gọi 3 API song song
      final results = await Future.wait([
        fetchHumidityData(token, cabinetId),
        fetchTemperatureData(token, cabinetId),
        fetchLocationData(token, cabinetId),
      ]);

      final double newHumidity = results[0] as double;
      final double newTemperature = results[1] as double;
      final LatLng newLocation = results[2] as LatLng;

      if (!mounted) return;
      setState(() {
        humidity = newHumidity;
        temperature = newTemperature;
        latitude = newLocation.latitude;
        longitude = newLocation.longitude;
      });
    } catch (error) {
      logger.e("Error fetching sensor data from API: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);
    final double gaugeHeight = isMobile ? 200.0 : 150.0;
    final double gaugeWidth = isMobile ? double.infinity : 100.0;
    final bool isRowLayout = isDesktop;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      drawer: const Navbar_left(),
      endDrawer: const Navbar_right(
          // profileData: {},
          ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height: isRowLayout ? MediaQuery.of(context).size.height : null,
              decoration: backgound_Color(),
              child: Padding(
                padding: EdgeInsets.only(right: isMobile ? 0.0 : 50.0),
                child: isRowLayout
                    ? Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                            child: SizedBox(
                              width: 300,
                              height: MediaQuery.of(context).size.height,
                              child: const Navbar_left(),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: VerticalDivider(
                              width: 1,
                              thickness: 2,
                              color: Color.fromARGB(255, 17, 163, 212),
                              indent: 20,
                              endIndent: 20,
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                children: [
                                  const SizedBox(height: 70),
                                    // CabinetSelectorBar(
                                    //     onCabinetChanged: (id, name) {
                                    //       // Khi đổi tủ -> gọi lại fetchSensorData (đã đọc từ SharedPreferences)
                                    //       fetchSensorData();
                                    //     },
                                    //   ),
                                    Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Column(
                                                  children: [
                                                    toggle(
                                                      toggleHeight: 150.0,
                                                      toggleWidth:
                                                          screenWidth * 0.44,
                                                      numOfRelay: 6,
                                                    ),
                                                    latitude == 0.0 &&
                                                            longitude == 0.0
                                                        ? const Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          )
                                                        : map(
                                                            mapHeight: 350.0,
                                                            mapWidth: 1000,
                                                            latitude: latitude,
                                                            longitude:
                                                                longitude,
                                                          ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                flex: 2,
                                                child: Column(
                                                  children: [
                                                    tempgauge(
                                                      gaugeHeight: 200.0,
                                                      gaugeWidth: 600,
                                                      value: temperature,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    humigauge(
                                                      gaugeHeight: 200.0,
                                                      gaugeWidth: 600,
                                                      value: humidity,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Chart(
                                                  token: token,
                                                  label: 'Temperature',
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Chart(
                                                  token: token,
                                                  label: 'Humidity',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          const SizedBox(height: 100.0),
                            // CabinetSelectorBar(
                            //   onCabinetChanged: (id, name) {
                            //     fetchSensorData();
                            //   },
                            // ),
                          const toggle(
                            toggleHeight: 270.0,
                            toggleWidth: 350.0,
                            numOfRelay: 3,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10.0),
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(195, 243, 243, 243),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(17.0),
                              ),
                            ),
                            child: Column(
                              children: [
                                tempgauge(
                                  gaugeHeight: gaugeHeight,
                                  gaugeWidth: gaugeWidth,
                                  value: temperature,
                                ),
                                const SizedBox(height: 20),
                                humigauge(
                                  gaugeHeight: gaugeHeight,
                                  gaugeWidth: gaugeWidth,
                                  value: humidity,
                                ),
                                const SizedBox(height: 20),
                                latitude == 0.0 && longitude == 0.0
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : map(
                                        mapHeight: 350.0,
                                        mapWidth: 1000,
                                        latitude: latitude,
                                        longitude: longitude,
                                      ),
                                const SizedBox(height: 20),
                                Chart(
                                  token: token,
                                  label: 'Humidity',
                                ),
                                const SizedBox(height: 20),
                                Chart(
                                  token: token,
                                  label: 'Temperature',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const navbarleft_set(),
            const noitification_setting(),
            const nabarright_set(),
          ],
        ),
      ),
    );
  }
}
