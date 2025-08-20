import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  // Define the consistent color palette locally
  static const Color darkBlue = Color(0xFF283554);
  static const Color mauve = Color(0xFFC98ED4);
  static const Color lavender = Color(0xFFE7D8E7);
  static const Color lightBlue = Color(0xFF98AECF);
  static const Color tealBlue = Color(0xFF2D4E6A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: darkBlue,
              border: Border.all(color: tealBlue, width: 2),
            ),
            child: const Icon(
              Icons
                  .auto_awesome_outlined, // --- FIX: Consistent Upgraded Icon ---
              size: 22,
              color: lightBlue,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                // --- ENHANCEMENT: Matches new AI bubble color ---
                colors: [darkBlue, tealBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0.ms),
                const SizedBox(width: 8),
                _buildDot(200.ms),
                const SizedBox(width: 8),
                _buildDot(400.ms),
                const SizedBox(width: 12),
                Text(
                  'Axon is typing...', // --- FIX: Corrected AI Name ---
                  style: GoogleFonts.inter(
                    color: lightBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildDot(Duration delay) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: lightBlue,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(), delay: delay)
        .fade(begin: 0.3, end: 1.0, duration: 800.ms, curve: Curves.easeInOut)
        .then()
        .fade(begin: 1.0, end: 0.3, duration: 800.ms, curve: Curves.easeInOut);
  }
}
