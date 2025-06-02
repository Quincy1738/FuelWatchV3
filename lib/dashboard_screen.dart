import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_page.dart';
import 'settings_page.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  List<double> last30DaysTotalRevenue = List.filled(30, 0.0);
  List<double> last12MonthsTotalRevenue = List.filled(12, 0.0);

  double dieselRevenue = 0.0;
  double petrolRevenue = 0.0;

  double dieselLiters = 0.0;
  double dieselPrice = 0.0;
  double petrolLiters = 0.0;
  double petrolPrice = 0.0;

  double totalRevenue = 0.0;

  double maxDieselCapacity = 10000;
  double maxPetrolCapacity = 10000;
  double lowThresholdPercent = 0.25;

  final TextEditingController _dieselLitersController = TextEditingController();
  final TextEditingController _dieselPriceController = TextEditingController();
  final TextEditingController _petrolLitersController = TextEditingController();
  final TextEditingController _petrolPriceController = TextEditingController();

  Timer? _reductionTimer;

  List<double> last7DaysTotalRevenue = List.filled(7, 0.0);
  int todayIndex = 6;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadSavedData();
    _startAutoReduction();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    _checkAndShowAlerts();
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fuel_alert_channel',
      'Fuel Alerts',
      channelDescription: 'Notifications for low fuel alerts',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(0, title, body, platformDetails);
  }

  void _checkAndShowAlerts() {
    if ((dieselLiters / maxDieselCapacity) < lowThresholdPercent) {
      _showNotification("Low Diesel Alert", "Diesel tank below 25% capacity!");
    }
    if ((petrolLiters / maxPetrolCapacity) < lowThresholdPercent) {
      _showNotification("Low Petrol Alert", "Petrol tank below 25% capacity!");
    }
  }

  void _startAutoReduction() {
    _reductionTimer = Timer.periodic(Duration(seconds: 60), (_) {
      setState(() {
        int dieselReduction = 5 + Random().nextInt(46);
        int petrolReduction = 5 + Random().nextInt(46);

        if (dieselReduction + petrolReduction > 100) {
          int excess = (dieselReduction + petrolReduction) - 100;
          if (dieselReduction > petrolReduction) {
            dieselReduction = (dieselReduction - excess).clamp(0, dieselReduction);
          } else {
            petrolReduction = (petrolReduction - excess).clamp(0, petrolReduction);
          }
        }

        dieselLiters = (dieselLiters - dieselReduction).clamp(0, maxDieselCapacity);
        petrolLiters = (petrolLiters - petrolReduction).clamp(0, maxPetrolCapacity);

        _checkAndShowAlerts();
        _saveData();
      });
    });
  }

  @override
  void dispose() {
    _reductionTimer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _addDieselRevenue(double liters, double price) {
    double revenue = liters * price;
    setState(() {
      dieselRevenue += revenue;
      totalRevenue += revenue;
      last7DaysTotalRevenue[todayIndex] += revenue;
      _checkAndShowAlerts();
      _saveData();
    });
  }

  void _addPetrolRevenue(double liters, double price) {
    double revenue = liters * price;
    setState(() {
      petrolRevenue += revenue;
      totalRevenue += revenue;
      last7DaysTotalRevenue[todayIndex] += revenue;
      _checkAndShowAlerts();
      _saveData();
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('dieselLiters', dieselLiters);
    await prefs.setDouble('dieselPrice', dieselPrice);
    await prefs.setDouble('petrolLiters', petrolLiters);
    await prefs.setDouble('petrolPrice', petrolPrice);
    await prefs.setDouble('dieselRevenue', dieselRevenue);
    await prefs.setDouble('petrolRevenue', petrolRevenue);
    await prefs.setDouble('totalRevenue', totalRevenue);
    await prefs.setStringList('last7DaysTotalRevenue', last7DaysTotalRevenue.map((e) => e.toString()).toList());
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      dieselLiters = prefs.getDouble('dieselLiters') ?? 0.0;
      dieselPrice = prefs.getDouble('dieselPrice') ?? 0.0;
      petrolLiters = prefs.getDouble('petrolLiters') ?? 0.0;
      petrolPrice = prefs.getDouble('petrolPrice') ?? 0.0;
      dieselRevenue = prefs.getDouble('dieselRevenue') ?? 0.0;
      petrolRevenue = prefs.getDouble('petrolRevenue') ?? 0.0;
      totalRevenue = prefs.getDouble('totalRevenue') ?? 0.0;

      List<String>? savedList = prefs.getStringList('last7DaysTotalRevenue');
      if (savedList != null && savedList.length == 7) {
        last7DaysTotalRevenue = savedList.map((e) => double.tryParse(e) ?? 0.0).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardContent(),
          AnalyticsPage(
            totalRevenue: totalRevenue,
            last7DaysRevenue: last7DaysTotalRevenue,
            last30DaysRevenue: last30DaysTotalRevenue,
            last12MonthsRevenue: last12MonthsTotalRevenue,
          ),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Analytics"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Fuel Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTankStatus("Diesel", dieselLiters, maxDieselCapacity, Icons.local_gas_station),
            _buildTankStatus("Petrol", petrolLiters, maxPetrolCapacity, Icons.local_gas_station_outlined),
          ],
        ),
        SizedBox(height: 20),
        _buildInputSection(),
        SizedBox(height: 20),
        _buildAnalyticsCard(),
        SizedBox(height: 20),
        _buildAlertSection(),
      ]),
    );
  }

  Widget _buildTankStatus(String label, double liters, double maxLiters, IconData icon) {
    double percent = liters / maxLiters;
    bool isLow = percent < lowThresholdPercent;

    return Expanded(
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isLow ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    child: Icon(icon, color: isLow ? Colors.red : Colors.green),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "$label Tank",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                "${liters.toStringAsFixed(0)} L",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 8),
              LinearPercentIndicator(
                lineHeight: 10.0,
                percent: percent.clamp(0, 1),
                animation: true,
                backgroundColor: Colors.grey[300]!,
                progressColor: isLow ? Colors.red : Colors.green,
                barRadius: Radius.circular(12),
              ),
              SizedBox(height: 8),
              Text(
                "${(percent * 100).toStringAsFixed(1)}% Full",
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Update Tank Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(height: 10),
        _buildFuelInput(
          label: "Diesel",
          icon: Icons.local_gas_station,
          color: Colors.blue.shade700,
          literCtrl: _dieselLitersController,
          priceCtrl: _dieselPriceController,
          onEnter: () {
            double? inputPrice = double.tryParse(_dieselPriceController.text);
            if (inputPrice == null || inputPrice <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a valid diesel price per liter.")));
              return;
            }
            double inputLiters = double.tryParse(_dieselLitersController.text) ?? 0.0;

            if (dieselLiters + inputLiters > maxDieselCapacity) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Diesel tank is full.")));
            } else {
              setState(() {
                dieselLiters += inputLiters;
                dieselPrice = inputPrice;
                _addDieselRevenue(inputLiters, inputPrice);
                _dieselLitersController.clear();
                _dieselPriceController.clear();
                _saveData();
              });
            }
          },
        ),
        SizedBox(height: 12),
        _buildFuelInput(
          label: "Petrol",
          icon: Icons.local_gas_station_outlined,
          color: Colors.orange.shade700,
          literCtrl: _petrolLitersController,
          priceCtrl: _petrolPriceController,
          onEnter: () {
            double? inputPrice = double.tryParse(_petrolPriceController.text);
            if (inputPrice == null || inputPrice <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a valid petrol price per liter.")));
              return;
            }
            double inputLiters = double.tryParse(_petrolLitersController.text) ?? 0.0;

            if (petrolLiters + inputLiters > maxPetrolCapacity) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Petrol tank is full.")));
            } else {
              setState(() {
                petrolLiters += inputLiters;
                petrolPrice = inputPrice;
                _addPetrolRevenue(inputLiters, inputPrice);
                _petrolLitersController.clear();
                _petrolPriceController.clear();
                _saveData();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildFuelInput({
    required String label,
    required IconData icon,
    required Color color,
    required TextEditingController literCtrl,
    required TextEditingController priceCtrl,
    required VoidCallback onEnter,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
                SizedBox(width: 12),
                Text("$label Fuel Input", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: literCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Liters Available",
                prefixIcon: Icon(Icons.scale),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: color, width: 2), borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Price per Liter",
                prefixIcon: Icon(Icons.price_change),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: color, width: 2), borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.local_gas_station),
                label: Text("Add $label"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onEnter,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Analytics",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            SizedBox(height: 12),
            _buildAnalyticsItem(
              icon: Icons.local_gas_station,
              label: "Diesel Sales",
              amount: dieselRevenue,
              color: Colors.blue,
            ),
            SizedBox(height: 8),
            _buildAnalyticsItem(
              icon: Icons.local_gas_station_outlined,
              label: "Petrol Sales",
              amount: petrolRevenue,
              color: Colors.orange,
            ),
            Divider(height: 32, thickness: 1.2),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200.withOpacity(0.6),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    SizedBox(width: 12),
                    Text(
                      "Total Sales",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ]),
                  Text(
                    "₱${totalRevenue.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsItem({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        Text(
          "₱${amount.toStringAsFixed(2)}",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }


  Widget _buildAlertSection() {
    List<Widget> alerts = [];

    // Thresholds
    const double lowThresholdPercent = 0.25;

    // Example variables (you should use your actual values)
    final dieselRatio = dieselLiters / maxDieselCapacity;
    final petrolRatio = petrolLiters / maxPetrolCapacity;

    // Add low fuel alerts with styling
    if (dieselRatio < lowThresholdPercent) {
      alerts.add(_buildAlertTile(
        "Low Fuel Alert",
        "Diesel tank below 25%",
        Icons.warning_amber_rounded,
        Colors.red.shade100,
        Colors.red.shade700,
      ));
    }
    if (petrolRatio < lowThresholdPercent) {
      alerts.add(_buildAlertTile(
        "Low Fuel Alert",
        "Petrol tank below 25%",
        Icons.warning_amber_rounded,
        Colors.red.shade100,
        Colors.red.shade700,
      ));
    }

    // If no alerts, show normal status
    if (alerts.isEmpty) {
      alerts.add(_buildAlertTile(
        "No Alerts",
        "Fuel levels are normal",
        Icons.check_circle_outline_rounded,
        Colors.green.shade100,
        Colors.green.shade700,
      ));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Recent Alerts",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.redAccent,
              ),
            ),
            SizedBox(height: 12),
            ...alerts,
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTile(String title, String message, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.6),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: iconColor.withOpacity(0.15),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: iconColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(fontSize: 14, color: iconColor.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
