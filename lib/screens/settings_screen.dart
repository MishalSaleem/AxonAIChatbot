import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/chat_message.dart';
import '../models/providers.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _glowController;
  late AnimationController _floatController;
  late ScrollController _scrollController;

  // Animation preference state
  bool _animationsEnabled = true;
  AnimationStyle _animationStyle = AnimationStyle.gentle;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showClearConfirmation() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierColor: AppColors.deepSpace.withOpacity(0.8),
      builder: (BuildContext context) {
        return _CrystalDialog(
          title: 'Clear All Data?',
          content:
              'This will permanently delete all your chat sessions, settings, and data. This action cannot be undone.',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.orange,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _CrystalButton(
              onPressed: () {
                ref.read(sessionsProvider.notifier).clearAllSessions();
                Navigator.pop(context);
                _showSuccessSnackBar('All chat history cleared successfully');
                HapticFeedback.heavyImpact();
              },
              isDestructive: true,
              child: Text(
                'Clear All',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.crystalBlue, size: 20),
            const SizedBox(width: 12),
            Text(
              message,
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.deepSpace.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.crystalBlue.withOpacity(0.3)),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temperature = ref.watch(temperatureProvider);
    final sessions = ref.watch(sessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.deepSpace,
      body: Stack(
        children: [
          // Subtle animated background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) => CustomPaint(
              painter: SettingsBackgroundPainter(
                animationValue: _backgroundController.value,
                animationsEnabled: _animationsEnabled,
              ),
              size: MediaQuery.of(context).size,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildEnhancedAppBar(),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildWelcomeSection(),
                      const SizedBox(height: 24),
                      _buildAIConfigurationCard(temperature),
                      const SizedBox(height: 20),
                      _buildDataManagementCard(sessions.length),
                      const SizedBox(height: 20),
                      _buildUsageStatsCard(),
                      const SizedBox(height: 20),
                      _buildAdvancedFeaturesCard(),
                      const SizedBox(height: 20),
                      _buildAppearanceCard(),
                      const SizedBox(height: 20),
                      _buildAboutCard(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _buildGlowButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
          ),
          const SizedBox(width: 16),
          // Floating logo with gentle glow
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGlow.withOpacity(0.3),
                      blurRadius: 15 + 5 * _glowController.value,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AXON Settings',
                  style: GoogleFonts.exo2(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Crystal Oracle Configuration',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.crystalBlue.withOpacity(0.1),
            AppColors.etherealPink.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: AppColors.crystalBlue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.crystalBlue.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentGlow.withOpacity(0.3),
                      AppColors.accentGlow.withOpacity(0.1),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.textPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Welcome to AXON',
                style: GoogleFonts.exo2(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Customize your Crystal Oracle experience with advanced AI settings, data management, and performance optimization.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIConfigurationCard(double temperature) {
    return _buildSettingsCard(
      title: 'AI Configuration',
      icon: Icons.psychology_outlined,
      iconColor: AppColors.accentGlow,
      child: Column(
        children: [
          _buildModelSelector(),
          const SizedBox(height: 20),
          _buildTemperatureSlider(temperature),
        ],
      ),
    );
  }

  Widget _buildModelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('AI Model'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                AppColors.crystalBlue.withOpacity(0.1),
                AppColors.etherealPink.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.crystalBlue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentGlow.withOpacity(0.3),
                      AppColors.accentGlow.withOpacity(0.1),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.api_outlined,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cohere Command R+',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Advanced language model',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.crystalBlue.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.crystalBlue,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureSlider(double temperature) {
    String getCreativityLevel(double temp) {
      if (temp <= 0.3) return 'Focused';
      if (temp <= 0.7) return 'Balanced';
      return 'Creative';
    }

    Color getSliderColor(double temp) {
      if (temp <= 0.3) return AppColors.crystalBlue;
      if (temp <= 0.7) return AppColors.accentGlow;
      return AppColors.etherealPink;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Creativity Level'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    getSliderColor(temperature).withOpacity(0.2),
                    getSliderColor(temperature).withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                    color: getSliderColor(temperature).withOpacity(0.5)),
              ),
              child: Text(
                '${getCreativityLevel(temperature)} (${(temperature * 100).toInt()}%)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: getSliderColor(temperature),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Icon(Icons.precision_manufacturing,
                  color: AppColors.crystalBlue, size: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: getSliderColor(temperature),
                    inactiveTrackColor:
                        getSliderColor(temperature).withOpacity(0.2),
                    thumbColor: getSliderColor(temperature),
                    overlayColor: getSliderColor(temperature).withOpacity(0.2),
                    trackHeight: 6,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 12),
                  ),
                  child: Slider(
                    value: temperature,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    onChanged: (value) {
                      ref.read(temperatureProvider.notifier).state = value;
                      HapticFeedback.selectionClick();
                    },
                  ),
                ),
              ),
              const Icon(Icons.auto_awesome, color: AppColors.etherealPink, size: 16),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Precise',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text('Creative',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataManagementCard(int sessionCount) {
    return _buildSettingsCard(
      title: 'Data Management',
      icon: Icons.storage_outlined,
      iconColor: Colors.orange,
      child: Column(
        children: [
          _buildInfoTile('Chat Sessions', '$sessionCount conversations',
              Icons.chat_outlined),
          const SizedBox(height: 16),
          _buildInfoTile(
              'Storage Used',
              '${(sessionCount * 0.5).toStringAsFixed(1)} MB',
              Icons.storage_outlined),
          const SizedBox(height: 16),
          _buildInfoTile(
              'Last Backup', 'Auto-save enabled', Icons.cloud_sync_outlined),
          const SizedBox(height: 20),
          _CrystalButton(
            onPressed: _showClearConfirmation,
            isDestructive: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_sweep_outlined,
                    size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text('Clear All Data',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStatsCard() {
    return _buildSettingsCard(
      title: 'Usage Statistics',
      icon: Icons.analytics_outlined,
      iconColor: AppColors.accentGlow,
      child: Column(
        children: [
          _buildStatItem('Total Messages', '1,247', Icons.message_outlined,
              AppColors.crystalBlue),
          const SizedBox(height: 16),
          _buildStatItem('Images Analyzed', '89', Icons.image_outlined,
              AppColors.etherealPink),
          const SizedBox(height: 16),
          _buildStatItem('Voice Messages', '156', Icons.mic_outlined,
              AppColors.accentGlow),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary)),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedFeaturesCard() {
    return _buildSettingsCard(
      title: 'Advanced Features',
      icon: Icons.tune_outlined,
      iconColor: Colors.purple,
      child: Column(
        children: [
          _buildFeatureToggle(
              'Auto Spell Check',
              'Automatically detect and suggest spelling corrections',
              Icons.spellcheck_outlined,
              true),
          const SizedBox(height: 16),
          _buildFeatureToggle(
              'Smart Suggestions',
              'Show contextual suggestions while typing',
              Icons.lightbulb_outline,
              true),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard() {
    return _buildSettingsCard(
      title: 'Appearance',
      icon: Icons.palette_outlined,
      iconColor: AppColors.crystalBlue,
      child: Column(
        children: [
          _buildSectionTitle('Animations'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _animationsEnabled = true;
                      _animationStyle = AnimationStyle.gentle;
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _animationsEnabled &&
                              _animationStyle == AnimationStyle.gentle
                          ? AppColors.crystalBlue.withOpacity(0.2)
                          : AppColors.deepSpace.withOpacity(0.3),
                      border: Border.all(
                        color: _animationsEnabled &&
                                _animationStyle == AnimationStyle.gentle
                            ? AppColors.crystalBlue
                            : AppColors.crystalBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.water_drop_outlined,
                          color: _animationsEnabled &&
                                  _animationStyle == AnimationStyle.gentle
                              ? AppColors.crystalBlue
                              : AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gentle',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _animationsEnabled &&
                                    _animationStyle == AnimationStyle.gentle
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _animationsEnabled = true;
                      _animationStyle = AnimationStyle.dynamic;
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _animationsEnabled &&
                              _animationStyle == AnimationStyle.dynamic
                          ? AppColors.accentGlow.withOpacity(0.2)
                          : AppColors.deepSpace.withOpacity(0.3),
                      border: Border.all(
                        color: _animationsEnabled &&
                                _animationStyle == AnimationStyle.dynamic
                            ? AppColors.accentGlow
                            : AppColors.crystalBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: _animationsEnabled &&
                                  _animationStyle == AnimationStyle.dynamic
                              ? AppColors.accentGlow
                              : AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dynamic',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _animationsEnabled &&
                                    _animationStyle == AnimationStyle.dynamic
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _animationsEnabled = false;
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: !_animationsEnabled
                          ? AppColors.etherealPink.withOpacity(0.2)
                          : AppColors.deepSpace.withOpacity(0.3),
                      border: Border.all(
                        color: !_animationsEnabled
                            ? AppColors.etherealPink
                            : AppColors.crystalBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.do_not_disturb_on_outlined,
                          color: !_animationsEnabled
                              ? AppColors.etherealPink
                              : AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Off',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: !_animationsEnabled
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureToggle(
      String title, String description, IconData icon, bool isEnabled) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isEnabled ? AppColors.accentGlow : AppColors.textSecondary)
                .withOpacity(0.1),
            border: Border.all(
                color:
                    (isEnabled ? AppColors.accentGlow : AppColors.textSecondary)
                        .withOpacity(0.3)),
          ),
          child: Icon(icon,
              color: isEnabled ? AppColors.accentGlow : AppColors.textSecondary,
              size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500)),
              Text(description,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Switch(
          value: isEnabled,
          activeColor: AppColors.crystalBlue,
          onChanged: (value) {
            HapticFeedback.lightImpact();
          },
        ),
      ],
    );
  }

  Widget _buildAboutCard() {
    return _buildSettingsCard(
      title: 'About AXON',
      icon: Icons.info_outline,
      iconColor: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoTile('Version', '2.1.0 (Crystal)', Icons.verified_outlined),
          const SizedBox(height: 16),
          _buildInfoTile(
              'Developer', 'Crystal Oracle Labs', Icons.code_outlined),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
      {required String title,
      required IconData icon,
      required Color iconColor,
      required Widget child}) {
    Widget card = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepSpace.withOpacity(0.6),
            AppColors.deepSpace.withOpacity(0.3),
          ],
        ),
        border: Border.all(color: AppColors.crystalBlue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.1),
                  border: Border.all(color: iconColor.withOpacity(0.3)),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 16),
              Text(title,
                  style: GoogleFonts.exo2(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );

    // Apply animations based on user preference
    if (_animationsEnabled) {
      if (_animationStyle == AnimationStyle.gentle) {
        card = card
            .animate(onPlay: (controller) => controller.repeat())
            .then()
            .scaleXY(
                begin: 1,
                end: 1.01,
                duration: 3000.ms,
                curve: Curves.easeInOutSine)
            .then()
            .scaleXY(
                begin: 1.01,
                end: 1,
                duration: 3000.ms,
                curve: Curves.easeInOutSine);
      } else if (_animationStyle == AnimationStyle.dynamic) {
        card = card
            .animate(onPlay: (controller) => controller.repeat())
            .then()
            .shimmer(delay: 1000.ms, duration: 2000.ms)
            .then()
            .scaleXY(
                begin: 1,
                end: 1.02,
                duration: 2000.ms,
                curve: Curves.easeInOutSine)
            .then()
            .scaleXY(
                begin: 1.02,
                end: 1,
                duration: 2000.ms,
                curve: Curves.easeInOutSine);
      }
    }

    return card;
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.crystalBlue, size: 18),
        const SizedBox(width: 12),
        Expanded(
            child: Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary))),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500)),
      ],
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
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.crystalBlue, size: 20),
      ),
    );
  }
}

// Custom Widgets
class _CrystalButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool isDestructive;

  const _CrystalButton(
      {required this.onPressed,
      required this.child,
      this.isDestructive = false});

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
            gradient: isDestructive
                ? LinearGradient(
                    colors: [Colors.red, Colors.red.withOpacity(0.8)])
                : const LinearGradient(
                    colors: [AppColors.crystalBlue, AppColors.etherealPink]),
            boxShadow: [
              BoxShadow(
                  color: (isDestructive ? Colors.red : AppColors.crystalBlue)
                      .withOpacity(0.3),
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
  final IconData? icon;
  final Color? iconColor;
  final List<Widget> actions;

  const _CrystalDialog(
      {required this.title,
      required this.content,
      required this.actions,
      this.icon,
      this.iconColor});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.deepSpace.withOpacity(0.95),
                AppColors.deepSpace.withOpacity(0.85),
              ],
            ),
            border: Border.all(color: AppColors.crystalBlue.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (iconColor ?? AppColors.crystalBlue).withOpacity(0.3),
                        (iconColor ?? AppColors.crystalBlue).withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                        color: (iconColor ?? AppColors.crystalBlue)
                            .withOpacity(0.3)),
                  ),
                  child: Icon(icon,
                      color: iconColor ?? AppColors.crystalBlue, size: 28),
                ),
                const SizedBox(height: 20),
              ],
              Text(title,
                  style: GoogleFonts.exo2(
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                      letterSpacing: 1),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(content,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 28),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Settings Background
class SettingsBackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool animationsEnabled;

  SettingsBackgroundPainter(
      {required this.animationValue, required this.animationsEnabled});

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle gradient background
    final backgroundPaint = Paint()
      ..shader =
          ui.Gradient.linear(Offset.zero, Offset(size.width, size.height), [
        const Color(0xFF0A0514),
        const Color(0xFF130A24),
        const Color(0xFF1A0F2E),
        const Color(0xFF0A0514)
      ], [
        0.0,
        0.3,
        0.7,
        1.0
      ]);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    if (!animationsEnabled) return;

    // Subtle floating shapes
    final shapePaint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(789);

    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final speed = random.nextDouble() * 5 + 3;
      final y = (startY + animationValue * speed * 2) % (size.height + 200);
      final shapeSize = random.nextDouble() * 60 + 30;
      final opacity = (random.nextDouble() * 0.03 + 0.01) *
              math.sin(animationValue * 2 * math.pi + i * 0.5) *
              0.5 +
          0.5;
      final color = Color.lerp(const Color(0xFFFFD6F5), const Color(0xFFD6EFFF),
          random.nextDouble())!;
      final path = Path();
      final centerX = x;
      final centerY = y;
      final radius = shapeSize / 2;

      // Create hexagon shape
      for (int j = 0; j < 6; j++) {
        final angle = (j * 60) * math.pi / 180;
        final pointX = centerX + radius * math.cos(angle);
        final pointY = centerY + radius * math.sin(angle);
        if (j == 0) {
          path.moveTo(pointX, pointY);
        } else {
          path.lineTo(pointX, pointY);
        }
      }
      path.close();

      shapePaint.shader = ui.Gradient.radial(Offset(centerX, centerY), radius, [
        color.withOpacity(opacity),
        color.withOpacity(opacity * 0.3),
        Colors.transparent
      ], [
        0.0,
        0.7,
        1.0
      ]);
      shapePaint.maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 30);
      canvas.drawPath(path, shapePaint);
    }

    // Subtle stars
    final starPaint = Paint();
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final twinkle =
          math.sin(animationValue * 4 * math.pi + i * 0.3) * 0.5 + 0.5;
      final opacity = random.nextDouble() * 0.3 * twinkle;
      starPaint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(
          Offset(x, y), random.nextDouble() * 1.2 + 0.5, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Animation style enum
enum AnimationStyle {
  gentle,
  dynamic,
}
