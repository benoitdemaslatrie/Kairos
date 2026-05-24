import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../services/notion_service.dart';
import '../../theme/app_theme.dart';

class NotionSettingsScreen extends StatefulWidget {
  const NotionSettingsScreen({super.key});

  @override
  State<NotionSettingsScreen> createState() => _NotionSettingsScreenState();
}

class _NotionSettingsScreenState extends State<NotionSettingsScreen> {
  final _tokenCtrl = TextEditingController();
  final _proxyCtrl = TextEditingController();
  bool _saving = false;
  bool _tokenObscured = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _proxyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _tokenCtrl.text = await NotionService.getToken() ?? '';
    _proxyCtrl.text = await NotionService.getProxyUrl() ?? '';
    setState(() {});
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await NotionService.saveToken(_tokenCtrl.text);
    if (kIsWeb) await NotionService.saveProxyUrl(_proxyCtrl.text);
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context, true);
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
        title: const Text('Connexion Notion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: KairosColors.onSurface)),
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
            padding: const EdgeInsets.all(24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildSection(
                  icon: Icons.vpn_key_outlined,
                  title: 'Token d\'intégration',
                  description: 'Crée une intégration sur notion.so/profile/integrations et copie le "Internal Integration Secret".',
                  child: TextField(
                    controller: _tokenCtrl,
                    obscureText: _tokenObscured,
                    decoration: InputDecoration(
                      hintText: 'secret_...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixIcon: IconButton(
                        icon: Icon(_tokenObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: KairosColors.onSurfaceVariant),
                        onPressed: () => setState(() => _tokenObscured = !_tokenObscured),
                      ),
                    ),
                    style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                  ),
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 28),
                  _buildSection(
                    icon: Icons.swap_horiz_outlined,
                    title: 'URL du proxy CORS',
                    description: 'Nécessaire sur web. Déploie le Cloudflare Worker depuis cloudflare/notion-proxy.js dans le repo.',
                    child: TextField(
                      controller: _proxyCtrl,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText: 'https://notion-proxy.xxx.workers.dev',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
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
                        : const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, required String description, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: KairosColors.cyan),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: KairosColors.onSurface)),
          ],
        ),
        const SizedBox(height: 6),
        Text(description, style: TextStyle(fontSize: 12, color: KairosColors.onSurfaceVariant.withOpacity(0.7), height: 1.4)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
