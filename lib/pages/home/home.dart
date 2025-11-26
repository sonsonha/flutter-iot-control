import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frontend_daktmt/apis/api_refreshtoken.dart';
import 'package:frontend_daktmt/custom_card.dart';
import 'package:frontend_daktmt/pages/home/widget/chart.dart';
import 'package:frontend_daktmt/pages/home/widget/map.dart';
import 'package:frontend_daktmt/pages/home/widget/toggle.dart';
import 'package:frontend_daktmt/responsive.dart';
import 'package:frontend_daktmt/nav_bar/nav_bar_left.dart';
import 'package:frontend_daktmt/nav_bar/nav_bar_right.dart';
// import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widget/gauge.dart';
// import 'package:frontend_daktmt/apis/api_page.dart';
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

  @override
  void initState() {
    super.initState();
    // fetchRefreshToken();
    fetchSensorData();
    startRefreshTokenTimer(fetchSensorData);
  }

  Future<void> fetchSensorData() async {
    logger.i("Fetching sensor data started");
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      token = prefs.getString('accessToken')!;
      double humidityData = prefs.getDouble('humidity') ?? 0.0;
      double temperatureData = prefs.getDouble('temperature') ?? 0.0;
      // print("TOKEN IN HOMESCREEN BEFORE CHART: $token");

      String? savedLocation = prefs.getString('location');
      if (savedLocation == null || savedLocation.isEmpty) {
        logger
            .w("No location found in SharedPreferences. Using default value.");
        savedLocation = "10.8797474-106.8064651";
      }

      List<String> coordinates = savedLocation.split('-');
      if (coordinates.length == 2) {
        double fetchedLatitude = double.tryParse(coordinates[0]) ?? 0.0;
        double fetchedLongitude = double.tryParse(coordinates[1]) ?? 0.0;
        if (mounted) {
          setState(() {
            humidity = humidityData;
            temperature = temperatureData;
            latitude = fetchedLatitude;
            longitude = fetchedLongitude;
          });
        }
      } else {
        logger.e("Invalid location format: $savedLocation");
      }
    } catch (error) {
      logger.e("Error fetching sensor data: $error");
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
                                child: const Navbar_left()),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: VerticalDivider(
                              width: 1,
                              thickness: 2,
                              // color: Color.fromARGB(255, 202, 202, 202),
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
                                  Expanded(
                                    // Thêm Expanded ở đây
                                    child: SingleChildScrollView(
                                      // Bọc Column trong SingleChildScrollView
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
                                                      toggleWidth: screenWidth * 0.44,
                                                      numOfRelay: 6,
                                                    ),
                                                    latitude == 0.0 && longitude == 0.0
                                                        ? const Center(
                                                            child: CircularProgressIndicator())
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
                                        child: CircularProgressIndicator())
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
