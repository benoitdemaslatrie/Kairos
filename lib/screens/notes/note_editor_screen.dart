import 'package:flutter/material.dart';
import '../../models/notion_page.dart';
import '../../services/notion_service.dart';
import '../../theme/app_theme.dart';

class NoteEditorScreen extends StatefulWidget {
  final NotionPage? page; // null = nouvelle note

  const NoteEditorScreen({super.key, this.page});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  bool _saving = false;
  bool _deleting = false;

  bool get _isNew => widget.page == null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.page?.title ?? '');
    final firstParagraph = widget.page?.blocks
        .where((b) => b.type == NotionBlockType.paragraph)
        .map((b) => b.text)
        .firstOrNull ?? '';
    _contentCtrl = TextEditingController(text: firstParagraph);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre ne peut pas être vide')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isNew) {
        await NotionService.createPage(title: title, content: _contentCtrl.text.trim());
      } else {
        await NotionService.updateTitle(widget.page!.id, title);
        final content = _contentCtrl.text.trim();
        final firstBlock = widget.page!.blocks
            .where((b) => b.type == NotionBlockType.paragraph)
            .firstOrNull;
        if (firstBlock != null) {
          await NotionService.updateFirstBlock(firstBlock.id, content);
        } else if (content.isNotEmpty) {
          await NotionService.appendBlock(widget.page!.id, content);
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: KairosColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette note ?'),
        content: const Text('La note sera archivée dans Notion.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: KairosColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await NotionService.deletePage(widget.page!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: KairosColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: KairosColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isNew ? 'Nouvelle note' : 'Modifier',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: KairosColors.onSurface),
        ),
        actions: [
          if (!_isNew)
            IconButton(
              icon: _deleting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_outline, color: KairosColors.error),
              onPressed: _deleting ? null : _delete,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9F9FF), Color(0xFFE7EEFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Titre
                TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w300, color: KairosColors.onSurface, letterSpacing: -0.5),
                  decoration: InputDecoration(
                    hintText: 'Titre',
                    hintStyle: TextStyle(fontSize: 26, fontWeight: FontWeight.w300, color: KairosColors.onSurfaceVariant.withOpacity(0.4)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),

                const SizedBox(height: 4),
                Divider(color: Colors.white.withOpacity(0.5)),
                const SizedBox(height: 12),

                // Contenu
                TextField(
                  controller: _contentCtrl,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: KairosColors.onSurface.withOpacity(0.85), height: 1.6),
                  decoration: InputDecoration(
                    hintText: 'Écris ta note ici...',
                    hintStyle: TextStyle(fontSize: 16, color: KairosColors.onSurfaceVariant.withOpacity(0.35)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: null,
                  minLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                ),

                const SizedBox(height: 40),

                // Bouton sauvegarder
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: KairosColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isNew ? 'Créer dans Notion' : 'Enregistrer', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
