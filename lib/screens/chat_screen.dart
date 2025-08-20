import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/chat_message.dart';
import '../models/providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import 'settings_screen.dart';
import '../theme/app_colors.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFocusNode = FocusNode();

  late AnimationController _nebulaBgController;
  late AnimationController _voiceController;
  late AnimationController _sidebarController;
  late AnimationController _crystalOrbController;

  final ImagePicker _picker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Timer? _recordTimer;
  Duration _recordDuration = Duration.zero;

  bool _isSidebarVisible = true;
  bool _showSpellCheck = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _misspelledWord;
  List<String> _suggestions = [];
  bool _spellCheckEnabled = true;

  final Set<String> _dictionary = {
    'hello',
    'world',
    'this',
    'is',
    'a',
    'test',
    'spell',
    'checker',
    'flutter',
    'code',
    'c#',
    'python',
    'the',
    'quick',
    'brown',
    'fox',
    'jumps',
    'over',
    'lazy',
    'dog',
    'axon',
    'dress',
    'create',
    'draw',
    'please',
    'help',
    'me',
    'with',
    'my',
    'homework',
    'thank',
    'you',
    'chat',
    'issue',
    'error',
    'fix',
    'how',
    'are',
    'you',
    'what',
    'is',
    'your',
    'name',
    'where',
    'when',
    'app',
    'screenshot',
    'image',
    'why',
    'can',
    'could',
    'would',
    'should',
    'will',
    'may',
    'might',
    'generate',
    'ui',
    'ux',
    'design',
    'must',
    'shall',
    'do',
    'does',
    'did',
    'have',
    'has',
    'had',
    'be',
    'ai',
    'api',
    'key',
    'token',
    'am',
    'is',
    'are',
    'was',
    'were',
    'being',
    'been',
    'i',
    'he',
    'she',
    'it',
    'we',
    'they',
    'style',
    'message',
    'crystal',
    'oracle',
    'analyze',
    'photo',
    'voice',
    'recording',
    'witty',
    'assistant',
    'personality',
    'ideas',
    'inspire',
    'explain',
    'creative',
    'amazing',
    'concept',
    'simple',
    'terms',
    'trip'
  };

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(sessionsProvider).isEmpty) {
        ref.read(sessionsProvider.notifier).createNewSession();
      }
    });

    _nebulaBgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 60))
          ..repeat();
    _voiceController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _sidebarController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _crystalOrbController =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();

    if (_isSidebarVisible) {
      _sidebarController.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _textFocusNode.dispose();
    _nebulaBgController.dispose();
    _voiceController.dispose();
    _sidebarController.dispose();
    _crystalOrbController.dispose();
    _audioRecorder.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic);
        }
      });
    }
  }

  Future<void> _sendMessage({String? textOverride}) async {
    final text = textOverride ?? _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();

    if (textOverride == null) {
      _controller.clear();
    }

    setState(() => _showSpellCheck = false);

    final message =
        ChatMessage(text: text, sender: Sender.user, timestamp: DateTime.now());

    await ref.read(sessionsProvider.notifier).sendMessage(message);
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    try {
      final status = await Permission.photos.request();
      if (status.isGranted) {
        final XFile? image = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 90,
            maxWidth: 1920,
            maxHeight: 1920);

        if (image != null) {
          HapticFeedback.lightImpact();
          final message = ChatMessage(
              text:
                  "What do you see in this image? Please analyze it in detail.",
              sender: Sender.user,
              timestamp: DateTime.now(),
              type: MessageType.image,
              filePath: image.path);
          await ref.read(sessionsProvider.notifier).sendMessage(message);
          _scrollToBottom();
        }
      } else {
        _showPermissionDialog('Photos', 'access your photo gallery');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select image: $e');
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        final XFile? image = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 90,
            maxWidth: 1920,
            maxHeight: 1920);

        if (image != null) {
          HapticFeedback.lightImpact();
          final message = ChatMessage(
              text:
                  "What do you see in this photo I just took? Please provide a detailed analysis.",
              sender: Sender.user,
              timestamp: DateTime.now(),
              type: MessageType.image,
              filePath: image.path);
          await ref.read(sessionsProvider.notifier).sendMessage(message);
          _scrollToBottom();
        }
      } else {
        _showPermissionDialog('Camera', 'access your camera');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture photo: $e');
    }
  }

  void _checkSpelling(String text) {
    if (!_spellCheckEnabled || text.isEmpty) {
      if (_showSpellCheck) setState(() => _showSpellCheck = false);
      return;
    }

    if (!text.endsWith(' ') &&
        !text.endsWith('.') &&
        !text.endsWith('!') &&
        !text.endsWith('?')) {
      return;
    }

    final words = text.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return;

    final lastWordRaw = words.last;
    final lastWordClean =
        lastWordRaw.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();

    if (lastWordClean.length > 2 && !_dictionary.contains(lastWordClean)) {
      final newSuggestions = _getSuggestions(lastWordClean);
      if (newSuggestions.isNotEmpty) {
        setState(() {
          _misspelledWord = lastWordRaw;
          _suggestions = newSuggestions.take(4).toList();
          _showSpellCheck = true;
        });
        return;
      }
    }

    if (_showSpellCheck) setState(() => _showSpellCheck = false);
  }

  List<String> _getSuggestions(String word) {
    final lowerWord = word.toLowerCase();
    final suggestions = <String>[];

    for (String dictWord in _dictionary) {
      if (dictWord
          .startsWith(lowerWord.substring(0, math.min(2, lowerWord.length)))) {
        suggestions.add(dictWord);
      }
    }

    for (String dictWord in _dictionary) {
      final distance = _levenshteinDistance(lowerWord, dictWord);
      if (distance <= 2 && distance > 0) {
        if (!suggestions.contains(dictWord)) {
          suggestions.add(dictWord);
        }
      }
    }

    suggestions.sort((a, b) => _levenshteinDistance(lowerWord, a)
        .compareTo(_levenshteinDistance(lowerWord, b)));
    return suggestions;
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.generate(s2.length + 1, (i) => 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce(math.min);
      }
      v0 = v1.toList();
    }

    return v1[s2.length];
  }

  void _applySuggestion(String suggestion) {
    if (_misspelledWord == null) return;

    final text = _controller.text;
    final words = text.split(' ');

    for (int i = words.length - 1; i >= 0; i--) {
      final cleanWord = words[i].replaceAll(RegExp(r'[^\w]'), '');
      if (cleanWord.toLowerCase() ==
          _misspelledWord!.replaceAll(RegExp(r'[^\w]'), '').toLowerCase()) {
        final punctuation = words[i].replaceAll(RegExp(r'[\w]'), '');
        words[i] = suggestion + punctuation;
        break;
      }
    }

    _controller.text = '${words.join(' ')} ';
    _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length));

    setState(() {
      _showSpellCheck = false;
      _misspelledWord = null;
      _suggestions = [];
    });

    HapticFeedback.lightImpact();
  }

  void _toggleSpellCheck() {
    setState(() {
      _spellCheckEnabled = !_spellCheckEnabled;
      if (!_spellCheckEnabled) _showSpellCheck = false;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _shareCurrentSession() async {
    final activeId = ref.read(activeSessionIdProvider);
    if (activeId == null) {
      _showErrorSnackBar('No active chat to share.');
      return;
    }

    final activeSession =
        ref.read(sessionsProvider).firstWhere((s) => s.id == activeId);

    if (activeSession.messages.isEmpty) {
      _showErrorSnackBar('Cannot share an empty chat.');
      return;
    }

    try {
      final buffer = StringBuffer();
      buffer.writeln('🔮 AXON Chat Session: ${activeSession.title}');
      buffer.writeln(
          '🗓️ Shared on: ${DateFormat.yMd().add_Hm().format(DateTime.now())}');
      buffer.writeln('----------------------------------\n');

      for (final message in activeSession.messages) {
        final prefix = message.sender == Sender.user ? '👤 You:' : '✨ AXON:';
        if (message.type == MessageType.image) {
          buffer.writeln('$prefix [Image Attached] - "${message.text}"\n');
        } else if (message.type == MessageType.voice) {
          buffer.writeln('$prefix [Voice Message] - "${message.text}"\n');
        } else {
          buffer.writeln('$prefix ${message.text}\n');
        }
      }

      await Share.share(
        buffer.toString(),
        subject: 'AXON Chat Log: ${activeSession.title}',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to share chat: $e');
    }
  }

  void _setPrompt(String prompt) {
    _controller.text = prompt;
    _textFocusNode.requestFocus();
    _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length));
  }

  Future<void> _setPromptAndSend(String prompt) async {
    await _sendMessage(textOverride: prompt);
    HapticFeedback.lightImpact();
  }

  Future<void> _startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/axon_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
            const RecordConfig(
                encoder: AudioEncoder.aacLc,
                sampleRate: 44100,
                bitRate: 128000),
            path: path);

        setState(() => _isRecording = true);
        HapticFeedback.mediumImpact();
        _startTimer();
      } else {
        _showPermissionDialog('Microphone', 'record audio messages');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordTimer?.cancel();
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      HapticFeedback.lightImpact();

      if (path != null && File(path).existsSync()) {
        final message = ChatMessage(
            text:
                "Please transcribe and respond to this voice message I just recorded.",
            sender: Sender.user,
            timestamp: DateTime.now(),
            type: MessageType.voice,
            filePath: path,
            audioDuration: _recordDuration);

        await ref.read(sessionsProvider.notifier).sendMessage(message);
        _scrollToBottom();
      }

      _recordDuration = Duration.zero;
    } catch (e) {
      _showErrorSnackBar('Failed to save recording: $e');
      setState(() => _isRecording = false);
      _recordDuration = Duration.zero;
    }
  }

  void _startTimer() {
    _recordDuration = Duration.zero;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _recordDuration = Duration(seconds: timer.tick));
        if (_recordDuration.inMinutes >= 5) {
          _stopRecording();
        }
      }
    });
  }

  void _showPermissionDialog(String permission, String purpose) {
    showDialog(
      context: context,
      barrierColor: AppColors.deepSpace.withOpacity(0.8),
      builder: (context) => _CrystalDialog(
        title: '$permission Permission Required',
        content:
            'AXON needs permission to $purpose. Please grant access in settings.',
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Settings',
                  style: TextStyle(color: AppColors.crystalBlue))),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.poppins(color: AppColors.textPrimary)),
        backgroundColor: AppColors.deepSpace.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _toggleSidebar() {
    setState(() => _isSidebarVisible = !_isSidebarVisible);
    if (_isSidebarVisible) {
      _sidebarController.forward();
    } else {
      _sidebarController.reverse();
    }
    HapticFeedback.lightImpact();
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _CrystalBottomSheet(
        title: 'Add Image',
        children: [
          _BottomSheetOption(
              icon: Icons.photo_library_outlined,
              title: 'From Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              }),
          _BottomSheetOption(
              icon: Icons.camera_alt_outlined,
              title: 'Take Photo',
              onTap: () {
                Navigator.pop(context);
                _capturePhoto();
              }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeId = ref.watch(activeSessionIdProvider);
    final sessions = ref.watch(sessionsProvider);
    final activeSession = sessions.firstWhere((s) => s.id == activeId,
        orElse: () => ChatSession(
            id: '',
            title: 'New Chat',
            messages: [],
            createdAt: DateTime.now()));

    final messages = activeSession.messages.where((msg) {
      if (_searchQuery.isEmpty) return true;
      return msg.text.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final isLoading = ref.watch(isLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.deepSpace,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _nebulaBgController,
            builder: (context, child) => CustomPaint(
              painter: EnhancedNebulaPainter(_nebulaBgController.value),
              size: MediaQuery.of(context).size,
            ),
          ),
          Row(
            children: [
              _buildEnhancedSidebar(),
              Expanded(
                child: Column(
                  children: [
                    _buildEnhancedAppBar(),
                    if (_searchQuery.isNotEmpty) _buildSearchHeader(),
                    Expanded(child: _buildChatArea(messages, isLoading)),
                    _buildEnhancedInputArea(isLoading),
                  ],
                ),
              ),
            ],
          ),
          if (_isRecording) _buildVoiceRecordingOverlay(),
        ],
      ),
    );
  }

  Widget _buildEnhancedSidebar() {
    final sessions = ref.watch(sessionsProvider);
    final activeId = ref.watch(activeSessionIdProvider);
    final temperature = ref.watch(temperatureProvider);

    return AnimatedBuilder(
      animation: _sidebarController,
      builder: (context, child) {
        final sidebarWidth = _sidebarController.value * 320;

        if (sidebarWidth < 10) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: sidebarWidth,
          child: OverflowBox(
            maxWidth: 320,
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.crystalBlue.withOpacity(0.03),
                        AppColors.etherealPink.withOpacity(0.02),
                        AppColors.deepSpace.withOpacity(0.7)
                      ],
                    ),
                    border: Border(
                        right: BorderSide(
                            color: AppColors.crystalBlue.withOpacity(0.2),
                            width: 1)),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSidebarHeader(),
                        _buildPersonalitySelector(),
                        _buildQuickStats(temperature),
                        _buildNewChatButton(),
                        _buildSearchBar(),
                        _buildChatHistory(sessions, activeId ?? ''),
                        _buildSidebarFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [AppColors.crystalBlue, AppColors.etherealPink])),
            child: Center(
                child: Text('A',
                    style: GoogleFonts.exo2(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepSpace))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AXON',
                    style: GoogleFonts.exo2(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary,
                        letterSpacing: 2)),
                Text('Your AI Companion',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        letterSpacing: 1)),
              ],
            ),
          ),
          _buildGlowButton(
            icon: Icons.settings_outlined,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalitySelector() {
    final currentPersonality = ref.watch(selectedPersonalityProvider);

    String getTitle(AiPersonality p) {
      switch (p) {
        case AiPersonality.oracle:
          return "Crystal Oracle";
        case AiPersonality.witty:
          return "Witty AI";
        case AiPersonality.assistant:
          return "Helpful Assistant";
      }
    }

    IconData getIcon(AiPersonality p) {
      switch (p) {
        case AiPersonality.oracle:
          return Icons.auto_awesome;
        case AiPersonality.witty:
          return Icons.psychology_alt;
        case AiPersonality.assistant:
          return Icons.support_agent;
      }
    }

    return PopupMenuButton<AiPersonality>(
      initialValue: currentPersonality,
      onSelected: (p) =>
          ref.read(selectedPersonalityProvider.notifier).state = p,
      tooltip: "Change AI Personality",
      color: AppColors.deepSpace.withOpacity(0.95),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.crystalBlue.withOpacity(0.2))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.accentGlow.withOpacity(0.1),
          border: Border.all(color: AppColors.accentGlow.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(getIcon(currentPersonality),
                color: AppColors.accentGlow, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                getTitle(currentPersonality),
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
      ),
      itemBuilder: (context) => AiPersonality.values.map((p) {
        return PopupMenuItem<AiPersonality>(
          value: p,
          child: Row(
            children: [
              Icon(getIcon(p), color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 12),
              Text(getTitle(p),
                  style: GoogleFonts.poppins(color: AppColors.textPrimary)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickStats(double temperature) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.crystalBlue.withOpacity(0.05),
        border: Border.all(color: AppColors.crystalBlue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildStatRow('Model', 'Cohere R+'),
          const SizedBox(height: 8),
          _buildStatRow('Creativity', '${(temperature * 100).toInt()}%'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildNewChatButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: _CrystalButton(
        onPressed: () {
          ref.read(sessionsProvider.notifier).createNewSession();
          HapticFeedback.lightImpact();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 20, color: AppColors.deepSpace),
            const SizedBox(width: 8),
            Text('New Chat',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepSpace)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle:
              GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textSecondary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.crystalBlue.withOpacity(0.05),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.crystalBlue.withOpacity(0.2))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.crystalBlue.withOpacity(0.2))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.crystalBlue.withOpacity(0.5))),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildChatHistory(List<ChatSession> sessions, String activeId) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text('CHAT HISTORY',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sessions.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final session = sessions[index];
                final isActive = session.id == activeId;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    selected: isActive,
                    selectedTileColor: AppColors.crystalBlue.withOpacity(0.1),
                    title: Text(session.title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isActive
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: isActive
                                ? FontWeight.w500
                                : FontWeight.normal)),
                    subtitle: Text(
                        DateFormat.yMd().add_Hm().format(session.createdAt),
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary.withOpacity(0.7))),
                    onTap: () {
                      ref.read(activeSessionIdProvider.notifier).state =
                          session.id;
                      HapticFeedback.lightImpact();
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 16, color: AppColors.textSecondary),
                      onPressed: () {
                        ref
                            .read(sessionsProvider.notifier)
                            .deleteSession(session.id);
                        HapticFeedback.lightImpact();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Divider(color: AppColors.crystalBlue.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('AXON • Quantum Intelligence',
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.textSecondary.withOpacity(0.6),
                  letterSpacing: 0.5),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEnhancedAppBar() {
    final activeId = ref.watch(activeSessionIdProvider);
    final sessions = ref.watch(sessionsProvider);
    final activeSession = sessions.firstWhere((s) => s.id == activeId,
        orElse: () => ChatSession(
            id: '',
            title: "New Chat",
            messages: [],
            createdAt: DateTime.now()));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _buildGlowButton(
            icon: _isSidebarVisible
                ? Icons.menu_open_rounded
                : Icons.menu_rounded,
            onTap: _toggleSidebar,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activeSession.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.exo2(
                        fontSize: 22,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary,
                        letterSpacing: 2)),
                Text('Crystal Oracle Active',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          _buildGlowButton(
            icon: Icons.share_outlined,
            onTap: _shareCurrentSession,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.5);
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.crystalBlue.withOpacity(0.05),
          border: Border(
              bottom:
                  BorderSide(color: AppColors.crystalBlue.withOpacity(0.2)))),
      child: Row(
        children: [
          const Icon(Icons.search_rounded,
              color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text('Searching for "$_searchQuery"',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textSecondary, size: 20),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(List<ChatMessage> messages, bool isLoading) {
    if (messages.isEmpty && !isLoading) {
      return _buildEnhancedEmptyState();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.deepSpace.withOpacity(0.3),
        border: Border.all(color: AppColors.crystalBlue.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: -10,
              offset: const Offset(0, 15))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: messages.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == messages.length) return const TypingIndicator();
            return MessageBubble(message: messages[index])
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.2, curve: Curves.easeOutCubic);
          },
        ),
      ),
    );
  }

  Widget _buildEnhancedEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _crystalOrbController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                    0, math.sin(_crystalOrbController.value * 2 * math.pi) * 8),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.crystalBlue.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 5),
                      BoxShadow(
                          color: AppColors.etherealPink.withOpacity(0.2),
                          blurRadius: 60,
                          spreadRadius: 10),
                    ],
                  ),
                  child: ClipOval(
                      child: Image.asset('assets/images/logo.png',
                          fit: BoxFit.cover)),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text('The Crystal Oracle Awaits',
              style: GoogleFonts.exo2(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text('Ask anything • Analyze images • Use your voice',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5)),
          const SizedBox(height: 32),
          _buildQuickActions(),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 800.ms);
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildQuickActionButton(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Ideas',
            onTap: () =>
                _setPromptAndSend('Give me some creative ideas for a trip')),
        const SizedBox(width: 16),
        _buildQuickActionButton(
            icon: Icons.auto_awesome_rounded,
            label: 'Inspire',
            onTap: () =>
                _setPromptAndSend('Inspire me with something amazing')),
        const SizedBox(width: 16),
        _buildQuickActionButton(
            icon: Icons.psychology_outlined,
            label: 'Explain',
            onTap: () =>
                _setPromptAndSend('Explain a complex topic in simple terms')),
      ],
    );
  }

  Widget _buildQuickActionButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.crystalBlue.withOpacity(0.1),
          border: Border.all(color: AppColors.crystalBlue.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
                color: AppColors.crystalBlue.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.crystalBlue, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedInputArea(bool isLoading) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1.0,
              child: FadeTransition(opacity: animation, child: child)),
          child: _showSpellCheck
              ? _buildSpellCheckOverlay()
              : const SizedBox.shrink(),
        ),
        Container(
          margin: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.crystalBlue.withOpacity(0.05),
                    AppColors.etherealPink.withOpacity(0.03)
                  ]),
                  border:
                      Border.all(color: AppColors.crystalBlue.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildInputButton(
                            icon: Icons.add_photo_alternate_outlined,
                            onTap: _showImageOptions),
                        const SizedBox(width: 8),
                        _buildInputButton(
                            icon: Icons.mic_none_rounded,
                            onTap: _startRecording,
                            isVoice: true),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextInput()),
                        const SizedBox(width: 12),
                        _buildSendButton(isLoading),
                      ],
                    ),
                    Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: _buildQuickTools()),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 1),
      ],
    );
  }

  Widget _buildTextInput() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.deepSpace.withOpacity(0.3),
        border: Border.all(color: AppColors.crystalBlue.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _textFocusNode,
        style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 16),
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: 'Message AXON...',
          hintStyle: GoogleFonts.poppins(
              color: AppColors.textSecondary.withOpacity(0.7), fontSize: 16),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: (_) => _sendMessage(),
        onChanged: _checkSpelling,
      ),
    );
  }

  Widget _buildInputButton(
      {required IconData icon,
      required VoidCallback onTap,
      bool isVoice = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isVoice
              ? AppColors.accentGlow.withOpacity(0.1)
              : AppColors.crystalBlue.withOpacity(0.1),
          border: Border.all(
              color: isVoice
                  ? AppColors.accentGlow.withOpacity(0.3)
                  : AppColors.crystalBlue.withOpacity(0.3)),
          boxShadow: isVoice
              ? [
                  BoxShadow(
                      color: AppColors.accentGlow.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 2)
                ]
              : null,
        ),
        child: Icon(icon,
            color: isVoice ? AppColors.accentGlow : AppColors.crystalBlue,
            size: 22),
      ),
    );
  }

  Widget _buildSendButton(bool isLoading) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isLoading
            ? null
            : const LinearGradient(
                colors: [AppColors.crystalBlue, AppColors.etherealPink]),
        color: isLoading ? AppColors.textSecondary.withOpacity(0.3) : null,
        boxShadow: !isLoading
            ? [
                BoxShadow(
                    color: AppColors.crystalBlue.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2)
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isLoading ? null : () => _sendMessage(),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.textSecondary)))
                : const Icon(Icons.arrow_upward_rounded,
                    color: AppColors.deepSpace, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTools() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildQuickTool(
              icon: Icons.spellcheck_rounded,
              label: _spellCheckEnabled ? 'On' : 'Off',
              onTap: _toggleSpellCheck,
              isActive: _spellCheckEnabled),
          const SizedBox(width: 12),
          _buildQuickTool(
              icon: Icons.translate_rounded,
              label: 'Translate',
              onTap: () {
                final text = _controller.text.trim();
                if (text.isNotEmpty) {
                  _setPromptAndSend('Translate this text to English: $text');
                } else {
                  _setPrompt('Translate this text to English: ');
                }
              }),
          const SizedBox(width: 12),
          _buildQuickTool(
              icon: Icons.auto_fix_high_rounded,
              label: 'Improve',
              onTap: () {
                final text = _controller.text.trim();
                if (text.isNotEmpty) {
                  _setPromptAndSend('Improve and enhance this text: $text');
                } else {
                  _setPrompt('Improve this text: ');
                }
              }),
        ],
      ),
    );
  }

  Widget _buildQuickTool(
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive
              ? AppColors.crystalBlue.withOpacity(0.2)
              : AppColors.crystalBlue.withOpacity(0.05),
          border: Border.all(
              color: isActive
                  ? AppColors.crystalBlue.withOpacity(0.5)
                  : AppColors.crystalBlue.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color:
                    isActive ? AppColors.crystalBlue : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.crystalBlue.withOpacity(0.1),
          border: Border.all(color: AppColors.crystalBlue.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
                color: AppColors.crystalBlue.withOpacity(0.2),
                blurRadius: 12,
                spreadRadius: 1)
          ],
        ),
        child: Icon(icon, color: AppColors.crystalBlue, size: 20),
      ),
    );
  }

  Widget _buildVoiceRecordingOverlay() {
    String formatDuration(Duration duration) {
      String minutes = duration.inMinutes.toString().padLeft(2, '0');
      String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }

    return Positioned.fill(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: AppColors.deepSpace.withOpacity(0.9),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _voiceController,
                  builder: (context, child) => CustomPaint(
                      painter: EnhancedVoiceVisualizerPainter(
                          _voiceController.value, AppColors.accentGlow),
                      size: const Size(300, 150)),
                ),
                const SizedBox(height: 40),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.accentGlow.withOpacity(0.1),
                      border: Border.all(
                          color: AppColors.accentGlow.withOpacity(0.3))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.red),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scaleXY(end: 1.5, duration: 500.ms)
                          .then()
                          .scaleXY(end: 1 / 1.5, duration: 500.ms),
                      const SizedBox(width: 12),
                      Text('Recording...',
                          style: GoogleFonts.poppins(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(formatDuration(_recordDuration),
                    style: GoogleFonts.robotoMono(
                        color: AppColors.textPrimary,
                        fontSize: 48,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 60),
                GestureDetector(
                  onTap: _stopRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [Colors.red, Colors.red.withOpacity(0.8)]),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5)
                      ],
                    ),
                    child: const Icon(Icons.stop_rounded,
                        size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Tap to stop recording',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSpellCheckOverlay() {
    return Container(
      key: ValueKey(_misspelledWord),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.deepSpace.withOpacity(0.9),
        border: Border.all(color: AppColors.crystalBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text('Did you mean:',
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _suggestions
                  .map((suggestion) => GestureDetector(
                        onTap: () => _applySuggestion(suggestion),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.crystalBlue.withOpacity(0.1),
                          ),
                          child: Text(suggestion,
                              style: GoogleFonts.poppins(
                                  color: AppColors.crystalBlue, fontSize: 13)),
                        ),
                      ))
                  .toList(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textSecondary, size: 18),
            onPressed: () => setState(() => _showSpellCheck = false),
          ),
        ],
      ),
    );
  }
}

class EnhancedNebulaPainter extends CustomPainter {
  final double animationValue;

  EnhancedNebulaPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = ui.Gradient.linear(
          Offset.zero, Offset(size.width, size.height), [
        const Color(0xFF0A0514),
        const Color(0xFF130A24),
        const Color(0xFF1A0F2E)
      ]);

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final particlePaint = Paint();
    final random = math.Random(42);

    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final speed = random.nextDouble() * 30 + 10;
      final y = (startY - animationValue * speed * 2) % (size.height + 100);
      final radius = random.nextDouble() * 200 + 80;
      final opacity = (random.nextDouble() * 0.15 + 0.02) *
              math.sin(animationValue * 2 * math.pi + i) *
              0.5 +
          0.5;
      final color = Color.lerp(const Color(0xFFFFD6F5), const Color(0xFFD6EFFF),
          random.nextDouble())!;

      particlePaint.shader = ui.Gradient.radial(Offset(x, y), radius, [
        color.withOpacity(opacity),
        color.withOpacity(opacity * 0.3),
        Colors.transparent
      ], [
        0.0,
        0.6,
        1.0
      ]);

      particlePaint.maskFilter =
          const ui.MaskFilter.blur(ui.BlurStyle.normal, 80);
      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }

    for (int i = 0; i < 150; i++) {
      final x = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final speed = random.nextDouble() * 50 + 20;
      final y = (startY + animationValue * speed) % size.height;
      final starOpacity = random.nextDouble() * 0.8 + 0.1;

      particlePaint.color = Colors.white.withOpacity(starOpacity);
      particlePaint.shader = null;
      particlePaint.maskFilter = null;
      canvas.drawCircle(
          Offset(x, y), random.nextDouble() * 1.5 + 0.5, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class EnhancedVoiceVisualizerPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  EnhancedVoiceVisualizerPainter(this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10);

    final centerY = size.height / 2;

    for (int layer = 0; layer < 3; layer++) {
      final layerOpacity = 1.0 - (layer * 0.3);
      final amplitude = (size.height * 0.3) / (layer + 1);

      final path = Path();
      bool isFirst = true;

      for (double x = 0; x <= size.width; x += 2) {
        final progress = x / size.width;
        final wave1 = math.sin((animationValue * 4 + progress * 6) * math.pi);
        final wave2 =
            math.sin((animationValue * 2 + progress * 4) * math.pi) * 0.5;
        final wave3 =
            math.sin((animationValue * 8 + progress * 12) * math.pi) * 0.3;
        final y = centerY + (wave1 + wave2 + wave3) * amplitude;

        if (isFirst) {
          path.moveTo(x, y);
          isFirst = false;
        } else {
          path.lineTo(x, y);
        }
      }

      glowPaint.color = color.withOpacity(layerOpacity * 0.3);
      canvas.drawPath(path, glowPaint);

      paint.color = color.withOpacity(layerOpacity);
      canvas.drawPath(path, paint);
    }

    final pulseRadius = 20 + math.sin(animationValue * 4 * math.pi) * 15;
    final pulsePaint = Paint()
      ..shader = ui.Gradient.radial(
          Offset(size.width / 2, centerY),
          pulseRadius,
          [color.withOpacity(0.6), color.withOpacity(0.2), Colors.transparent]);

    canvas.drawCircle(Offset(size.width / 2, centerY), pulseRadius, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CrystalButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _CrystalButton({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
                colors: [AppColors.crystalBlue, AppColors.etherealPink]),
            boxShadow: [
              BoxShadow(
                  color: AppColors.crystalBlue.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2)
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CrystalDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<Widget> actions;

  const _CrystalDialog(
      {required this.title, required this.content, required this.actions});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.deepSpace.withOpacity(0.95),
            border: Border.all(color: AppColors.crystalBlue.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.exo2(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Text(content,
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrystalBottomSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _CrystalBottomSheet({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          color: AppColors.deepSpace.withOpacity(0.95),
          border: Border.all(color: AppColors.crystalBlue.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.exo2(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _BottomSheetOption(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.crystalBlue.withOpacity(0.1),
          border: Border.all(color: AppColors.crystalBlue.withOpacity(0.3)),
        ),
        child: Icon(icon, color: AppColors.crystalBlue, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
