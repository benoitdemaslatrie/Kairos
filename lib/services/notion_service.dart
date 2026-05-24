import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notion_page.dart';

class NotionService {
  static const _tokenKey = 'notion_token';
  static const _proxyKey = 'notion_proxy_url';
  static const _parentKey = 'notion_parent_id';
  static const _directUrl = 'https://api.notion.com/v1';
  static const _version = '2022-06-28';

  // ── Persistence ────────────────────────────────────────────────────────────

  static Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  static Future<String?> getProxyUrl() async =>
      (await SharedPreferences.getInstance()).getString(_proxyKey);

  static Future<String?> getParentId() async =>
      (await SharedPreferences.getInstance()).getString(_parentKey);

  static Future<void> saveToken(String v) async =>
      (await SharedPreferences.getInstance()).setString(_tokenKey, v.trim());

  static Future<void> saveProxyUrl(String v) async =>
      (await SharedPreferences.getInstance())
          .setString(_proxyKey, v.trim().replaceAll(RegExp(r'/$'), ''));

  static Future<void> saveParentId(String v) async =>
      (await SharedPreferences.getInstance()).setString(_parentKey, v.trim());

  // ── Internal helpers ───────────────────────────────────────────────────────

  static Future<String> _base() async {
    if (!kIsWeb) return _directUrl;
    final proxy = await getProxyUrl();
    if (proxy == null || proxy.isEmpty) {
      throw Exception('URL du proxy non configurée — entre l\'URL Vercel dans les paramètres ⚙');
    }
    return '$proxy/api';
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    if (token == null || token.isEmpty) throw Exception('Token manquant');
    return {
      'Authorization': 'Bearer $token',
      'Notion-Version': _version,
      'Content-Type': 'application/json',
    };
  }

  static Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final base = await _base();
    final uri = Uri.parse('$base/$path');
    final headers = await _headers();
    try {
      return switch (method) {
        'GET' => await http.get(uri, headers: headers),
        'POST' => await http.post(uri, headers: headers, body: jsonEncode(body)),
        'PATCH' => await http.patch(uri, headers: headers, body: jsonEncode(body)),
        'DELETE' => await http.delete(uri, headers: headers),
        _ => throw Exception('Méthode inconnue'),
      };
    } catch (e) {
      throw Exception('Erreur réseau : $e');
    }
  }

  static void _check(http.Response r) {
    if (r.statusCode == 401) throw Exception('Token invalide (401)');
    if (r.statusCode == 403) throw Exception('Accès refusé (403) — partage la page avec ton intégration');
    if (r.statusCode == 404) throw Exception('Page introuvable (404)');
    if (r.statusCode >= 400) throw Exception('Erreur ${r.statusCode} : ${r.body}');
  }

  // ── Web: static cache (read-only fallback) ─────────────────────────────────

  static Future<List<NotionPage>> _fetchFromCache() async {
    final response = await http.get(Uri.parse('notion_cache.json'));
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['pages'] as List? ?? [])
        .map((r) => NotionPage.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  static Future<List<NotionPage>> fetchPages() async {
    // On web without proxy configured, fall back to static cache
    if (kIsWeb) {
      final proxy = await getProxyUrl();
      if (proxy == null || proxy.isEmpty) return _fetchFromCache();
    }

    final r = await _request('POST', 'search', body: {
      'filter': {'value': 'page', 'property': 'object'},
      'page_size': 30,
      'sort': {'direction': 'descending', 'timestamp': 'last_edited_time'},
    });
    _check(r);

    return (jsonDecode(r.body)['results'] as List)
        .map((e) => NotionPage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<NotionBlock>> fetchBlocks(String pageId) async {
    if (kIsWeb) {
      final proxy = await getProxyUrl();
      if (proxy == null || proxy.isEmpty) return [];
    }
    final r = await _request('GET', 'blocks/$pageId/children?page_size=20');
    if (r.statusCode != 200) return [];

    return (jsonDecode(r.body)['results'] as List)
        .map((e) => NotionBlock.fromJson(e as Map<String, dynamic>))
        .where((b) => b.type != NotionBlockType.unknown)
        .where((b) => b.text.isNotEmpty || b.type == NotionBlockType.toDo)
        .take(8)
        .toList();
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  static Future<NotionPage> createPage({
    required String title,
    String content = '',
  }) async {
    final parentId = await getParentId();
    if (parentId == null || parentId.isEmpty) {
      throw Exception('ID de la page parente non configuré dans les paramètres ⚙');
    }

    final body = {
      'parent': {'page_id': parentId},
      'properties': {
        'title': {
          'title': [{'text': {'content': title}}]
        }
      },
      if (content.isNotEmpty)
        'children': [
          {
            'object': 'block',
            'type': 'paragraph',
            'paragraph': {
              'rich_text': [{'text': {'content': content}}]
            }
          }
        ]
    };

    final r = await _request('POST', 'pages', body: body);
    _check(r);
    return NotionPage.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  static Future<void> updateTitle(String pageId, String title) async {
    final r = await _request('PATCH', 'pages/$pageId', body: {
      'properties': {
        'title': {
          'title': [{'text': {'content': title}}]
        }
      }
    });
    _check(r);
  }

  static Future<void> updateFirstBlock(String blockId, String content) async {
    final r = await _request('PATCH', 'blocks/$blockId', body: {
      'paragraph': {
        'rich_text': [{'text': {'content': content}}]
      }
    });
    _check(r);
  }

  static Future<void> appendBlock(String pageId, String content) async {
    final r = await _request('PATCH', 'blocks/$pageId/children', body: {
      'children': [
        {
          'object': 'block',
          'type': 'paragraph',
          'paragraph': {
            'rich_text': [{'text': {'content': content}}]
          }
        }
      ]
    });
    _check(r);
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  static Future<void> deletePage(String pageId) async {
    final r = await _request('PATCH', 'pages/$pageId', body: {'archived': true});
    _check(r);
  }
}
