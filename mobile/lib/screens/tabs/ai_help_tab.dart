import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_tokens.dart';

class AiHelpTab extends StatefulWidget {
  const AiHelpTab({super.key});

  @override
  State<AiHelpTab> createState() => _AiHelpTabState();
}

class _AiHelpTabState extends State<AiHelpTab> {
  final TextEditingController _promptController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'user',
      'text': 'How can I purify water without a filter?',
    },
    {
      'role': 'assistant',
      'text': 'You can purify water using boiling. Here are the steps:\n\n'
          '1. Collect clear water if possible.\n'
          '2. Boil it for at least 1 minute (3 minutes at high altitude).\n'
          '3. Let it cool naturally.\n'
          '4. Store in a clean, covered container.\n\n'
          '⚠️ Note: This removes harmful pathogens and makes water safe to drink.',
    },
  ];

  final List<String> _suggestions = [
    'Food storage tips',
    'First aid for cuts',
    'What to do in flood?',
    'Show nearby shelters',
  ];

  void _submitPrompt(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': query.trim()});
      _messages.add({
        'role': 'assistant',
        'text': 'Emergency guidance for "$query":\n\n'
            '• Maintain calm and conserve phone battery.\n'
            '• If injured, elevate the wound and apply firm pressure.\n'
            '• Signal your position with 3 audio or light pulses.\n'
            '• Mesh network will relay your status to local rescuers.',
      });
    });
    _promptController.clear();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
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
        // Offline SLM Badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.surfaceSunken,
          child: Row(
            children: [
              const Icon(Icons.bolt, color: AppTokens.signalYellow, size: 18),
              const SizedBox(width: 8),
              Text(
                'On-Device Offline SLM • Zero Data Required',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Conversation List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg['role'] == 'user';

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  mainAxisAlignment:
                      isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppTokens.signalYellow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.smart_toy,
                          color: AppTokens.lightOnPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFF1E2D4A) : cardBg,
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                          border: Border.all(
                            color: isUser
                                ? const Color(0xFF3B82F6)
                                : borderColor,
                          ),
                        ),
                        child: Text(
                          msg['text']!,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Suggestion Chips
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _suggestions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final chipText = _suggestions[index];
              return ActionChip(
                label: Text(chipText),
                backgroundColor: theme.surface,
                labelStyle: TextStyle(color: textColor, fontSize: 12),
                side: BorderSide(color: borderColor),
                onPressed: () => _submitPrompt(chipText),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Input Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          hintText: 'Ask emergency AI...',
                          hintStyle: TextStyle(color: textMuted, fontSize: 14),
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
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppTokens.signalYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: AppTokens.lightOnPrimary,
                      size: 24,
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
}
