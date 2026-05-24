import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notion_page.dart';

class NotionService {
  static const _tokenKey = 'notion_token';
  static const _baseUrl = 'https://api.notion.com/v1';
  static const _version = '2022-06-28';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token.trim());
  }

  static Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Notion-Version': _version,
        'Content-Type': 'application/json',
      };

  static Future<List<NotionPage>> fetchPages() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return [];

    final response = await http.post(
      Uri.parse('$_baseUrl/search'),
      headers: _headers(token),
      body: jsonEncode({
        'filter': {'value': 'page', 'property': 'object'},
        'page_size': 30,
        'sort': {'direction': 'descending', 'timestamp': 'last_edited_time'},
      }),
    );

    if (response.statusCode != 200) return [];

    final results = (jsonDecode(response.body)['results'] as List)
        .map((r) => NotionPage.fromJson(r as Map<String, dynamic>))
        .toList();

    return results;
  }

  static Future<List<NotionBlock>> fetchBlocks(String pageId) async {
    final token = await getToken();
    if (token == null || token.isEmpty) return [];

    final response = await http.get(
      Uri.parse('$_baseUrl/blocks/$pageId/children?page_size=20'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) return [];

    return (jsonDecode(response.body)['results'] as List)
        .map((r) => NotionBlock.fromJson(r as Map<String, dynamic>))
        .where((b) => b.type != NotionBlockType.unknown && b.text.isNotEmpty || b.type == NotionBlockType.toDo)
        .take(8)
        .toList();
  }
}
