import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notion_page.dart';

class NotionService {
  static const _tokenKey = 'notion_token';
  static const _directUrl = 'https://api.notion.com/v1';
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

  // Web: reads from the static cache built by GitHub Actions
  static Future<List<NotionPage>> _fetchFromCache() async {
    final response = await http.get(Uri.parse('notion_cache.json'));
    if (response.statusCode != 200) throw Exception('Cache non trouvé (${response.statusCode})');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final pages = data['pages'] as List? ?? [];
    if (pages.isEmpty) throw Exception('Aucune note dans le cache — configure NOTION_TOKEN dans les secrets GitHub.');
    return pages.map((r) => NotionPage.fromJson(r as Map<String, dynamic>)).toList();
  }

  // Mobile: calls Notion API directly (no CORS restriction)
  static Future<List<NotionPage>> _fetchFromApi() async {
    final token = await getToken();
    if (token == null || token.isEmpty) throw Exception('Token manquant — entre ton token Notion dans les paramètres.');

    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_directUrl/search'),
        headers: _headers(token),
        body: jsonEncode({
          'filter': {'value': 'page', 'property': 'object'},
          'page_size': 30,
          'sort': {'direction': 'descending', 'timestamp': 'last_edited_time'},
        }),
      );
    } catch (e) {
      throw Exception('Erreur réseau : $e');
    }

    if (response.statusCode == 401) throw Exception('Token invalide (401).');
    if (response.statusCode == 403) throw Exception('Accès refusé (403) — partage tes pages avec l\'intégration.');
    if (response.statusCode != 200) throw Exception('Erreur ${response.statusCode} : ${response.body}');

    return (jsonDecode(response.body)['results'] as List)
        .map((r) => NotionPage.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  static Future<List<NotionPage>> fetchPages() async {
    return kIsWeb ? _fetchFromCache() : _fetchFromApi();
  }

  static Future<List<NotionBlock>> fetchBlocks(String pageId) async {
    if (kIsWeb) return []; // already included in cache
    final token = await getToken();
    if (token == null || token.isEmpty) return [];

    final response = await http.get(
      Uri.parse('$_directUrl/blocks/$pageId/children?page_size=20'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) return [];

    return (jsonDecode(response.body)['results'] as List)
        .map((r) => NotionBlock.fromJson(r as Map<String, dynamic>))
        .where((b) => b.type != NotionBlockType.unknown)
        .where((b) => b.text.isNotEmpty || b.type == NotionBlockType.toDo)
        .take(8)
        .toList();
  }
}
