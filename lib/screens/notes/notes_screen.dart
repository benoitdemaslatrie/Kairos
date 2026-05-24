import 'package:flutter/material.dart';
import '../../models/notion_page.dart';
import '../../services/notion_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'note_editor_screen.dart';
import 'notion_settings_screen.dart';

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
          if (p.blocks.isNotEmpty) return p; // already loaded from cache
          final blocks = await NotionService.fetchBlocks(p.id);
          return p.copyWith(blocks: blocks);
        }),
      );
      setState(() {
        _pages = withBlocks;
        _filtered = withBlocks;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
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

  Future<void> _openSettings() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NotionSettingsScreen()),
    );
    if (saved == true) _init();
  }

  Future<void> _openEditor({NotionPage? page}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(page: page)),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _hasToken
          ? FloatingActionButton(
              onPressed: () => _openEditor(),
              backgroundColor: KairosColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
            onPressed: _openSettings,
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
            Expanded(child: _Column(pages: left, onTap: _openEditor)),
            const SizedBox(width: 8),
            Expanded(child: _Column(pages: right, onTap: _openEditor)),
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
              onPressed: _openSettings,
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
  final void Function({NotionPage? page}) onTap;
  const _Column({required this.pages, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: pages
          .map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _NoteCard(page: p, onTap: () => onTap(page: p)),
              ))
          .toList(),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NotionPage page;
  final VoidCallback onTap;
  const _NoteCard({required this.page, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasChecklist = page.blocks.any((b) => b.type == NotionBlockType.toDo);
    final isQuote = page.blocks.isNotEmpty && page.blocks.first.type == NotionBlockType.quote;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
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
