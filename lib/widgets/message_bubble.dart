// lib/widgets/message_bubble.dart

import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../models/chat_message.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  const MessageBubble({super.key, required this.message});
  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  static const Color deepSpace = Color(0xFF0A0514);
  static const Color crystalBlue = Color(0xFFD6EFFF);
  static const Color etherealPink = Color(0xFFFFD6F5);
  static const Color textPrimary = Color(0xFFEAE6F3);
  static const Color textSecondary = Color(0xFFB8B0C8);

  @override
  void initState() {
    super.initState();
    if (widget.message.type == MessageType.voice) {
      _audioPlayer.onPlayerStateChanged.listen((s) => mounted ? setState(() => _isPlaying = s == PlayerState.playing) : null);
      _audioPlayer.onDurationChanged.listen((d) => mounted ? setState(() => _audioDuration = d) : null);
      _audioPlayer.onPositionChanged.listen((p) => mounted ? setState(() => _audioPosition = p) : null);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPauseAudio() async {
    if (widget.message.filePath != null) {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(DeviceFileSource(widget.message.filePath!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(radius: 20, backgroundColor: deepSpace, backgroundImage: AssetImage('assets/images/logo.png')),
            const SizedBox(width: 12),
          ],
          Flexible(child: _buildMessageContent(context, isUser)),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: isUser ? 0.2 : -0.2, curve: Curves.easeOutCubic);
  }

  Widget _buildMessageContent(BuildContext context, bool isUser) {
    final hasText = widget.message.text.isNotEmpty && widget.message.type != MessageType.voice;
    return Column(crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
      Container(
        padding: widget.message.type == MessageType.image ? const EdgeInsets.all(6) : EdgeInsets.zero,
        decoration: _bubbleDecoration(isUser),
        child: ClipRRect(
          borderRadius: _bubbleBorderRadius(isUser),
          child: widget.message.type == MessageType.voice ? _buildVoiceBubble(isUser)
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (widget.message.type == MessageType.image && widget.message.filePath != null) ...[
                Image.file(File(widget.message.filePath!), fit: BoxFit.cover, width: 250),
                if (hasText) const SizedBox(height: 8),
              ],
              if (hasText) Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: _buildTextContent(context, isUser),
              ),
            ]),
        ),
      ),
      if (isUser) ...[const SizedBox(height: 8), _buildTimestamp()]
    ]);
  }

  Widget _buildVoiceBubble(bool isUser) {
    final progress = (_audioDuration.inMilliseconds > 0) ? _audioPosition.inMilliseconds / _audioDuration.inMilliseconds : 0.0;
    String formatDuration(Duration d) => "${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), width: 250,
      child: Row(children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: isUser ? deepSpace : etherealPink, size: 30),
          onPressed: _playPauseAudio,
        ),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(trackHeight: 3.0, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0), overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0)),
            child: Slider(
              value: progress.clamp(0.0, 1.0), onChanged: (v) async => await _audioPlayer.seek(_audioDuration * v),
              activeColor: isUser ? deepSpace.withOpacity(0.8) : etherealPink,
              inactiveColor: isUser ? deepSpace.withOpacity(0.3) : etherealPink.withOpacity(0.3),
            ),
          ),
          Text('${formatDuration(_audioPosition)} / ${formatDuration(widget.message.audioDuration ?? _audioDuration)}',
            style: GoogleFonts.robotoMono(color: isUser ? deepSpace.withOpacity(0.8) : etherealPink, fontSize: 12),
          ),
        ])),
      ]),
    );
  }

  Widget _buildTextContent(BuildContext context, bool isUser) {
    final mdStyle = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: GoogleFonts.poppins(color: textPrimary, fontSize: 16, height: 1.5),
      code: GoogleFonts.robotoMono(backgroundColor: deepSpace.withOpacity(0.5), color: etherealPink),
      codeblockDecoration: BoxDecoration(color: deepSpace.withOpacity(0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: crystalBlue.withOpacity(0.2))),
      h1: GoogleFonts.exo2(color: textPrimary),
    );
    return isUser
      ? SelectableText(widget.message.text, style: GoogleFonts.poppins(color: deepSpace, fontSize: 16, height: 1.5, fontWeight: FontWeight.w500))
      : MarkdownBody(data: widget.message.text, selectable: true, styleSheet: mdStyle,
          builders: {'code': CodeElementBuilder()},
          extensionSet: md.ExtensionSet(md.ExtensionSet.gitHubWeb.blockSyntaxes, [md.EmojiSyntax(), ...md.ExtensionSet.gitHubWeb.inlineSyntaxes]),
        );
  }

  BorderRadius _bubbleBorderRadius(bool isUser) => BorderRadius.only(
    topLeft: const Radius.circular(24), topRight: const Radius.circular(24),
    bottomLeft: isUser ? const Radius.circular(24) : const Radius.circular(4),
    bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(24),
  );

  BoxDecoration _bubbleDecoration(bool isUser) => BoxDecoration(
    gradient: isUser ? const LinearGradient(colors: [etherealPink, crystalBlue], begin: Alignment.topRight, end: Alignment.bottomLeft) : null,
    color: isUser ? null : crystalBlue.withOpacity(0.1), borderRadius: _bubbleBorderRadius(isUser),
    border: isUser ? null : Border.all(color: crystalBlue.withOpacity(0.3)),
  );

  Widget _buildTimestamp() => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(DateFormat.Hm().format(widget.message.timestamp), style: GoogleFonts.poppins(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
    const SizedBox(width: 6),
    const Icon(Icons.done_all_rounded, size: 16, color: etherealPink).animate().fadeIn(delay: 500.ms).scale(),
  ]);
}

class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.textContent.isEmpty) return const SizedBox.shrink();
    return CodeBlock(text: element.textContent);
  }
}

class CodeBlock extends StatelessWidget {
  final String text; const CodeBlock({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Stack(children: [
    SelectableText(text, style: GoogleFonts.robotoMono(color: const Color(0xFFEAE6F3), backgroundColor: Colors.transparent, fontSize: 14)),
    Positioned(top: -10, right: -10, child: IconButton(
      icon: const Icon(Icons.copy_all_outlined, size: 18, color: Color(0xFFB8B0C8)),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied to clipboard!'), behavior: SnackBarBehavior.floating));
      },
    )),
  ]);
}