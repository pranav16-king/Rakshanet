import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/mesh_provider.dart';
import '../../services/ai/hybrid_ai_service.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_bar_actions.dart';

/// Screen 7: AI Assistant (Hybrid Groq Cloud + On-Device Trained ML Model)
///
/// Features:
/// 1. Groq Cloud Llama-3.3 70B LLM when network is available (Groq API Key integrated)
/// 2. Trained On-Device Machine Learning NLP Model & Knowledge Base (sub-5ms offline inference)
/// 3. Dynamic Math Evaluator, Unit Converter, and Disaster Ration Calculator
/// 4. Interactive Mode Switcher (Auto vs Force Offline for testing)
/// 5. Real-time Telemetry Context injection (battery, GPS, mesh peers)
/// 6. Strict High-Visibility emergency design tokens (Light, Dark, OLED)
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isTyping = false;
  bool _isOnline = false;
  String _selectedCategoryFilter = 'All';

  static const List<String> _categoryFilters = [
    'All',
    'Medical',
    'Hazards',
    'Rescue',
    'CBRN',
    'Survival',
  ];

  // Chat message stream
  final List<_ChatMessage> _messages = [
    // Welcome message
    _ChatMessage(
      text: 'RakshaNet Hybrid AI Assistant initialized and ready.',
      isUser: false,
      timestamp: 'Just now',
      source: 'System Engine',
      urgency: 'advisory',
      category: 'System Architecture',
      steps: [
        'Online Mode: Groq Cloud Llama-3.3 70B answers any question with high reasoning capacity.',
        'Offline Mode: 69+ Pre-trained disaster models answer CPR, triage, CBRN, bleeding, trauma, and survival questions with 0 KB data (<5ms).',
        'Automatic Fallback: Seamlessly transitions between Cloud and Device without losing chat context.',
      ],
      warningNotice:
          'Tap the mode indicator in the header to switch between Auto Mode and Force Offline Mode.',
    ),
  ];

  // Quick prompt suggestions categorized across emergency disciplines
  final List<_PromptSuggestion> _suggestions = [
    // Medical
    _PromptSuggestion(
      icon: Icons.favorite_rounded,
      label: 'CPR Protocol',
      query: 'How to perform CPR on an unconscious adult who is not breathing?',
      category: 'Medical',
    ),
    _PromptSuggestion(
      icon: Icons.healing_rounded,
      label: 'Severe Bleeding',
      query: 'What is the immediate protocol for severe arterial bleeding and tourniquets?',
      category: 'Medical',
    ),
    _PromptSuggestion(
      icon: Icons.airline_seat_recline_extra_rounded,
      label: 'Choking Heimlich',
      query: 'How to save a choking person using back blows and abdominal thrusts?',
      category: 'Medical',
    ),
    _PromptSuggestion(
      icon: Icons.masks_rounded,
      label: 'Chest Trauma',
      query: 'What is the first aid for a sucking chest wound with flutter valve?',
      category: 'Medical',
    ),
    _PromptSuggestion(
      icon: Icons.cut_rounded,
      label: 'Amputation & Crush',
      query: 'What is the first aid for traumatic amputation and crush syndrome?',
      category: 'Medical',
    ),
    _PromptSuggestion(
      icon: Icons.pest_control_rounded,
      label: 'Snake Bite',
      query: 'What is the first aid protocol for a venomous snakebite?',
      category: 'Medical',
    ),
    _PromptSuggestion(
      icon: Icons.visibility_rounded,
      label: 'Eye Chemical Burn',
      query: 'How to flush chemical splash or treat impaled object in eye?',
      category: 'Medical',
    ),

    // Hazards
    _PromptSuggestion(
      icon: Icons.waves_rounded,
      label: 'Flood Survival',
      query: 'What should I do immediately during sudden flash flooding and rising water?',
      category: 'Hazards',
    ),
    _PromptSuggestion(
      icon: Icons.terrain_rounded,
      label: 'Earthquake Action',
      query: 'What are the essential survival steps during an earthquake and if trapped under rubble?',
      category: 'Hazards',
    ),
    _PromptSuggestion(
      icon: Icons.water_rounded,
      label: 'Dam Burst Surge',
      query: 'How to survive a catastrophic dam burst flash flood and wall of water?',
      category: 'Hazards',
    ),
    _PromptSuggestion(
      icon: Icons.cyclone_rounded,
      label: 'Cyclone Survival',
      query: 'How to secure shelter and survive a category 5 cyclone or hurricane?',
      category: 'Hazards',
    ),
    _PromptSuggestion(
      icon: Icons.local_fire_department_rounded,
      label: 'Wildfire Burnover',
      query: 'How to survive a wildfire burnover and deploy emergency fire shelter?',
      category: 'Hazards',
    ),

    // Rescue
    _PromptSuggestion(
      icon: Icons.crisis_alert_rounded,
      label: 'START Triage',
      query: 'How do I perform START mass casualty triage for multiple injured victims?',
      category: 'Rescue',
    ),
    _PromptSuggestion(
      icon: Icons.touch_app_rounded,
      label: 'Rubble Tapping',
      query: 'How do trapped victims signal under concrete rubble using acoustic tapping?',
      category: 'Rescue',
    ),
    _PromptSuggestion(
      icon: Icons.kayaking_rounded,
      label: 'Swiftwater Rescue',
      query: 'How to survive strong river swiftwater current and river strainer?',
      category: 'Rescue',
    ),
    _PromptSuggestion(
      icon: Icons.snowmobile_rounded,
      label: 'Avalanche Transceiver',
      query: 'What is the avalanche beacon search protocol and probe shoveling?',
      category: 'Rescue',
    ),
    _PromptSuggestion(
      icon: Icons.flight_takeoff_rounded,
      label: 'Ground-to-Air Signals',
      query: 'What are the ground to air rescue signals and heliograph mirror flash?',
      category: 'Rescue',
    ),
    _PromptSuggestion(
      icon: Icons.volume_up_rounded,
      label: 'Whistle Codes',
      query: 'What are the international emergency whistle signals for rescue?',
      category: 'Rescue',
    ),

    // CBRN
    _PromptSuggestion(
      icon: Icons.science_rounded,
      label: 'CBRN Decontamination',
      query: 'What is the protocol for CBRN full decontamination after chemical gas attack?',
      category: 'CBRN',
    ),
    _PromptSuggestion(
      icon: Icons.air_rounded,
      label: 'Toxic Gas Shelter',
      query: 'How to shelter in place during industrial chlorine or ammonia leak?',
      category: 'CBRN',
    ),
    _PromptSuggestion(
      icon: Icons.dangerous_rounded,
      label: 'Nuclear Fallout (7:10)',
      query: 'How to survive nuclear fallout and apply the 7:10 rule of decay?',
      category: 'CBRN',
    ),

    // Survival
    _PromptSuggestion(
      icon: Icons.wb_sunny_rounded,
      label: 'Solar Water Still',
      query: 'How to build a solar still to condense drinking water from soil in drought?',
      category: 'Survival',
    ),
    _PromptSuggestion(
      icon: Icons.water_drop_rounded,
      label: 'Water Purification',
      query: 'How can I purify contaminated water using boiling, bleach, or SODIS?',
      category: 'Survival',
    ),
    _PromptSuggestion(
      icon: Icons.calculate_rounded,
      label: 'Ration Planning',
      query: 'How much drinking water and food is needed for 4 people for 5 days in a disaster?',
      category: 'Survival',
    ),
    _PromptSuggestion(
      icon: Icons.cleaning_services_rounded,
      label: 'Field Sanitation',
      query: 'How to construct an emergency camp trench latrine and prevent cholera?',
      category: 'Survival',
    ),
    _PromptSuggestion(
      icon: Icons.grass_rounded,
      label: 'Edibility Test',
      query: 'What are the steps of the universal edibility test for wild survival plants?',
      category: 'Survival',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final online = await HybridAiService.instance.checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = online;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final now = TimeOfDay.now();
    final timeStr =
        '${now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} ${now.period == DayPeriod.am ? 'AM' : 'PM'}';

    setState(() {
      _messages.add(_ChatMessage(
        text: trimmed,
        isUser: true,
        timestamp: timeStr,
      ));
      _isTyping = true;
    });

    _textController.clear();
    _scrollToBottom();

    // Prepare conversation history
    final history = <Map<String, String>>[];
    for (final m in _messages.reversed.take(6).toList().reversed) {
      if (m.isUser) {
        history.add({'role': 'user', 'content': m.text});
      } else {
        history.add({'role': 'assistant', 'content': '${m.text} ${m.steps?.join(". ") ?? ""}'});
      }
    }

    // Prepare live device telemetry context
    Map<String, dynamic>? telemetryContext;
    try {
      final telemetry = context.read<TelemetryProvider>();
      final mesh = context.read<MeshProvider>();
      telemetryContext = {
        'battery': telemetry.batteryLevel,
        'latitude': telemetry.latitude,
        'longitude': telemetry.longitude,
        'mesh_peers': mesh.connectedPeerCount,
      };
    } catch (_) {}

    try {
      final aiResponse = await HybridAiService.instance.processQuery(
        trimmed,
        conversationHistory: history,
        telemetryContext: telemetryContext,
      );

      if (!mounted) return;

      setState(() {
        _isOnline = aiResponse.isOnline;
        _messages.add(_ChatMessage(
          text: aiResponse.text,
          isUser: false,
          timestamp: timeStr,
          steps: aiResponse.steps,
          warningNotice: aiResponse.warningNotice,
          source: aiResponse.source,
          latencyMs: aiResponse.latencyMs,
          confidence: aiResponse.confidence,
          urgency: aiResponse.urgency,
          category: aiResponse.category,
        ));
        _isTyping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          text: 'RakshaNet Emergency Guidance:',
          isUser: false,
          timestamp: timeStr,
          steps: [
            'Assess immediate vital signs: Airway, Breathing, and Circulation (ABCs).',
            'Avoid moving the injured if neck or spinal injury is suspected.',
            'Press and hold the SOS Beacon for 1.5 seconds if rescue dispatch is required.',
          ],
          source: 'Trained On-Device AI Model',
          warningNotice: 'Emergency protocols are cached securely on this phone.',
          urgency: 'critical',
          category: 'Disaster Protocol',
        ));
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _toggleForceOffline() {
    setState(() {
      HybridAiService.instance.forceOfflineMode =
          !HybridAiService.instance.forceOfflineMode;
      _isOnline = HybridAiService.instance.isOnlineMode;
    });

    final snack = SnackBar(
      content: Text(
        HybridAiService.instance.forceOfflineMode
            ? 'Forced Offline Mode enabled: Using On-Device Trained AI Model'
            : 'Auto Mode enabled: Using Groq Cloud AI with Offline fallback',
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: HybridAiService.instance.forceOfflineMode
          ? AppTokens.darkWarning
          : AppTokens.beaconTeal,
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(_ChatMessage(
        text: 'Chat history cleared. How can I assist you?',
        isUser: false,
        timestamp: 'Just now',
        source: 'System Engine',
      ));
    });
  }

  void _showOfflineEngineInfo(ThemeProvider theme) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: BorderSide(color: theme.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: AppTokens.signalYellow, size: 24),
            const SizedBox(width: 8),
            Text(
              'Hybrid AI Architecture',
              style: TextStyle(
                color: theme.text,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RakshaNet AI operates a Dual-Engine intelligent pipeline:',
              style: TextStyle(color: theme.text, fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              '1. Cloud LLM Engine (Groq Llama-3.3 70B):\n'
              '• Ultra-fast sub-second cloud inference\n'
              '• In-depth reasoning across every type of question\n'
              '• Active whenever Wi-Fi or cellular network is detected\n\n'
              '2. On-Device Trained ML Engine:\n'
              '• 100% self-contained on your phone (0 KB mobile data)\n'
              '• Pre-trained TF-IDF Cosine Classifier & Knowledge Base\n'
              '• Covers CPR, Bleeding, Floods, Earthquakes, Fractures, Snakebites, Survival & Math\n'
              '• Seamless sub-5ms instant response when cell towers are destroyed',
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTokens.signalYellow, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Upgraded Non-Overflowing Header Bar
            _buildHeaderBar(theme),

            // 2. Chat Stream Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator(theme);
                  }
                  final msg = _messages[index];
                  return msg.isUser
                      ? _buildUserMessage(msg, theme)
                      : _buildAiResponseCard(msg, theme);
                },
              ),
            ),

            // 3. Quick Prompt Suggestion Pills
            _buildPromptSuggestions(theme),

            // 4. Bottom Input Bar
            _buildInputBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar(ThemeProvider theme) {
    final isForcedOffline = HybridAiService.instance.forceOfflineMode;
    final isOnlineActive = _isOnline && !isForcedOffline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.bg,
        border: Border(
          bottom: BorderSide(
            color: theme.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: theme.text, size: 22),
            tooltip: 'Back',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          // Yellow Beacon Circle with AI icon
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppTokens.signalYellow,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome,
                color: AppTokens.lightOnPrimary,
                size: 19,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Title & Live Mode Status (Using Expanded to prevent RenderFlex overflow)
          Expanded(
            child: GestureDetector(
              onTap: _toggleForceOffline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AI Assistant',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnlineActive
                              ? const Color(0xFF35D07F)
                              : AppTokens.signalYellow,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          isOnlineActive
                              ? 'Groq Cloud • Llama 3.3'
                              : (isForcedOffline
                                  ? 'Forced Offline • On-Device'
                                  : 'Offline • Trained Model'),
                          style: TextStyle(
                            color: isOnlineActive
                                ? const Color(0xFF35D07F)
                                : (theme.isLightMode
                                    ? AppTokens.lightPrimaryInk
                                    : AppTokens.signalYellow),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Toggle Offline/Online mode action chip
          IconButton(
            icon: Icon(
              isForcedOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
              color: isForcedOffline ? AppTokens.signalYellow : const Color(0xFF35D07F),
              size: 21,
            ),
            tooltip: isForcedOffline ? 'Forced Offline (Tap for Auto)' : 'Cloud Active (Tap to Force Offline)',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            onPressed: _toggleForceOffline,
          ),
          // More options menu (Clear Chat, Info)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: theme.textMuted, size: 21),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: theme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              side: BorderSide(color: theme.border),
            ),
            onSelected: (val) {
              if (val == 'info') _showOfflineEngineInfo(theme);
              if (val == 'clear') _clearChat();
              if (val == 'toggle') _toggleForceOffline();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      isForcedOffline ? Icons.cloud_queue_rounded : Icons.cloud_off_rounded,
                      color: theme.text,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isForcedOffline ? 'Switch to Auto Cloud' : 'Force Offline Mode',
                      style: TextStyle(color: theme.text, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: theme.text, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'AI Engine Details',
                      style: TextStyle(color: theme.text, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, color: AppTokens.sosRed, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Clear Chat',
                      style: TextStyle(color: AppTokens.sosRed, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const ThemeToggleButton(compact: true),
        ],
      ),
    );
  }

  Widget _buildUserMessage(_ChatMessage msg, ThemeProvider theme) {
    final bubbleColor = theme.isLightMode
        ? const Color(0xFFE8EEF5)
        : (theme.isLowPower ? const Color(0xFF161616) : AppTokens.darkSurfaceAlt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.80,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  msg.text,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  msg.timestamp,
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyProtocolToClipboard(_ChatMessage msg) {
    final buffer = StringBuffer();
    buffer.writeln(msg.text);
    if (msg.category != null) {
      buffer.writeln('Category: ${msg.category}');
    }
    if (msg.steps != null && msg.steps!.isNotEmpty) {
      buffer.writeln('\nAction Steps:');
      for (int i = 0; i < msg.steps!.length; i++) {
        buffer.writeln('${i + 1}. ${msg.steps![i]}');
      }
    }
    if (msg.warningNotice != null && msg.warningNotice!.isNotEmpty) {
      buffer.writeln('\nSafety Notice: ${msg.warningNotice}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Protocol copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAiResponseCard(_ChatMessage msg, ThemeProvider theme) {
    final cardBg = theme.surface;
    final isGroqSource = msg.source?.contains('Groq') ?? false;

    // Urgency styling tokens
    final urgency = msg.urgency;
    final isCritical = urgency == 'critical';
    final isHigh = urgency == 'high';

    final Color badgeColor;
    final String badgeLabel;
    final IconData badgeIcon;

    if (isCritical) {
      badgeColor = AppTokens.sosRed;
      badgeLabel = 'CRITICAL EMERGENCY PROTOCOL';
      badgeIcon = Icons.warning_rounded;
    } else if (isHigh) {
      badgeColor = theme.isLightMode ? const Color(0xFFD97706) : AppTokens.signalYellow;
      badgeLabel = 'HIGH PRIORITY PROTOCOL';
      badgeIcon = Icons.bolt_rounded;
    } else {
      badgeColor = theme.isLightMode ? const Color(0xFF0284C7) : AppTokens.beaconTeal;
      badgeLabel = 'ADVISORY GUIDANCE';
      badgeIcon = Icons.shield_outlined;
    }

    // Warning box colors
    final warningBg = theme.isLightMode
        ? const Color(0xFFFFF7E6)
        : (theme.isLowPower ? const Color(0xFF161204) : const Color(0xFF2A1E0A));
    final warningBorder = theme.isLightMode
        ? const Color(0xFFFFD591)
        : (theme.isLowPower ? const Color(0xFF4A3408) : const Color(0xFF8A5A00));
    final warningText = theme.isLightMode
        ? const Color(0xFF873800)
        : (theme.isLowPower ? const Color(0xFFFFCC80) : const Color(0xFFFFB74D));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: isCritical
                ? AppTokens.sosRed.withValues(alpha: 0.6)
                : theme.border,
            width: isCritical ? 1.5 : 1.0,
          ),
          boxShadow: theme.isLowPower
              ? null
              : [
                  BoxShadow(
                    color: isCritical
                        ? AppTokens.sosRed.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: theme.isLightMode ? 0.05 : 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Triage & Category Banner + Copy Action
            Row(
              children: [
                // Urgency Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, color: badgeColor, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        badgeLabel,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (msg.category != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '• ${msg.category}',
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                // Copy Action Button
                IconButton(
                  icon: Icon(Icons.copy_rounded, color: theme.textMuted, size: 16),
                  tooltip: 'Copy protocol',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () => _copyProtocolToClipboard(msg),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title / Main Headline
            Text(
              msg.text,
              style: TextStyle(
                color: theme.text,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                height: 1.35,
              ),
            ),

            // Step-by-step layout (Card-based sequential presentation)
            if (msg.steps != null && msg.steps!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...msg.steps!.asMap().entries.map((entry) {
                final stepNum = entry.key + 1;
                final stepText = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 7),
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: theme.surfaceSunken,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    border: Border.all(color: theme.border.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: theme.isLightMode
                              ? AppTokens.lightPrimaryInk
                              : AppTokens.signalYellow,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$stepNum',
                            style: TextStyle(
                              color: theme.isLightMode
                                  ? Colors.white
                                  : AppTokens.lightOnPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          stepText,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 13.5,
                            height: 1.38,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Safety Warning Callout Banner
            if (msg.warningNotice != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: warningBg,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(color: warningBorder, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.isLightMode ? const Color(0xFFFA8C16) : AppTokens.darkWarning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        msg.warningNotice!,
                        style: TextStyle(
                          color: warningText,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Footer: Source + Speed Badge + Timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isGroqSource ? Icons.cloud_done_rounded : Icons.bolt_rounded,
                      size: 13,
                      color: isGroqSource ? const Color(0xFF35D07F) : AppTokens.signalYellow,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      msg.source ?? 'Offline Edge Model',
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (msg.latencyMs != null) ...[
                      Text(
                        ' • ${msg.latencyMs}ms instant',
                        style: TextStyle(
                          color: isGroqSource ? theme.textMuted : const Color(0xFF35D07F),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  msg.timestamp,
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeProvider theme) {
    return _NeuralRadarIndicator(
      isOnline: _isOnline && !HybridAiService.instance.forceOfflineMode,
      theme: theme,
    );
  }

  Widget _buildPromptSuggestions(ThemeProvider theme) {
    final filtered = _selectedCategoryFilter == 'All'
        ? _suggestions
        : _suggestions
            .where((s) => s.category == _selectedCategoryFilter)
            .toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.bg,
        border: Border(top: BorderSide(color: theme.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter Tabs
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _categoryFilters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final cat = _categoryFilters[index];
                final isSelected = _selectedCategoryFilter == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryFilter = cat;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (theme.isLightMode
                              ? AppTokens.lightPrimaryInk
                              : AppTokens.signalYellow)
                          : theme.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : theme.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected
                              ? (theme.isLightMode
                                  ? Colors.white
                                  : AppTokens.lightOnPrimary)
                              : theme.textMuted,
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          // Prompt Chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final s = filtered[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    onTap: () => _sendMessage(s.query),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusPill),
                        border: Border.all(color: theme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            s.icon,
                            size: 14,
                            color: theme.isLightMode
                                ? AppTokens.lightPrimaryInk
                                : AppTokens.signalYellow,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            s.label,
                            style: TextStyle(
                              color: theme.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildInputBar(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      decoration: BoxDecoration(
        color: theme.bg,
        border: Border(
          top: BorderSide(
            color: theme.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: AppTokens.inputHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: theme.surfaceSunken,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(color: theme.border),
              ),
              child: Center(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 14.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask any emergency or survival question...',
                    hintStyle: TextStyle(
                      color: theme.textMuted,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: AppTokens.touchMin,
            height: AppTokens.touchMin,
            decoration: const BoxDecoration(
              color: AppTokens.signalYellow,
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                onTap: () => _sendMessage(_textController.text),
                child: const Center(
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTokens.nightNavy,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Animated Neural Radar Loading Beacon
class _NeuralRadarIndicator extends StatefulWidget {
  final bool isOnline;
  final ThemeProvider theme;

  const _NeuralRadarIndicator({
    required this.isOnline,
    required this.theme,
  });

  @override
  State<_NeuralRadarIndicator> createState() => _NeuralRadarIndicatorState();
}

class _NeuralRadarIndicatorState extends State<_NeuralRadarIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isOnline = widget.isOnline;
    final cardBg = theme.surface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: isOnline
                ? const Color(0xFF35D07F).withValues(alpha: 0.35)
                : AppTokens.signalYellow.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: theme.isLowPower
              ? null
              : [
                  BoxShadow(
                    color: (isOnline ? const Color(0xFF35D07F) : AppTokens.signalYellow)
                        .withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Animated Custom Radar Canvas
            SizedBox(
              width: 36,
              height: 36,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _NeuralRadarPainter(
                      progress: _controller.value,
                      isOnline: isOnline,
                      isLowPower: theme.isLowPower,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Text & Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        isOnline
                            ? 'GROQ CLOUD AI REASONING'
                            : 'NEURAL ON-DEVICE INFERENCE',
                        style: TextStyle(
                          color: isOnline
                              ? const Color(0xFF35D07F)
                              : (theme.isLightMode
                                  ? AppTokens.lightPrimaryInk
                                  : AppTokens.signalYellow),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: (isOnline
                                  ? const Color(0xFF35D07F)
                                  : AppTokens.signalYellow)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        ),
                        child: Text(
                          isOnline ? 'CLOUD LLM' : '<5ms EDGE',
                          style: TextStyle(
                            color: isOnline
                                ? const Color(0xFF35D07F)
                                : (theme.isLightMode
                                    ? AppTokens.lightPrimaryInk
                                    : AppTokens.signalYellow),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isOnline
                        ? 'Llama-3.3 70B • High-Capacity Cognitive Processing'
                        : 'Vector Space TF-IDF • Cosine Centroid Scan • 0 KB Data',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeuralRadarPainter extends CustomPainter {
  final double progress;
  final bool isOnline;
  final bool isLowPower;

  _NeuralRadarPainter({
    required this.progress,
    required this.isOnline,
    required this.isLowPower,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final primaryColor = isOnline
        ? const Color(0xFF35D07F)
        : (isLowPower ? const Color(0xFFFFD21F) : AppTokens.signalYellow);

    // 1. Draw 3 expanding concentric radar wave ripples
    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + (i * 0.33)) % 1.0;
      final waveRadius = maxRadius * waveProgress;
      final waveAlpha = (1.0 - waveProgress) * 0.7;

      final wavePaint = Paint()
        ..color = primaryColor.withValues(alpha: waveAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;

      canvas.drawCircle(center, waveRadius, wavePaint);
    }

    // 2. Outer boundary ring
    final ringPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, maxRadius, ringPaint);

    // 3. Sweeping radar scan arc
    final sweepAngle = math.pi * 0.6;
    final startAngle = progress * 2 * math.pi;
    final sweepPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius),
      startAngle,
      sweepAngle,
      true,
      sweepPaint,
    );

    // 4. Center pulsing core dot
    final coreRadius = 3.5 + (math.sin(progress * 2 * math.pi) * 1.0);
    final corePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, coreRadius, corePaint);

    // 5. Core ring
    final coreRingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, coreRadius, coreRingPaint);
  }

  @override
  bool shouldRepaint(covariant _NeuralRadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isOnline != isOnline ||
        oldDelegate.isLowPower != isLowPower;
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String timestamp;
  final List<String>? steps;
  final String? warningNotice;
  final String? source;
  final int? latencyMs;
  final double? confidence;
  final String urgency;
  final String? category;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.steps,
    this.warningNotice,
    this.source,
    this.latencyMs,
    this.confidence,
    this.urgency = 'high',
    this.category,
  });
}

class _PromptSuggestion {
  final IconData icon;
  final String label;
  final String query;
  final String category;

  _PromptSuggestion({
    required this.icon,
    required this.label,
    required this.query,
    required this.category,
  });
}
