import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/activity.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class DictationScreen extends StatefulWidget {
  const DictationScreen({super.key});

  @override
  State<DictationScreen> createState() => _DictationScreenState();
}

class _DictationScreenState extends State<DictationScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _currentText = '';
  String _statusMessage = 'Appuyez pour dicter';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) => setState(() {
        _statusMessage = 'Erreur: ${error.errorMsg}';
        _isListening = false;
        _pulseController.stop();
      }),
    );
    setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      setState(() => _statusMessage = 'Microphone non disponible');
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _statusMessage = 'Appuyez pour dicter';
        _pulseController.stop();
      });
    } else {
      setState(() {
        _isListening = true;
        _currentText = '';
        _statusMessage = 'Écoute en cours...';
      });
      _pulseController.repeat(reverse: true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _currentText = result.recognizedWords;
          });
        },
        localeId: 'fr_FR',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        cancelOnError: true,
      );
    }
  }

  Future<void> _saveActivity() async {
    if (_currentText.trim().isEmpty) return;

    final box = Hive.box<Activity>('activities');
    final activity = Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: _currentText.trim(),
      createdAt: DateTime.now(),
      type: ActivityType.voice,
    );
    await box.add(activity);

    setState(() {
      _currentText = '';
      _statusMessage = 'Appuyez pour dicter';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Activité enregistrée'),
          backgroundColor: KairosColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const Spacer(),
              _buildMicButton(),
              const SizedBox(height: 32),
              _buildTranscription(),
              const Spacer(),
              if (_currentText.isNotEmpty) _buildSaveButton(),
              const SizedBox(height: 24),
              _buildRecentList(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dictée',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: KairosColors.onSurface,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _statusMessage,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: _isListening
                ? KairosColors.cyan
                : KairosColors.onSurfaceVariant.withOpacity(0.7),
            letterSpacing: 0.02,
          ),
        ),
      ],
    );
  }

  Widget _buildMicButton() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isListening ? _pulseAnimation.value : 1.0,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: _toggleListening,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isListening
                    ? [KairosColors.cyanBright, KairosColors.cyan]
                    : [
                        KairosColors.surfaceContainerHigh,
                        KairosColors.surfaceContainer,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: _isListening
                  ? [
                      BoxShadow(
                        color: KairosColors.cyan.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 8,
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
            ),
            child: Icon(
              _isListening ? Icons.stop_rounded : Icons.mic,
              size: 40,
              color: _isListening ? Colors.white : KairosColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTranscription() {
    return GlassCard(
      showCyanBorder: _isListening,
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: _currentText.isEmpty
            ? Text(
                _isListening
                    ? 'Je vous écoute...'
                    : 'La transcription apparaîtra ici',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  color: KairosColors.onSurfaceVariant.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              )
            : Text(
                _currentText,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: KairosColors.onSurface,
                  height: 1.5,
                ),
              ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: GestureDetector(
        onTap: _saveActivity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            color: KairosColors.primary,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: KairosColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 18, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Enregistrer',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.02,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Activity>('activities').listenable(),
      builder: (context, box, _) {
        final recent = box.values
            .where((a) => a.type == ActivityType.voice)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final toShow = recent.take(3).toList();

        if (toShow.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Récentes',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: KairosColors.onSurfaceVariant,
                letterSpacing: 0.08,
              ),
            ),
            const SizedBox(height: 10),
            ...toShow.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.mic_none_outlined,
                            size: 14, color: KairosColors.cyan.withOpacity(0.8)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            a.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: KairosColors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('HH:mm').format(a.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: KairosColors.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }
}
