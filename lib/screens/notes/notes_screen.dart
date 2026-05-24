import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/notion_page.dart';
import '../../services/notion_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<NotionPage> _pages = [];
  List<NotionPage> _filtered = [];
  bool _loading = false;
  String? _error;
  bool _hasToken = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final token = await NotionService.getToken();
    setState(() => _hasToken = token != null && token.isNotEmpty);
    if (_hasToken) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pages = await NotionService.fetchPages();
      final withBlocks = await Future.wait(
        pages.map((p) async {
          final blocks = await NotionService.fetchBlocks(p.id);
          return p.copyWith(blocks: blocks);
        }),
      );
      setState(() {
        _pages = withBlocks;
        _filtered = withBlocks;
      });
    } catch (_) {
      setState(() => _error = 'Impossible de charger les notes.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _pages
          : _pages.where((p) {
              final inTitle = p.title.toLowerCase().contains(q);
              final inBlocks = p.blocks.any((b) => b.text.toLowerCase().contains(q));
              return inTitle || inBlocks;
            }).toList();
    });
  }

  Future<void> _showTokenDialog() async {
    final tokenCtrl = TextEditingController(text: await NotionService.getToken() ?? '');
    final proxyCtrl = TextEditingController(text: await NotionService.getProxyUrl() ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AlertDialog(
          scrollable: true,
          backgroundColor: const Color(0xFFF0F4FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Connexion Notion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Token d\'intégration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: KairosColors.onSurfaceVariant)),
              const SizedBox(height: 6),
              TextField(
                controller: tokenCtrl,
                decoration: InputDecoration(
                  hintText: 'secret_...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                maxLines: 2,
              ),
              if (kIsWeb) ...[
                const SizedBox(height: 16),
                const Text('URL du proxy CORS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: KairosColors.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('Nécessaire sur web. Déploie le proxy Cloudflare Worker depuis le fichier cloudflare/notion-proxy.js du repo.',
                    style: TextStyle(fontSize: 11, color: KairosColors.onSurfaceVariant.withOpacity(0.7))),
                const SizedBox(height: 6),
                TextField(
                  controller: proxyCtrl,
                  decoration: InputDecoration(
                    hintText: 'https://notion-proxy.xxx.workers.dev',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                await NotionService.saveToken(tokenCtrl.text);
                if (kIsWeb) await NotionService.saveProxyUrl(proxyCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                await _init();
              },
              style: FilledButton.styleFrom(backgroundColor: KairosColors.primary),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Notes', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: KairosColors.onSurface, letterSpacing: -0.8)),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: KairosColors.onSurfaceVariant, size: 22),
            onPressed: _showTokenDialog,
            tooltip: 'Token Notion',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher vos notes',
            hintStyle: TextStyle(fontSize: 14, color: KairosColors.onSurfaceVariant.withOpacity(0.5)),
            prefixIcon: Icon(Icons.search, size: 20, color: KairosColors.onSurfaceVariant.withOpacity(0.5)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasToken) return _buildEmptyToken();
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildError();
    if (_filtered.isEmpty) return _buildEmpty();
    return _buildGrid();
  }

  Widget _buildGrid() {
    final left = <NotionPage>[];
    final right = <NotionPage>[];
    for (var i = 0; i < _filtered.length; i++) {
      if (i.isEven) {
        left.add(_filtered[i]);
      } else {
        right.add(_filtered[i]);
      }
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Column(pages: left)),
            const SizedBox(width: 8),
            Expanded(child: _Column(pages: right)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyToken() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.vpn_key_outlined, size: 56, color: KairosColors.onSurfaceVariant.withOpacity(0.25)),
            const SizedBox(height: 16),
            const Text('Connecte ton compte Notion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: KairosColors.onSurface)),
            const SizedBox(height: 8),
            Text('Appuie sur l\'icône ⚙ en haut à droite\npour entrer ton token d\'intégration.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: KairosColors.onSurfaceVariant.withOpacity(0.6))),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showTokenDialog,
              icon: const Icon(Icons.add_link, size: 18),
              label: const Text('Connecter Notion'),
              style: FilledButton.styleFrom(backgroundColor: KairosColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.note_outlined, size: 56, color: KairosColors.onSurfaceVariant.withOpacity(0.25)),
          const SizedBox(height: 12),
          Text('Aucune note trouvée', style: TextStyle(fontSize: 14, color: KairosColors.onSurfaceVariant.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: KairosColors.error.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(fontSize: 14, color: KairosColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _load, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  final List<NotionPage> pages;
  const _Column({required this.pages});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: pages.map((p) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _NoteCard(page: p))).toList(),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NotionPage page;
  const _NoteCard({required this.page});

  @override
  Widget build(BuildContext context) {
    final hasChecklist = page.blocks.any((b) => b.type == NotionBlockType.toDo);
    final isQuote = page.blocks.isNotEmpty && page.blocks.first.type == NotionBlockType.quote;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: isQuote ? _QuoteContent(page: page) : hasChecklist ? _ChecklistContent(page: page) : _TextContent(page: page),
    );
  }
}

class _TextContent extends StatelessWidget {
  final NotionPage page;
  const _TextContent({required this.page});

  @override
  Widget build(BuildContext context) {
    final preview = page.blocks
        .where((b) => b.type == NotionBlockType.paragraph || b.type == NotionBlockType.bulletedListItem)
        .map((b) => b.text)
        .where((t) => t.isNotEmpty)
        .take(3)
        .join('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (page.title != 'Sans titre') ...[
          Text(page.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: KairosColors.onSurface, height: 1.3)),
          if (preview.isNotEmpty) const SizedBox(height: 6),
        ],
        if (preview.isNotEmpty)
          Text(preview, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: KairosColors.onSurface.withOpacity(0.75), height: 1.45)),
        if (page.title == 'Sans titre' && preview.isEmpty)
          Text('Note vide', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: KairosColors.onSurfaceVariant.withOpacity(0.4))),
      ],
    );
  }
}

class _ChecklistContent extends StatelessWidget {
  final NotionPage page;
  const _ChecklistContent({required this.page});

  @override
  Widget build(BuildContext context) {
    final todos = page.blocks.where((b) => b.type == NotionBlockType.toDo).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (page.title != 'Sans titre') ...[
          Text(page.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: KairosColors.onSurface)),
          const SizedBox(height: 8),
        ],
        ...todos.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    b.checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    size: 15,
                    color: b.checked ? KairosColors.cyan : KairosColors.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      b.text,
                      style: TextStyle(
                        fontSize: 12,
                        color: b.checked ? KairosColors.onSurfaceVariant.withOpacity(0.45) : KairosColors.onSurface.withOpacity(0.8),
                        decoration: b.checked ? TextDecoration.lineThrough : null,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _QuoteContent extends StatelessWidget {
  final NotionPage page;
  const _QuoteContent({required this.page});

  @override
  Widget build(BuildContext context) {
    final quote = page.blocks.first.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '"$quote"',
          style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, fontWeight: FontWeight.w300, color: KairosColors.onSurface, height: 1.5),
        ),
        if (page.title != 'Sans titre') ...[
          const SizedBox(height: 8),
          Text('— ${page.title}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: KairosColors.onSurfaceVariant.withOpacity(0.6), letterSpacing: 0.05)),
        ],
      ],
    );
  }
}
