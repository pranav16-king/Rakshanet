import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

/// Screen 7: AI Assistant (Offline)
/// Matches Mockup Screen 7:
/// - Header: "AI Assistant", subtitle "Offline on your device"
/// - Pre-populated & interactive chat stream showing offline disaster Q&A:
///   - User: "How can I purify water without a filter?"
///   - AI Response card: step-by-step instructions (Boiling, settling, solar disinfection)
///     + Warning badge: "This removes most harmful germs and makes the water safer to drink."
/// - Quick prompt suggestion pills: "Food storage tips", "First aid for cuts",
///   "What to do in flood?", "Show nearby shelters"
/// - Bottom input bar: "Ask anything..." + yellow circular send button
/// - Embedded offline emergency reasoning engine with instant step-by-step responses
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Chat message stream
  final List<_ChatMessage> _messages = [
    // Prepopulated mockup message 1 (User)
    _ChatMessage(
      text: 'How can I purify water without a filter?',
      isUser: true,
      timestamp: '10:41 AM',
    ),
    // Prepopulated mockup message 2 (AI Card)
    _ChatMessage(
      text: 'You can purify water using boiling. Here are the steps:',
      isUser: false,
      timestamp: '10:41 AM',
      steps: [
        'Collect clear water if possible.',
        'Boil it for at least 1 minute (3 minutes at high altitude).',
        'Let it cool naturally.',
        'Store in a clean, covered container.',
      ],
      warningNotice:
          'This removes most harmful germs and makes the water safer to drink.',
    ),
  ];

  // Quick prompt suggestions from mockup
  final List<_PromptSuggestion> _suggestions = [
    _PromptSuggestion(
      icon: Icons.lightbulb_outline_rounded,
      label: 'Food storage tips',
      query: 'How to store perishable food during an extended power outage?',
    ),
    _PromptSuggestion(
      icon: Icons.healing_rounded,
      label: 'First aid for cuts',
      query: 'What is the immediate first aid treatment for deep cuts and bleeding?',
    ),
    _PromptSuggestion(
      icon: Icons.waves_rounded,
      label: 'What to do in flood?',
      query: 'What should I do immediately during sudden flash flooding?',
    ),
    _PromptSuggestion(
      icon: Icons.night_shelter_outlined,
      label: 'Show nearby shelters',
      query: 'Where are the closest emergency relief shelters and community centers?',
    ),
    _PromptSuggestion(
      icon: Icons.local_fire_department_outlined,
      label: 'Make signal fire',
      query: 'How can I safely signal rescue helicopters or search drones?',
    ),
    _PromptSuggestion(
      icon: Icons.ac_unit_rounded,
      label: 'Hypothermia safety',
      query: 'How to treat someone showing signs of hypothermia and shivering?',
    ),
  ];

  bool _isTyping = false;

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

  void _sendMessage(String query) {
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

    // Generate offline AI response
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final response = _resolveOfflineAiResponse(trimmed);
      setState(() {
        _messages.add(response);
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  _ChatMessage _resolveOfflineAiResponse(String input) {
    final lower = input.toLowerCase();
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} ${now.period == DayPeriod.am ? 'AM' : 'PM'}';

    if (lower.contains('food') || lower.contains('storage') || lower.contains('fridge')) {
      return _ChatMessage(
        text: 'Food safety during power outage guidelines:',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'Keep refrigerator and freezer doors tightly closed. An unopened fridge keeps food cold for 4 hours; a full freezer for 48 hours.',
          'Consume perishable items (milk, meat, cooked leftovers) first.',
          'Eat dry rations, canned beans, peanut butter, and biscuits once cold storage warms above 4°C (40°F).',
          'Never taste food to determine if it is spoiled; discard food with unusual odor or mold.',
        ],
        warningNotice:
          'When in doubt, throw it out. Food poisoning in a disaster worsens dehydration.',
      );
    } else if (lower.contains('cut') || lower.contains('bleed') || lower.contains('first aid')) {
      return _ChatMessage(
        text: 'Immediate first aid protocol for severe cuts & bleeding:',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'Apply direct, firm pressure on the wound using a clean cloth, gauze, or sterile pad.',
          'Maintain pressure continuously for at least 5 minutes without peeking.',
          'Elevate the injured limb above heart level if no fracture is suspected.',
          'Wrap securely with a bandage. If blood soaks through, add another layer—do not remove the first pad.',
        ],
        warningNotice:
          'Seek emergency medical help or trigger SOS if bleeding does not stop after 10 minutes of direct pressure.',
      );
    } else if (lower.contains('flood') || lower.contains('water level') || lower.contains('drown')) {
      return _ChatMessage(
        text: 'Immediate survival protocol for flood waters:',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'Move immediately to higher ground or upper floor. Avoid closed attics where you could get trapped; stay near roof access.',
          'Turn off electricity main breaker and gas cylinder valve before water reaches sockets.',
          'Never walk or drive through moving water. Just 15 cm (6 in) of moving water can knock you down.',
          'Signal your location with a whistle, bright cloth, or flashlight.',
        ],
        warningNotice:
          'Floodwater carries dangerous contaminants, hidden debris, and electric shock hazards.',
      );
    } else if (lower.contains('shelter') || lower.contains('camp') || lower.contains('relief')) {
      return _ChatMessage(
        text: 'Nearby verified shelters recorded in offline mesh:',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'Village School: 1.2 km North (Capacity: 120 people, Food & Medical available).',
          'Community Center: 2.6 km East (Capacity: 200 people, Charging & Water active).',
          'Primary Health Center: 3.1 km North-West (Medical support & Triage).',
          'Relief Camp: 4.5 km South-East (Capacity: 500 people, Emergency beds).',
        ],
        warningNotice:
          'Check the "Shelters" tab for real-time mesh occupancy and offline compass bearings.',
      );
    } else if (lower.contains('signal') || lower.contains('fire') || lower.contains('helicopter') || lower.contains('drone')) {
      return _ChatMessage(
        text: 'Visual emergency signaling methods:',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'Form the international distress triangle: 3 small fires or 3 bright objects in an equilateral triangle.',
          'Use green pine or damp leaves to generate thick white smoke during the day; dry wood for bright flame at night.',
          'Sound SOS with a whistle: 3 short blasts, 3 long blasts, 3 short blasts (... --- ...).',
          'Lay out bright clothing in an "X" or "V" shape on rooftops or clearings.',
        ],
        warningNotice:
          'Ensure signal fires are safely contained from surrounding brush or structures.',
      );
    } else if (lower.contains('hypotherm') || lower.contains('cold') || lower.contains('shiver')) {
      return _ChatMessage(
        text: 'Emergency response for hypothermia:',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'Move person into shelter out of wind and rain immediately.',
          'Gently remove wet clothing and replace with dry layers, blankets, or sleeping bags.',
          'Warm the core body first (chest, neck, groin) with warm dry compresses or body heat.',
          'Provide warm, sweet, non-caffeinated fluids if person is conscious and able to swallow.',
        ],
        warningNotice:
          'Do NOT rub or massage limbs briskly, and do NOT apply direct extreme heat or hot water.',
      );
    } else if (lower.contains('earthquake') || lower.contains('quake') || lower.contains('shake')) {
      return _ChatMessage(
        text: 'Earthquake survival actions:',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'DROP to your hands and knees.',
          'COVER your head and neck under a sturdy table or desk.',
          'HOLD ON until shaking completely stops.',
          'If outdoors, move into an open area away from power lines, chimneys, and facades.',
        ],
        warningNotice:
          'Expect aftershocks. Avoid doorways—modern doors are no stronger than other parts of a room.',
      );
    } else {
      return _ChatMessage(
        text: 'Emergency guidance from RakshaNet Offline Engine:',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'Stay calm and evaluate immediate safety hazards (fire, water, falling debris).',
          'Keep your device in Low Power Mode and rely on the Bluetooth Mesh relay.',
          'Stay with your group and monitor the Emergency Status timeline.',
          'If in critical danger, hold the main SOS button for 1.5 seconds to broadcast your coordinates.',
        ],
        warningNotice:
          'This guidance is compiled from verified offline disaster response protocols.',
      );
    }
  }

  void _showOfflineEngineInfo() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTokens.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: const BorderSide(color: AppTokens.darkBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: AppTokens.signalYellow, size: 24),
            SizedBox(width: 8),
            Text(
              'Offline Edge AI Engine',
              style: TextStyle(
                color: AppTokens.darkText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RakshaNet AI Assistant is completely self-contained on your mobile device.',
              style: TextStyle(color: AppTokens.darkText, fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              '• 0 KB Cellular data required\n• Instant response without cell towers\n• Pre-indexed offline disaster first aid protocols\n• Verified NDMA & Red Cross emergency knowledge base',
              style: TextStyle(
                color: AppTokens.darkTextMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood',
                style: TextStyle(color: AppTokens.signalYellow, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.nightNavy,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Bar (Matches Mockup Screen 7)
            _buildHeaderBar(),

            // 2. Chat Stream Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  final msg = _messages[index];
                  return msg.isUser
                      ? _buildUserMessage(msg)
                      : _buildAiResponseCard(msg);
                },
              ),
            ),

            // 3. Quick Prompt Suggestion Pills
            _buildPromptSuggestions(),

            // 4. Bottom Input Bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTokens.darkBg,
        border: Border(
          bottom: BorderSide(
            color: AppTokens.darkBorder.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Yellow Beacon Circle with AI icon
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppTokens.signalYellow,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome,
                color: AppTokens.lightOnPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title & Subtitle
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: AppTokens.darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 13, color: AppTokens.beaconTeal),
                    SizedBox(width: 4),
                    Text(
                      'Offline on your device',
                      style: TextStyle(
                        color: AppTokens.darkTextMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Offline engine information action
          IconButton(
            icon: const Icon(Icons.info_outline_rounded,
                color: AppTokens.darkTextMuted),
            tooltip: 'Offline Engine Status',
            onPressed: _showOfflineEngineInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  msg.text,
                  style: const TextStyle(
                    color: Color(0xFF16202D),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  msg.timestamp,
                  style: TextStyle(
                    color: const Color(0xFF16202D).withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiResponseCard(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Intro text
                  Text(
                    msg.text,
                    style: const TextStyle(
                      color: Color(0xFF16202D),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  if (msg.steps != null && msg.steps!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    // Step by step list
                    ...msg.steps!.asMap().entries.map((entry) {
                      final stepNum = entry.key + 1;
                      final stepText = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$stepNum. ',
                              style: const TextStyle(
                                color: Color(0xFF16202D),
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                stepText,
                                style: const TextStyle(
                                  color: Color(0xFF263238),
                                  fontSize: 14.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // Warning / Safety Callout Box (Matches Mockup 7)
                  if (msg.warningNotice != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E6),
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        border: Border.all(
                          color: const Color(0xFFFFD591),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFA8C16),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              msg.warningNotice!,
                              style: const TextStyle(
                                color: Color(0xFF873800),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 13,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Offline AI Model',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        msg.timestamp,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
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

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTokens.darkSurface,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: AppTokens.darkBorder),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTokens.signalYellow),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'AI reasoning offline...',
                  style: TextStyle(
                    color: AppTokens.darkTextMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptSuggestions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTokens.darkSurface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      border: Border.all(
                        color: AppTokens.darkBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.icon,
                            size: 15, color: AppTokens.signalYellow),
                        const SizedBox(width: 6),
                        Text(
                          s.label,
                          style: const TextStyle(
                            color: AppTokens.darkText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
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

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppTokens.darkBg,
        border: Border(
          top: BorderSide(
            color: AppTokens.darkBorder.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Input field container
          Expanded(
            child: Container(
              height: AppTokens.inputHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTokens.darkSurfaceSunken,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(color: AppTokens.darkBorder),
              ),
              child: Center(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    color: AppTokens.darkText,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Ask anything...',
                    hintStyle: TextStyle(
                      color: AppTokens.darkTextMuted,
                      fontSize: 15,
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
          const SizedBox(width: 10),
          // Yellow circular send button (Mockup 7)
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
                    color: AppTokens.lightOnPrimary,
                    size: 22,
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

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.steps,
    this.warningNotice,
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
