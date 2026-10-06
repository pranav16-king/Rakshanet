import 'package:flutter/material.dart';
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

  // Chat message stream
  final List<_ChatMessage> _messages = [
    // Welcome message
    _ChatMessage(
      text: 'SignalRescue Hybrid AI Assistant initialized and ready.',
      isUser: false,
      timestamp: 'Just now',
      source: 'System Engine',
      steps: [
        'Online Mode: Groq Cloud Llama-3.3 70B answers any question with high reasoning capacity.',
        'Offline Mode: Pre-trained on-device NLP model answers CPR, bleeding, trauma, survival, and general knowledge questions with 0 KB data.',
        'Automatic Fallback: Seamlessly transitions between Cloud and Device without losing chat context.',
      ],
      warningNotice:
          'Tap the mode indicator in the header to switch between Auto Mode and Force Offline Mode.',
    ),
  ];

  // Quick prompt suggestions covering core emergency, survival & utility protocols
  final List<_PromptSuggestion> _suggestions = [
    _PromptSuggestion(
      icon: Icons.favorite_rounded,
      label: 'CPR Protocol',
      query: 'How to perform CPR on an unconscious adult who is not breathing?',
    ),
    _PromptSuggestion(
      icon: Icons.healing_rounded,
      label: 'Severe Bleeding',
      query: 'What is the immediate protocol for severe arterial bleeding and tourniquets?',
    ),
    _PromptSuggestion(
      icon: Icons.water_drop_rounded,
      label: 'Water Purification',
      query: 'How can I purify contaminated water without specialized equipment?',
    ),
    _PromptSuggestion(
      icon: Icons.waves_rounded,
      label: 'Flood Survival',
      query: 'What should I do immediately during sudden flash flooding and rising water?',
    ),
    _PromptSuggestion(
      icon: Icons.terrain_rounded,
      label: 'Earthquake Action',
      query: 'What are the essential survival steps during an earthquake and if trapped under rubble?',
    ),
    _PromptSuggestion(
      icon: Icons.local_fire_department_rounded,
      label: 'Burn Treatment',
      query: 'How to treat thermal burns and blisters immediately?',
    ),
    _PromptSuggestion(
      icon: Icons.ac_unit_rounded,
      label: 'Hypothermia Care',
      query: 'How to treat someone showing signs of hypothermia and severe shivering?',
    ),
    _PromptSuggestion(
      icon: Icons.pest_control_rounded,
      label: 'Snake Bite',
      query: 'What is the first aid protocol for a venomous snakebite?',
    ),
    _PromptSuggestion(
      icon: Icons.phone_in_talk_rounded,
      label: 'Emergency Numbers',
      query: 'What are the official national emergency helpline numbers in India?',
    ),
    _PromptSuggestion(
      icon: Icons.calculate_rounded,
      label: 'Water Ration Math',
      query: 'How much drinking water is needed for 4 people for 5 days in a disaster?',
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
        ));
        _isTyping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          text: 'SignalRescue Emergency Guidance:',
          isUser: false,
          timestamp: timeStr,
          steps: [
            'Assess immediate vital signs: Airway, Breathing, and Circulation (ABCs).',
            'Avoid moving the injured if neck or spinal injury is suspected.',
            'Press and hold the SOS Beacon for 1.5 seconds if rescue dispatch is required.',
          ],
          source: 'Trained On-Device AI Model',
          warningNotice: 'Emergency protocols are cached securely on this phone.',
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
              'SignalRescue AI operates a Dual-Engine intelligent pipeline:',
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

  Widget _buildAiResponseCard(_ChatMessage msg, ThemeProvider theme) {
    final cardBg = theme.surface;
    final warningBg = theme.isLightMode
        ? const Color(0xFFFFF7E6)
        : (theme.isLowPower ? const Color(0xFF161204) : const Color(0xFF2A1E0A));
    final warningBorder = theme.isLightMode
        ? const Color(0xFFFFD591)
        : (theme.isLowPower ? const Color(0xFF4A3408) : const Color(0xFF8A5A00));
    final warningText = theme.isLightMode
        ? const Color(0xFF873800)
        : (theme.isLowPower ? const Color(0xFFFFCC80) : const Color(0xFFFFB74D));

    final isGroqSource = msg.source?.contains('Groq') ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: theme.border),
                boxShadow: theme.isLowPower
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: theme.isLightMode ? 0.05 : 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title / Main text
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),

                  // Step-by-step list
                  if (msg.steps != null && msg.steps!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...msg.steps!.asMap().entries.map((entry) {
                      final stepNum = entry.key + 1;
                      final stepText = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$stepNum. ',
                              style: TextStyle(
                                color: theme.isLightMode ? AppTokens.lightPrimaryInk : AppTokens.signalYellow,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                height: 1.35,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                stepText,
                                style: TextStyle(
                                  color: theme.text,
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // Warning / Safety Notice
                  if (msg.warningNotice != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: warningBg,
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        border: Border.all(
                          color: warningBorder,
                          width: 1,
                        ),
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
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Footer: Source tag + Latency + Timestamp
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
                            msg.source ?? 'Offline AI Engine',
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (msg.latencyMs != null) ...[
                            Text(
                              ' • ${msg.latencyMs}ms',
                              style: TextStyle(
                                color: theme.textMuted,
                                fontSize: 10.5,
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
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTokens.signalYellow),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isOnline && !HybridAiService.instance.forceOfflineMode
                      ? 'Groq Cloud AI reasoning...'
                      : 'On-Device AI reasoning offline...',
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptSuggestions(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: _suggestions.map((s) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  onTap: () => _sendMessage(s.query),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      border: Border.all(
                        color: theme.border,
                        width: 1,
                      ),
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
                        const SizedBox(width: 5),
                        Text(
                          s.label,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
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

class _ChatMessage {
  final String text;
  final bool isUser;
  final String timestamp;
  final List<String>? steps;
  final String? warningNotice;
  final String? source;
  final int? latencyMs;
  final double? confidence;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.steps,
    this.warningNotice,
    this.source,
    this.latencyMs,
    this.confidence,
  });
}

class _PromptSuggestion {
  final IconData icon;
  final String label;
  final String query;

  _PromptSuggestion({
    required this.icon,
    required this.label,
    required this.query,
  });
}
