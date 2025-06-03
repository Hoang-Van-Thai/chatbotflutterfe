import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<Map<String, dynamic>> _history = [];
  String? _token;
  String? _userId;

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
      }
    });
  }

  Future<void> _loadHistory() async {
    if (_token == null || _userId == null) return;

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
          _history.clear();
          _history.addAll(data.map((item) => {
            'sender': item['is_from_user'] ? 'You' : 'Bot',
            'message': item['message'],
            'timestamp': item['timestamp'],
          }));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat History')),
      body: ListView.builder(
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          return ListTile(
            title: Text(item['sender']),
            subtitle: Text(item['message']),
            trailing: Text(item['timestamp'].toString().substring(0, 19)),
          );
        },
      ),
    );
  }
}