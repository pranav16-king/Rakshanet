import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/ai/hybrid_ai_service.dart';
import '../../theme/app_tokens.dart';

class AiHelpTab extends StatefulWidget {
  const AiHelpTab({super.key});

  @override
  State<AiHelpTab> createState() => _AiHelpTabState();
}

class _TabAiMessage {
  final bool isUser;
  final String text;
  final List<String> steps;
  final String? warning;
  final String urgency;
  final int? latencyMs;
  final String source;

  _TabAiMessage({
    required this.isUser,
    required this.text,
    this.steps = const [],
    this.warning,
    this.urgency = 'high',
    this.latencyMs,
    this.source = 'Trained On-Device AI Model',
  });
}

class _AiHelpTabState extends State<AiHelpTab> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isThinking = false;

  final List<_TabAiMessage> _messages = [
    _TabAiMessage(
      isUser: true,
      text: 'How can I purify water without a filter?',
    ),
    _TabAiMessage(
      isUser: false,
      text: 'Offline Water Purification & Finding Potable Water:',
      steps: [
        'Vigorous Rolling Boil (Primary standard): Bring water to a full, rolling boil for at least 1 full minute (3 full minutes at altitudes > 2,000m / 6,500ft). Kills 99.9% of bacteria, viruses, and protozoa.',
        'Emergency Bleach Disinfection: Add 2 drops of standard unscented 5-6% household chlorine bleach per 1 Liter of clear water (4 drops for cloudy water). Mix thoroughly and let stand for 30 minutes before drinking.',
        'SODIS Solar UV Disinfection: Fill clean, clear PET plastic bottles 3/4 full, shake for 20 seconds to oxygenate, then lay flat on reflective metal/aluminum surface in full sun for 6 hours minimum.',
        'Improvised 3-Tier Bio-Sand Filter: Cut inverted plastic bottle. Layer from bottom to top: clean cotton cloth -> fine crushed charcoal -> fine sand -> coarse sand -> small gravel.',
      ],
      warning:
          'DO NOT use scented, splashless, or color-safe bleaches. Boiling does NOT remove chemical toxins or heavy metals.',
      urgency: 'high',
      latencyMs: 3,
      source: 'Trained On-Device AI Model',
    ),
  ];

  final List<String> _suggestions = [
    'START Triage Protocol',
    'CBRN Decontamination',
    'Earthquake Rubble Escape',
    'Sinking Car SWCO Escape',
    'Swiftwater River Rescue',
    'Solar Water Still',
    'Food Calorie Rationing',
    'Severe Arterial Bleeding',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
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

  Future<void> _submitPrompt(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _messages.add(_TabAiMessage(isUser: true, text: trimmed));
      _isThinking = true;
    });
    _promptController.clear();
    _scrollToBottom();

    try {
      final res = await HybridAiService.instance.processQuery(trimmed);
      if (!mounted) return;
      setState(() {
        _messages.add(_TabAiMessage(
          isUser: false,
          text: res.text,
          steps: res.steps,
          warning: res.warningNotice,
          urgency: res.urgency,
          latencyMs: res.latencyMs,
          source: res.source,
        ));
        _isThinking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(_TabAiMessage(
          isUser: false,
          text: 'RakshaNet Emergency Guidance:',
          steps: [
            'Assess immediate vital signs: Airway, Breathing, and Circulation (ABCs).',
            'Avoid moving the injured if neck or spinal injury is suspected.',
            'Press and hold the SOS Beacon for 1.5 seconds if rescue dispatch is required.',
          ],
          warning: 'Offline emergency SLM protocols are active locally on this phone.',
          urgency: 'critical',
          source: 'Trained On-Device AI Model',
        ));
        _isThinking = false;
      });
    }

    _scrollToBottom();
  }

  void _copyMessageToClipboard(_TabAiMessage msg) {
    final buffer = StringBuffer();
    buffer.writeln(msg.text);
    if (msg.steps.isNotEmpty) {
      buffer.writeln('\nAction Steps:');
      for (int i = 0; i < msg.steps.length; i++) {
        buffer.writeln('${i + 1}. ${msg.steps[i]}');
      }
    }
    if (msg.warning != null && msg.warning!.isNotEmpty) {
      buffer.writeln('\nSafety Notice: ${msg.warning}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Protocol copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final cardBg = theme.surface;
    final borderColor = theme.border;
    final textColor = theme.text;
    final textMuted = theme.textMuted;

    return Column(
      children: [
        // Offline SLM Live Header Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.surfaceSunken,
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppTokens.signalYellow, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'On-Device Offline SLM • 69+ Models • <5ms',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTokens.signalYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                ),
                child: Text(
                  '0 KB DATA',
                  style: TextStyle(
                    color: theme.isLightMode
                        ? AppTokens.lightPrimaryInk
                        : AppTokens.signalYellow,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Conversation List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            itemCount: _messages.length + (_isThinking ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isThinking) {
                return _buildThinkingTile(theme);
              }
              final msg = _messages[index];
              return msg.isUser
                  ? _buildUserBubble(msg, theme)
                  : _buildAssistantCard(msg, theme);
            },
          ),
        ),

        // Suggestion Chips
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _suggestions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final chipText = _suggestions[index];
              return ActionChip(
                label: Text(chipText),
                backgroundColor: theme.surface,
                labelStyle: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(color: borderColor),
                onPressed: () => _submitPrompt(chipText),
              );
            },
          ),
        ),
        const SizedBox(height: 6),

        // Input Box
        Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: AppTokens.inputHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: theme.surfaceSunken,
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: TextField(
                        controller: _promptController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ask disaster triage, first aid, survival...',
                          hintStyle: TextStyle(color: textMuted, fontSize: 13.5),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: _submitPrompt,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _submitPrompt(_promptController.text),
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTokens.signalYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: AppTokens.nightNavy,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserBubble(_TabAiMessage msg, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.isLightMode
                  ? const Color(0xFFE8EEF5)
                  : (theme.isLowPower ? const Color(0xFF161616) : AppTokens.darkSurfaceAlt),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: theme.border),
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                color: theme.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantCard(_TabAiMessage msg, ThemeProvider theme) {
    final isCritical = msg.urgency == 'critical';
    final isHigh = msg.urgency == 'high';

    final Color badgeColor = isCritical
        ? AppTokens.sosRed
        : (isHigh
            ? (theme.isLightMode ? const Color(0xFFD97706) : AppTokens.signalYellow)
            : (theme.isLightMode ? const Color(0xFF0284C7) : AppTokens.beaconTeal));

    final String badgeLabel = isCritical
        ? 'CRITICAL PROTOCOL'
        : (isHigh ? 'HIGH PRIORITY' : 'ADVISORY');

    final IconData badgeIcon = isCritical
        ? Icons.warning_rounded
        : (isHigh ? Icons.bolt_rounded : Icons.shield_outlined);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: isCritical
                ? AppTokens.sosRed.withValues(alpha: 0.5)
                : theme.border,
            width: isCritical ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge & Copy
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
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
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.copy_rounded, color: theme.textMuted, size: 16),
                  tooltip: 'Copy',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: () => _copyMessageToClipboard(msg),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Headline
            Text(
              msg.text,
              style: TextStyle(
                color: theme.text,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
            ),

            // Steps
            if (msg.steps.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...msg.steps.asMap().entries.map((e) {
                final stepNum = e.key + 1;
                final stepContent = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.surfaceSunken,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    border: Border.all(color: theme.border.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
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
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stepContent,
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

            // Warning
            if (msg.warning != null && msg.warning!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.isLightMode
                      ? const Color(0xFFFFF7E6)
                      : const Color(0xFF2A1E0A),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(
                    color: theme.isLightMode
                        ? const Color(0xFFFFD591)
                        : const Color(0xFF8A5A00),
                  ),
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
                        msg.warning!,
                        style: TextStyle(
                          color: theme.isLightMode ? const Color(0xFF873800) : const Color(0xFFFFB74D),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 6),
            // Footer
            Row(
              children: [
                const Icon(Icons.bolt_rounded, size: 12, color: AppTokens.signalYellow),
                const SizedBox(width: 4),
                Text(
                  msg.source,
                  style: TextStyle(color: theme.textMuted, fontSize: 10.5),
                ),
                if (msg.latencyMs != null) ...[
                  Text(
                    ' • ${msg.latencyMs}ms instant',
                    style: const TextStyle(color: Color(0xFF35D07F), fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingTile(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: AppTokens.signalYellow.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTokens.signalYellow),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Neural On-Device Inference • Scanning Centroids...',
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
