import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'statistics_screen.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final Map<String, List<Map<String, String>>> _sessions = {};
  String? _token;
  String? _userId;
  String _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _loadToken();
    _sessions[_currentSessionId] = [];
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
      if (_token != null) {
        _userId = Jwt.parseJwt(_token!)['sub'];
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _token == null || _userId == null) return;

    final message = _messageController.text;
    setState(() {
      _sessions[_currentSessionId]!.add({'sender': 'You', 'message': message});
    });

    try {
      final response = await http.post(
        Uri.parse('https://chatbotflutter-production.up.railway.app/chat/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'userID': _userId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _sessions[_currentSessionId]!.add({'sender': 'Bot', 'message': data['bot_reply']});
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gửi tin nhắn thất bại'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    _messageController.clear();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _newChat() {
    setState(() {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _sessions[_currentSessionId] = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat - Session $_currentSessionId',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.blue[700], // Màu xanh da trời đậm
        elevation: 2,
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.history, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HistoryScreen()),
                  );
                },
                tooltip: 'Lịch sử chat',
              ),
              IconButton(
                icon: Icon(Icons.bar_chart, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StatisticsScreen()),
                  );
                },
                tooltip: 'Thống kê',
              ),
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
                tooltip: 'Đăng xuất',
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.blue[50], // Nền xanh nhạt cho drawer
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.blue[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  'Danh sách phiên chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ..._sessions.keys.map((sessionId) {
                return ListTile(
                  title: Text(
                    'Phiên $formattedDate',
                    style: TextStyle(color: Colors.blue[900]),
                  ),
                  tileColor: _currentSessionId == sessionId ? Colors.blue[100] : null,
                  onTap: () {
                    setState(() {
                      _currentSessionId = sessionId;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              ListTile(
                title: Text(
                  'Tạo phiên mới',
                  style: TextStyle(color: Colors.blue[900]),
                ),
                leading: Icon(Icons.add, color: Colors.blue[700]),
                onTap: () {
                  _newChat();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[100], // Nền sáng để tương phản
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                itemCount: _sessions[_currentSessionId]?.length ?? 0,
                itemBuilder: (context, index) {
                  final message = _sessions[_currentSessionId]![index];
                  final isUser = message['sender'] == 'You';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue[600] : Colors.blue[200],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['sender']!,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isUser ? Colors.white : Colors.blue[900],
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            message['message']!,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      filled: true,
                      fillColor: Colors.blue[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Material(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _sendMessage,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
