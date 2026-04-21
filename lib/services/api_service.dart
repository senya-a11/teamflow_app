import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/task.dart';

class ApiService {
  static String get baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:5001';

  static Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = token;
    }
    return headers;
  }

  // ========== AUTH ==========

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: _headers(),
      body: jsonEncode({'username': username, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'token': data['token'],
        'user': User.fromJson(data['user']),
      };
    } else {
      throw Exception(data['error'] ?? 'Ошибка входа');
    }
  }

  static Future<void> register(String username, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: _headers(),
      body: jsonEncode({'username': username, 'password': password, 'role': role}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['error'] ?? 'Ошибка регистрации');
    }
  }

  // ========== TASKS ==========

  static Future<List<Task>> getTasks(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tasks'),
      headers: _headers(token: token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Task.fromJson(json)).toList();
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Ошибка загрузки задач');
    }
  }

  static Future<void> createTask({
    required String token,
    required String title,
    required String taskContent,
    int? assignedTo,
    String? deadline,
  }) async {
    final body = {
      'title': title,
      'task': taskContent,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (deadline != null) 'deadline': deadline,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/tasks'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['error'] ?? 'Ошибка создания задачи');
    }
  }

  static Future<void> completeTask(String token, int taskInfoId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tasks/$taskInfoId/complete'),
      headers: _headers(token: token),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Ошибка обновления задачи');
    }
  }

  // ========== USERS ==========

  static Future<List<Map<String, dynamic>>> getCrew(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/crew'),
      headers: _headers(token: token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Ошибка загрузки списка команды');
    }
  }
}
