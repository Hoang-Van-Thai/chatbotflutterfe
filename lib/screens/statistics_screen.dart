
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Map<String, dynamic>> _history = [];
  String? _token;
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenAndHistory();
  }

  Future<void> _loadTokenAndHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
      if (_token != null) {
        _userId = Jwt.parseJwt(_token!)['sub'];
        _loadHistory();
      } else {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _loadHistory() async {
    if (_token == null || _userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://chatbotflutter-production.up.railway.app/chat_history/$_userId'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _history = data.map((item) => {
            'sender': item['is_from_user'] ? 'You' : 'Bot',
            'message': item['message'],
            'timestamp': item['timestamp'],
          }).toList();
          // Sort history by timestamp in ascending order
          _history.sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  // Generate data for the chart
  List<BarChartGroupData> _generateChartData() {
    Map<String, Map<String, int>> dailyCounts = {};
    List<String> dates = [];

    for (var item in _history) {
      try {
        final timestamp = DateTime.parse(item['timestamp']).toLocal();
        final dateKey = '${timestamp.year}-${timestamp.month}-${timestamp.day}';
        if (!dailyCounts.containsKey(dateKey)) {
          dailyCounts[dateKey] = {'You': 0, 'Bot': 0};
          dates.add(dateKey);
        }
        dailyCounts[dateKey]![item['sender']] = dailyCounts[dateKey]![item['sender']]! + 1;
      } catch (e) {
        print('Error parsing timestamp: ${item['timestamp']}, $e');
      }
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < dates.length; i++) {
      final counts = dailyCounts[dates[i]]!;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: counts['You']!.toDouble(),
              color: Colors.blue,
              width: 10,
            ),
            BarChartRodData(
              toY: counts['Bot']!.toDouble(),
              color: Colors.green,
              width: 10,
            ),
          ],
        ),
      );
    }

    return barGroups;
  }

  // Get list of dates for X-axis
  List<String> _getDates() {
    Set<String> dateSet = {};
    for (var item in _history) {
      try {
        final timestamp = DateTime.parse(item['timestamp']).toLocal();
        final dateKey = '${timestamp.year}-${timestamp.month}-${timestamp.day}';
        dateSet.add(dateKey);
      } catch (e) {
        print('Error parsing timestamp: ${item['timestamp']}, $e');
      }
    }
    return dateSet.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final dates = _getDates();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Statistics'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? const Center(child: Text('No chat history available'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Messages per Day',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: _generateChartData(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dates.length) {
                            final dateParts = dates[index].split('-');
                            final day = int.parse(dateParts[2]).toString().padLeft(2, '0');
                            final month = int.parse(dateParts[1]).toString().padLeft(2, '0');
                            return Text(
                              '$day/$month',
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  barTouchData: BarTouchData( // Fixed: Use BarTouchData instead of BarTouchTooltipData
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final sender = rodIndex == 0 ? 'You' : 'Bot';
                        return BarTooltipItem(
                          '$sender: ${rod.toY.toInt()}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                const Text('You'),
                const SizedBox(width: 16),
                Container(
                  width: 20,
                  height: 20,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                const Text('Bot'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}