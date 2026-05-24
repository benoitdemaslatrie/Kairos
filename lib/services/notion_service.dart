import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notion_page.dart';

class NotionService {
  static const _tokenKey = 'notion_token';
  static const _proxyKey = 'notion_proxy_url';
  static const _directUrl = 'https://api.notion.com/v1';
  static const _version = '2022-06-28';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getProxyUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_proxyKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token.trim());
  }

  static Future<void> saveProxyUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_proxyKey, url.trim().replaceAll(RegExp(r'/$'), ''));
  }

  static Future<String> _baseUrl() async {
    if (!kIsWeb) return _directUrl;
    final proxy = await getProxyUrl();
    if (proxy != null && proxy.isNotEmpty) return '$proxy/v1';
    return _directUrl;
  }

  static Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Notion-Version': _version,
        'Content-Type': 'application/json',
      };

  static Future<List<NotionPage>> fetchPages() async {
    final token = await getToken();
    if (token == null || token.isEmpty) throw Exception('Token manquant');
    final base = await _baseUrl();

    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$base/search'),
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

    if (response.statusCode == 401) throw Exception('Token invalide (401) — vérifie ton token Notion.');
    if (response.statusCode == 403) throw Exception('Accès refusé (403) — partage tes pages avec l\'intégration.');
    if (response.statusCode != 200) throw Exception('Erreur Notion ${response.statusCode} : ${response.body}');

    return (jsonDecode(response.body)['results'] as List)
        .map((r) => NotionPage.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  static Future<List<NotionBlock>> fetchBlocks(String pageId) async {
    final token = await getToken();
    if (token == null || token.isEmpty) return [];
    final base = await _baseUrl();

    final response = await http.get(
      Uri.parse('$base/blocks/$pageId/children?page_size=20'),
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
