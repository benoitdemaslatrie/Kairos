import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/notion_service.dart';
import '../../theme/app_theme.dart';

class NotionSettingsScreen extends StatefulWidget {
  const NotionSettingsScreen({super.key});

  @override
  State<NotionSettingsScreen> createState() => _NotionSettingsScreenState();
}

class _NotionSettingsScreenState extends State<NotionSettingsScreen> {
  final _tokenCtrl = TextEditingController();
  bool _saving = false;
  bool _tokenObscured = true;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _tokenCtrl.text = await NotionService.getToken() ?? '';
    final info = await PackageInfo.fromPlatform();
    setState(() => _version = '${info.version} (build ${info.buildNumber})');
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await NotionService.saveToken(_tokenCtrl.text);
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
        title: const Text('Paramètres Notion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: KairosColors.onSurface)),
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
            child: kIsWeb ? _buildWebContent() : _buildMobileContent(),
          ),
        ),
      ),
    );
  }

  // Sur web : les notes sont récupérées par GitHub Actions via NOTION_TOKEN secret
  Widget _buildWebContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _SectionCard(
          icon: Icons.auto_awesome_outlined,
          title: 'Comment ça fonctionne',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Step(number: '1', text: 'Va sur notion.so/profile/integrations → crée une intégration → copie le token secret_...'),
              const SizedBox(height: 10),
              _Step(number: '2', text: 'Dans Notion, partage chaque page avec ton intégration (... → Connections).'),
              const SizedBox(height: 10),
              _Step(number: '3', text: 'Sur GitHub → Settings → Secrets and variables → Actions → New secret → nom : NOTION_TOKEN, valeur : ton token.'),
              const SizedBox(height: 10),
              _Step(number: '4', text: 'Relance le workflow GitHub Actions → les notes seront intégrées au prochain déploiement.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          icon: Icons.info_outline,
          title: 'Pourquoi cette approche ?',
          child: Text(
            'Les navigateurs web bloquent les appels directs à l\'API Notion (CORS). Kairos contourne ce problème en récupérant tes notes lors du build sur GitHub, sans jamais exposer ton token dans le navigateur.',
            style: TextStyle(fontSize: 13, color: KairosColors.onSurfaceVariant.withOpacity(0.8), height: 1.5),
          ),
        ),
        if (_version.isNotEmpty) ...[
          const SizedBox(height: 32),
          Center(child: Text(_version, style: TextStyle(fontSize: 11, color: KairosColors.onSurfaceVariant.withOpacity(0.35)))),
        ],
      ],
    );
  }

  // Sur mobile : token saisi directement, API appelée sans CORS
  Widget _buildMobileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _SectionCard(
          icon: Icons.vpn_key_outlined,
          title: 'Token d\'intégration',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crée une intégration sur notion.so/profile/integrations et copie le "Internal Integration Secret".',
                style: TextStyle(fontSize: 12, color: KairosColors.onSurfaceVariant.withOpacity(0.7), height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tokenCtrl,
                obscureText: _tokenObscured,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: 'secret_...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: KairosColors.cyan, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(_tokenObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: KairosColors.onSurfaceVariant),
                    onPressed: () => setState(() => _tokenObscured = !_tokenObscured),
                  ),
                ),
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
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
        if (_version.isNotEmpty) ...[
          const SizedBox(height: 32),
          Center(child: Text(_version, style: TextStyle(fontSize: 11, color: KairosColors.onSurfaceVariant.withOpacity(0.35)))),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _SectionCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: KairosColors.cyan),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: KairosColors.onSurface)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: KairosColors.cyan.withOpacity(0.15), shape: BoxShape.circle),
          child: Center(child: Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: KairosColors.cyan))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: KairosColors.onSurfaceVariant.withOpacity(0.8), height: 1.4))),
      ],
    );
  }
}
