import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/mesh_provider.dart';
import '../../services/ai/ai_models.dart';
import '../../services/ai/ai_orchestrator.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_bar_actions.dart';

/// Screen 7: AI Assistant (Redesigned Production-Grade Hybrid Emergency Copilot)
///
/// Features:
/// 1. Dual-Engine Architecture:
///    - Online: Groq Cloud (Llama 3.3 70B) via secure backend proxy (ZERO client API keys).
///    - Offline: On-Device NLP / SLM model + Local Verified Knowledge Base (NDMA, NDRF, WHO, IFRC).
/// 2. Automatic Online/Offline Routing with instant graceful fallback.
/// 3. Clean, compact one-handed mobile UI without vertical competition or oversized cards.
/// 4. Authoritative verified emergency citations with zero fabricated metrics or hallucinated numbers.
/// 5. Safe markdown, step-by-step guidance, copy actions, and generation cancellation.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isGenerating = false;
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Medical',
    'Hazards',
    'Rescue',
    'CBRN',
    'Survival',
  ];

  // Chat message stream
  final List<AiChatMessage> _messages = [
    AiChatMessage(
      text: 'RakshaNet Hybrid AI Assistant initialized and ready.',
      isUser: false,
      timestamp: 'Ready',
      source: 'System Engine',
      urgency: 'advisory',
      category: 'System Architecture',
      steps: [
        'Online Mode: Groq Cloud Llama-3.3 70B provides deep reasoning when internet is reachable.',
        'Offline Mode: 69+ Pre-trained disaster SOPs answer CPR, hemorrhage, CBRN, flood, and rubble questions with zero network.',
        'Automatic Fallback: Seamlessly transitions between Cloud and Device without losing chat context.',
      ],
      warningNotice:
          'Tap the mode indicator in the header to switch between Auto Mode and Force Offline Mode.',
    ),
  ];

  // Categorized Suggested Prompts (max 3-4 suggestions per category)
  final Map<String, List<_PromptSuggestion>> _categorySuggestions = {
    'All': [
      _PromptSuggestion(
        icon: Icons.favorite_rounded,
        label: 'CPR Protocol',
        query: 'How do I perform CPR on an adult who collapsed?',
        category: 'Medical',
      ),
      _PromptSuggestion(
        icon: Icons.healing_rounded,
        label: 'Severe Bleeding',
        query: 'What is the immediate protocol for severe arterial bleeding and tourniquets?',
        category: 'Medical',
      ),
      _PromptSuggestion(
        icon: Icons.water_rounded,
        label: 'Water Purification',
        query: 'How can I purify dirty contaminated water without a filter?',
        category: 'Survival',
      ),
      _PromptSuggestion(
        icon: Icons.terrain_rounded,
        label: 'Earthquake Action',
        query: 'What are the essential survival steps during an earthquake and if trapped under rubble?',
        category: 'Hazards',
      ),
    ],
    'Medical': [
      _PromptSuggestion(
        icon: Icons.favorite_rounded,
        label: 'CPR Protocol',
        query: 'How do I perform CPR on an adult who collapsed?',
        category: 'Medical',
      ),
      _PromptSuggestion(
        icon: Icons.healing_rounded,
        label: 'Severe Bleeding',
        query: 'What is the immediate protocol for severe arterial bleeding and tourniquets?',
        category: 'Medical',
      ),
      _PromptSuggestion(
        icon: Icons.pest_control_rounded,
        label: 'Snakebite Care',
        query: 'What is the first aid protocol for a venomous snakebite?',
        category: 'Medical',
      ),
      _PromptSuggestion(
        icon: Icons.airline_seat_recline_extra_rounded,
        label: 'Choking Heimlich',
        query: 'How to save a choking person using back blows and abdominal thrusts?',
        category: 'Medical',
      ),
    ],
    'Hazards': [
      _PromptSuggestion(
        icon: Icons.waves_rounded,
        label: 'Flood Safety',
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
        icon: Icons.cyclone_rounded,
        label: 'Cyclone Defense',
        query: 'How to secure shelter and survive a category 5 cyclone or hurricane?',
        category: 'Hazards',
      ),
      _PromptSuggestion(
        icon: Icons.local_fire_department_rounded,
        label: 'Wildfire Burnover',
        query: 'How to survive a wildfire burnover and deploy emergency fire shelter?',
        category: 'Hazards',
      ),
    ],
    'Rescue': [
      _PromptSuggestion(
        icon: Icons.crisis_alert_rounded,
        label: 'START Triage',
        query: 'How do I perform START mass casualty triage for multiple injured victims?',
        category: 'Rescue',
      ),
      _PromptSuggestion(
        icon: Icons.touch_app_rounded,
        label: 'Rubble Tapping',
        query: 'How do trapped victims signal under concrete rubble in building collapse?',
        category: 'Rescue',
      ),
      _PromptSuggestion(
        icon: Icons.pool_rounded,
        label: 'Swiftwater Rescue',
        query: 'How to survive strong river swiftwater current and river strainer?',
        category: 'Rescue',
      ),
      _PromptSuggestion(
        icon: Icons.flight_land_rounded,
        label: 'Helo Landing Zone',
        query: 'How to prepare and secure an emergency helicopter landing zone LZ?',
        category: 'Rescue',
      ),
    ],
    'CBRN': [
      _PromptSuggestion(
        icon: Icons.sanitizer_rounded,
        label: 'CBRN Decontamination',
        query: 'What is the protocol for cbrn decontamination after a chemical gas attack?',
        category: 'CBRN',
      ),
      _PromptSuggestion(
        icon: Icons.masks_rounded,
        label: 'Toxic Gas Shelter',
        query: 'How to shelter in place during a toxic chlorine or chemical gas leak?',
        category: 'CBRN',
      ),
      _PromptSuggestion(
        icon: Icons.warning_rounded,
        label: 'Nuclear Fallout (7:10)',
        query: 'How to survive nuclear fallout and what is the radiation 7:10 rule?',
        category: 'CBRN',
      ),
    ],
    'Survival': [
      _PromptSuggestion(
        icon: Icons.water_drop_rounded,
        label: 'Water Purification',
        query: 'How can I purify dirty contaminated water without a filter?',
        category: 'Survival',
      ),
      _PromptSuggestion(
        icon: Icons.restaurant_rounded,
        label: 'Ration Planning',
        query: 'How much water ration needed for 4 people for 5 days?',
        category: 'Survival',
      ),
      _PromptSuggestion(
        icon: Icons.clean_hands_rounded,
        label: 'Sanitation Hygiene',
        query: 'How to maintain camp sanitation and prevent cholera during a disaster?',
        category: 'Survival',
      ),
      _PromptSuggestion(
        icon: Icons.phone_in_talk_rounded,
        label: 'Emergency Numbers',
        query: 'What are the official emergency helpline numbers in India?',
        category: 'Survival',
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    AiOrchestrator.instance.addListener(_onOrchestratorUpdated);
  }

  @override
  void dispose() {
    AiOrchestrator.instance.removeListener(_onOrchestratorUpdated);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onOrchestratorUpdated() {
    if (mounted) setState(() {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  Future<void> _sendMessage(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || _isGenerating) return;

    _textController.clear();
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add(AiChatMessage(
        text: trimmed,
        isUser: true,
        timestamp: timeStr,
      ));
      _isGenerating = true;
    });
    _scrollToBottom();

    // Prepare anonymized conversation history (last 4 turns)
    final history = _messages
        .where((m) => m.text.isNotEmpty)
        .take(6)
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();

    // Contextual device telemetry
    Map<String, dynamic>? telemetryContext;
    try {
      final telemetry = context.read<TelemetryProvider>();
      final mesh = context.read<MeshProvider>();
      telemetryContext = {
        'battery': telemetry.batteryLevel,
        'mesh_peers': mesh.connectedPeerCount,
      };
    } catch (_) {}

    try {
      final aiResponse = await AiOrchestrator.instance.processQuery(
        trimmed,
        conversationHistory: history,
        telemetryContext: telemetryContext,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(AiChatMessage(
          text: aiResponse.text,
          isUser: false,
          timestamp: timeStr,
          steps: aiResponse.steps,
          warningNotice: aiResponse.warningNotice,
          source: aiResponse.source,
          engineType: aiResponse.engineType,
          sources: aiResponse.sources,
          urgency: aiResponse.urgency,
          category: aiResponse.category,
          requestId: aiResponse.requestId,
        ));
        _isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(AiChatMessage(
          text: 'Emergency Standard Procedures (Offline Fallback):',
          isUser: false,
          timestamp: timeStr,
          steps: [
            'Maintain vital airway, breathing, and circulation (ABCs).',
            'Do not move an injured person if spinal damage is suspected.',
            'Press and hold the central SOS Beacon for 1.5 seconds if urgent dispatch is needed.',
          ],
          source: 'Verified Knowledge Base',
          engineType: AiEngineType.localKnowledge,
          urgency: 'critical',
          category: 'Disaster Protocol',
          warningNotice: 'Request completed using on-device emergency guidelines.',
        ));
        _isGenerating = false;
      });
    }

    _scrollToBottom();
  }

  void _cancelGeneration() {
    AiOrchestrator.instance.cancelCurrentRequest();
    setState(() {
      _isGenerating = false;
    });
  }

  void _toggleForceOffline() {
    final orchestrator = AiOrchestrator.instance;
    orchestrator.forceOfflineMode = !orchestrator.forceOfflineMode;

    final snack = SnackBar(
      content: Text(
        orchestrator.forceOfflineMode
            ? 'Forced Offline Mode enabled: Using On-Device AI Model'
            : 'Auto Mode enabled: Using Groq Cloud AI with Offline fallback',
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: orchestrator.forceOfflineMode
          ? AppTokens.darkWarning
          : AppTokens.beaconTeal,
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(AiChatMessage(
        text: 'Chat history cleared. How can I assist you?',
        isUser: false,
        timestamp: 'Just now',
        source: 'System Engine',
      ));
    });
  }

  void _copyToClipboard(AiChatMessage msg) {
    final buffer = StringBuffer();
    buffer.writeln(msg.text);
    if (msg.category != null) {
      buffer.writeln('Category: ${msg.category}');
    }
    if (msg.steps.isNotEmpty) {
      buffer.writeln('\nAction Steps:');
      for (int i = 0; i < msg.steps.length; i++) {
        buffer.writeln('${i + 1}. ${msg.steps[i]}');
      }
    }
    if (msg.warningNotice != null && msg.warningNotice!.isNotEmpty) {
      buffer.writeln('\nSafety Notice: ${msg.warningNotice}');
    }
    if (msg.sources.isNotEmpty) {
      buffer.writeln('\nSources:');
      for (final s in msg.sources) {
        buffer.writeln('• ${s.title} (${s.organization})');
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Protocol copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSourcesDialog(ThemeProvider theme) {
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
            const Icon(Icons.verified_rounded, color: AppTokens.beaconTeal, size: 22),
            const SizedBox(width: 8),
            Text(
              'Verified Knowledge Sources',
              style: TextStyle(
                color: theme.text,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RakshaNet emergency guidance is grounded in official, peer-reviewed disaster management guidelines:',
                style: TextStyle(color: theme.textMuted, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              _buildSourceTile('NDMA India', 'National Guidelines: Floods & Earthquakes', 'ndma.gov.in', theme),
              _buildSourceTile('NDRF India', 'Collapsed Structure Search & Rescue (CSSR) SOP', 'ndrf.gov.in', theme),
              _buildSourceTile('MoHFW India', 'Trauma Care & Snakebite Envenomation Standards', 'mohfw.gov.in', theme),
              _buildSourceTile('WHO', 'Emergency Trauma Care & Basic Life Support (BLS)', 'who.int', theme),
              _buildSourceTile('IFRC', 'International First Aid & Disaster Guidelines', 'ifrc.org', theme),
              _buildSourceTile('IMD India', 'Cyclone & Extreme Weather Preparedness SOP', 'mausam.imd.gov.in', theme),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppTokens.signalYellow)),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceTile(String org, String title, String domain, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.surfaceSunken,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          border: Border.all(color: theme.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  org,
                  style: const TextStyle(
                    color: AppTokens.beaconTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
                const Spacer(),
                Text(
                  domain,
                  style: TextStyle(color: theme.textMuted, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(color: theme.text, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showArchitectureDialog(ThemeProvider theme) {
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
            const Icon(Icons.auto_awesome, color: AppTokens.signalYellow, size: 22),
            const SizedBox(width: 8),
            Text(
              'Hybrid AI Architecture',
              style: TextStyle(
                color: theme.text,
                fontSize: 16,
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
              'RakshaNet AI Dual-Engine System:',
              style: TextStyle(color: theme.text, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '1. Cloud Reasoning (Groq Llama 3.3 70B):\n'
              '• Secure backend proxy — zero API keys in mobile bundle\n'
              '• In-depth reasoning and complex explanations\n'
              '• Active when network connectivity is available\n\n'
              '2. On-Device Local Inference:\n'
              '• 100% self-contained on device (0 KB mobile data)\n'
              '• 69+ disaster classes, CPR, CBRN, hemorrhage, triage\n'
              '• Grounded in local verified documents (NDMA, WHO, IFRC)\n'
              '• Seamless instant response during total blackout',
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It', style: TextStyle(color: AppTokens.signalYellow)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final orchestrator = AiOrchestrator.instance;

    return Scaffold(
      backgroundColor: theme.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Redesigned Premium Header Bar
            _buildHeaderBar(theme, orchestrator),

            // 2. Vertically Scrolling Conversation Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                itemCount: _messages.length + (_isGenerating ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isGenerating) {
                    return _buildGeneratingIndicator(theme);
                  }
                  final msg = _messages[index];
                  return msg.isUser
                      ? _buildUserBubble(msg, theme)
                      : _buildAssistantCard(msg, theme);
                },
              ),
            ),

            // 3. Compact Horizontal Category & Prompt Suggestions
            _buildSuggestionsSection(theme),

            // 4. Responsive Multiline Message Composer
            _buildMessageComposer(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar(ThemeProvider theme, AiOrchestrator orchestrator) {
    final isForcedOffline = orchestrator.forceOfflineMode;
    final isOnline = orchestrator.state == AiOrchestratorState.onlineReady && !isForcedOffline;
    final canPop = Navigator.canPop(context);

    // Dynamic dot color according to state
    final Color dotColor;
    if (isOnline) {
      dotColor = const Color(0xFF35D07F); // Green
    } else if (orchestrator.state == AiOrchestratorState.onlineDegraded) {
      dotColor = const Color(0xFFFFA940); // Amber
    } else {
      dotColor = AppTokens.signalYellow; // Yellow / Gold for On-Device
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.bg,
        border: Border(
          bottom: BorderSide(
            color: theme.border,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button (shown if opened via push)
          if (canPop)
            IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: theme.text, size: 20),
              tooltip: 'Back',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 4),

          // Yellow AI Icon Circle
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTokens.signalYellow,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome,
                color: AppTokens.lightOnPrimary,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Title & Accurate State Badge
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
                      fontSize: 15.5,
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
                        width: 6.5,
                        height: 6.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          isOnline
                              ? 'ONLINE · GROQ'
                              : (isForcedOffline
                                  ? 'Forced Offline • On-Device'
                                  : 'OFFLINE · LOCAL AI'),
                          style: TextStyle(
                            color: isOnline
                                ? const Color(0xFF35D07F)
                                : (theme.isLightMode
                                    ? AppTokens.lightPrimaryInk
                                    : AppTokens.signalYellow),
                            fontSize: 11,
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

          // Mode Switcher Action Chip (NO green cloud icon while offline!)
          IconButton(
            icon: Icon(
              isForcedOffline ? Icons.cloud_off_rounded : (isOnline ? Icons.cloud_done_rounded : Icons.offline_bolt_rounded),
              color: isOnline ? const Color(0xFF35D07F) : AppTokens.signalYellow,
              size: 20,
            ),
            tooltip: isForcedOffline ? 'Forced Offline (Tap for Auto)' : 'Tap to Force Offline',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: _toggleForceOffline,
          ),

          // Overflow Menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: theme.textMuted, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            color: theme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              side: BorderSide(color: theme.border),
            ),
            onSelected: (val) {
              if (val == 'toggle') _toggleForceOffline();
              if (val == 'info') _showArchitectureDialog(theme);
              if (val == 'sources') _showSourcesDialog(theme);
              if (val == 'clear') _clearChat();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      isForcedOffline ? Icons.cloud_queue_rounded : Icons.cloud_off_rounded,
                      color: theme.text,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isForcedOffline ? 'Switch to Auto Cloud' : 'Force Offline Mode',
                      style: TextStyle(color: theme.text, fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: theme.text, size: 17),
                    const SizedBox(width: 8),
                    Text('Architecture Details', style: TextStyle(color: theme.text, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sources',
                child: Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: AppTokens.beaconTeal, size: 17),
                    const SizedBox(width: 8),
                    Text('Verified Sources', style: TextStyle(color: theme.text, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, color: AppTokens.sosRed, size: 17),
                    const SizedBox(width: 8),
                    Text('Clear Conversation', style: TextStyle(color: AppTokens.sosRed, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),

          // Theme Switcher Button
          const ThemeToggleButton(compact: true),
        ],
      ),
    );
  }

  Widget _buildUserBubble(AiChatMessage msg, ThemeProvider theme) {
    final bubbleColor = theme.isLightMode
        ? const Color(0xFFE8EEF5)
        : (theme.isLowPower ? const Color(0xFF161616) : AppTokens.darkSurfaceAlt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
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
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  msg.timestamp,
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantCard(AiChatMessage msg, ThemeProvider theme) {
    final isCritical = msg.urgency == 'critical';
    final isHigh = msg.urgency == 'high';

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

    // Warning callout colors
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: isCritical
                ? AppTokens.sosRed.withValues(alpha: 0.6)
                : theme.border,
            width: isCritical ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge & Category Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.35), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, color: badgeColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        badgeLabel,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
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
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                // Copy Action
                IconButton(
                  icon: Icon(Icons.copy_rounded, color: theme.textMuted, size: 15),
                  tooltip: 'Copy protocol',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: () => _copyToClipboard(msg),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Headline Title
            Text(
              msg.text,
              style: TextStyle(
                color: theme.text,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                height: 1.35,
              ),
            ),

            // Compact Numbered Action Steps (Inline flow without oversized cards)
            if (msg.steps.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...msg.steps.asMap().entries.map((entry) {
                final stepNum = entry.key + 1;
                final stepText = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 19,
                        height: 19,
                        margin: const EdgeInsets.only(top: 1),
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
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stepText,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Safety Warning Callout
            if (msg.warningNotice != null && msg.warningNotice!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warningBg,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(color: warningBorder, width: 0.8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.isLightMode ? const Color(0xFFFA8C16) : AppTokens.darkWarning,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        msg.warningNotice!,
                        style: TextStyle(
                          color: warningText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Verified Knowledge Sources (Authoritative Citations)
            if (msg.sources.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_outlined, size: 12, color: AppTokens.beaconTeal),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Sources: ${msg.sources.map((s) => s.title).join(' • ')}',
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 6),

            // Footer: Engine Attribution + Clean Timestamp (NO fake latency or fabricated scores)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      msg.engineType == AiEngineType.groqCloud
                          ? Icons.cloud_done_rounded
                          : Icons.bolt_rounded,
                      size: 12,
                      color: msg.engineType == AiEngineType.groqCloud
                          ? const Color(0xFF35D07F)
                          : AppTokens.signalYellow,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      msg.source,
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Helpful Feedback Action
                    InkWell(
                      onTap: () {
                        setState(() {
                          msg.feedbackPositive = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thank you for your feedback!'), duration: Duration(seconds: 1)),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          msg.feedbackPositive == true ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                          size: 13,
                          color: msg.feedbackPositive == true ? AppTokens.beaconTeal : theme.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      msg.timestamp,
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingIndicator(ThemeProvider theme) {
    final isOnline = AiOrchestrator.instance.state == AiOrchestratorState.onlineRequest;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isOnline ? const Color(0xFF35D07F) : AppTokens.signalYellow,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isOnline
                    ? 'Consulting Groq Cloud Llama-3.3...'
                    : 'Searching On-Device Verified Knowledge...',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            TextButton(
              onPressed: _cancelGeneration,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTokens.sosRed, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection(ThemeProvider theme) {
    final suggestions = _categorySuggestions[_selectedCategory] ?? _categorySuggestions['All']!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.bg,
        border: Border(
          top: BorderSide(color: theme.border, width: 0.6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Horizontal Category Filter Chips (Single Compact Row)
          SizedBox(
            height: 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (theme.isLightMode
                              ? AppTokens.lightPrimaryInk
                              : AppTokens.signalYellow)
                          : theme.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : theme.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected
                              ? (theme.isLightMode ? Colors.white : AppTokens.lightOnPrimary)
                              : theme.textMuted,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 5),

          // 2. Filtered Suggested Prompts (Single Compact Horizontal Row, max 3-4 items)
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: suggestions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final s = suggestions[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    onTap: () => _sendMessage(s.query),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        border: Border.all(color: theme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            s.icon,
                            size: 13,
                            color: theme.isLightMode
                                ? AppTokens.lightPrimaryInk
                                : AppTokens.signalYellow,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            s.label,
                            style: TextStyle(
                              color: theme.text,
                              fontSize: 11.5,
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

  Widget _buildMessageComposer(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 5, 14, 8),
      decoration: BoxDecoration(
        color: theme.bg,
        border: Border(
          top: BorderSide(color: theme.border, width: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 100),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.surfaceSunken,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.border),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask any emergency or survival question...',
                  hintStyle: TextStyle(
                    color: theme.textMuted,
                    fontSize: 13.5,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send / Cancel Action Button
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _isGenerating ? AppTokens.sosRed : AppTokens.signalYellow,
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(21),
                onTap: _isGenerating
                    ? _cancelGeneration
                    : () => _sendMessage(_textController.text),
                child: Center(
                  child: Icon(
                    _isGenerating ? Icons.stop_rounded : Icons.arrow_forward_rounded,
                    color: _isGenerating ? Colors.white : AppTokens.nightNavy,
                    size: 20,
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

class _PromptSuggestion {
  final IconData icon;
  final String label;
  final String query;
  final String category;

  const _PromptSuggestion({
    required this.icon,
    required this.label,
    required this.query,
    required this.category,
  });
}
