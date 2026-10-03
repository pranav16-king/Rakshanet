import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_bar_actions.dart';

/// Screen 7: AI Assistant (Offline)
/// Matches Mockup Screen 7:
/// - Header: "AI Assistant", subtitle "Offline on your device"
/// - 100% offline rule-based disaster triage decision tree:
///   CPR, bleeding, flood survival, earthquake, burns, hypothermia, water purification.
/// - Suggestion chips, step-by-step guidance cards with warning badges.
/// - Strict theme support: Light, Dark, Low-Power OLED.
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
        'Collect clear water if possible; let cloudy water settle and strain through cloth.',
        'Boil at a vigorous rolling boil for at least 1 minute (3 minutes at high altitude).',
        'Let it cool naturally without adding ice or contaminants.',
        'Store in a sanitized, covered container away from flood waters.',
      ],
      warningNotice:
          'This removes most harmful bacteria, parasites, and viruses, making water safer to drink.',
    ),
  ];

  // Quick prompt suggestions covering all core disaster triage protocols
  final List<_PromptSuggestion> _suggestions = [
    _PromptSuggestion(
      icon: Icons.favorite_rounded,
      label: 'CPR Protocol',
      query: 'How to perform CPR on an unconscious adult who is not breathing?',
    ),
    _PromptSuggestion(
      icon: Icons.healing_rounded,
      label: 'Severe Bleeding',
      query: 'What is the immediate first aid protocol for severe cuts and arterial bleeding?',
    ),
    _PromptSuggestion(
      icon: Icons.waves_rounded,
      label: 'Flood Survival',
      query: 'What should I do immediately during sudden flash flooding and rising water?',
    ),
    _PromptSuggestion(
      icon: Icons.terrain_rounded,
      label: 'Earthquake Action',
      query: 'What are the essential survival steps during and after an earthquake?',
    ),
    _PromptSuggestion(
      icon: Icons.local_fire_department_rounded,
      label: 'Burn Treatment',
      query: 'How to treat first and second degree thermal burns immediately?',
    ),
    _PromptSuggestion(
      icon: Icons.ac_unit_rounded,
      label: 'Hypothermia Care',
      query: 'How to treat someone showing signs of hypothermia and severe shivering?',
    ),
    _PromptSuggestion(
      icon: Icons.water_drop_rounded,
      label: 'Water Purification',
      query: 'How can I purify contaminated water without specialized equipment?',
    ),
    _PromptSuggestion(
      icon: Icons.night_shelter_outlined,
      label: 'Nearby Shelters',
      query: 'Where are the closest emergency relief shelters and community centers?',
    ),
    _PromptSuggestion(
      icon: Icons.lightbulb_outline_rounded,
      label: 'Food Storage',
      query: 'How to store perishable food during an extended power outage?',
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

    // 1. CPR & Resuscitation Triage Protocol
    if (lower.contains('cpr') || lower.contains('cardiac') || lower.contains('resuscit') ||
        lower.contains('not breathing') || lower.contains('unconscious') || lower.contains('heart attack')) {
      return _ChatMessage(
        text: 'Emergency CPR & Resuscitation Protocol (AHA / NDMA Guidelines):',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'Check responsiveness & breathing: Tap shoulders firmly and shout loudly. Check chest for normal rise/fall for no more than 10 seconds.',
          'Position hands in center of chest: Place heel of one hand in center of breastbone; interlock other hand on top. Lock elbows straight above chest.',
          'Deliver 30 hard, fast compressions: Push down at least 5–6 cm (2 inches) at 100–120 compressions/minute (to the beat of "Stayin\' Alive"). Allow full chest recoil.',
          'Deliver 2 gentle rescue breaths: Tilt head back, lift chin, pinch nostrils shut. Blow gently for 1 second until chest rises. (If untrained, perform continuous hands-only CPR).',
          'Repeat 30:2 cycles without stopping until victim moves, breathing resumes, or emergency rescue arrives.',
        ],
        warningNotice:
          'CRITICAL: Minimize interruptions in compressions. Switch compressors every 2 minutes if another person is present to prevent fatigue.',
      );
    }

    // 2. Severe Bleeding & Hemorrhage Triage Protocol
    if (lower.contains('bleed') || lower.contains('cut') || lower.contains('wound') ||
        lower.contains('hemorrhag') || lower.contains('arterial')) {
      return _ChatMessage(
        text: 'Emergency Hemorrhage Control & Bleeding Triage:',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'Direct firm pressure: Place a sterile pad or cleanest available cloth directly over wound and press firmly with both hands.',
          'Maintain pressure continuously: Keep uninterrupted pressure for at least 5–10 minutes without lifting pad to check.',
          'Elevate injured limb: Raise the bleeding limb above heart level (only if no fracture or spinal trauma is suspected).',
          'Wrap secure pressure bandage: Wrap firmly around dressing. If blood soaks through, add more layers on top—NEVER remove initial dressing.',
          'Emergency Tourniquet (for life-threatening limb arterial spurting): Apply tourniquet 5–7 cm above the wound (never over a joint), tighten windlass until bleeding stops, and record exact application time.',
        ],
        warningNotice:
          'DO NOT loosen or remove a tourniquet once applied. Mark "T" and the time on the patient\'s forehead for medical responders.',
      );
    }

    // 3. Flood Survival Triage Protocol
    if (lower.contains('flood') || lower.contains('water level') || lower.contains('drown') ||
        lower.contains('rising water') || lower.contains('current')) {
      return _ChatMessage(
        text: 'Immediate Flash Flood Survival & Evacuation Protocol:',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'Seek high ground immediately: Move upward to second story or roof access. Avoid closed attics with no roof hatch where water can trap you.',
          'Shut down utilities: Turn off primary electrical breaker and cylinder gas valves before floodwaters enter structure.',
          'Never cross moving floodwaters: 15 cm (6 in) of rushing water will sweep adults off feet; 30 cm (12 in) sweeps small vehicles away.',
          'Stay clear of electrical hazards: Assume all downed wires in flooded streets are live and lethal.',
          'Signal your location: Display bright cloth, wave flashlights at night, or blow 3 sharp whistle blasts for rescue boats and drones.',
        ],
        warningNotice:
          'Never drink floodwater. Floodwaters harbor industrial runoff, raw sewage, and dangerous submerged debris.',
      );
    }

    // 4. Earthquake Survival Triage Protocol
    if (lower.contains('earthquake') || lower.contains('quake') || lower.contains('shake') ||
        lower.contains('tremor') || lower.contains('aftershock')) {
      return _ChatMessage(
        text: 'Earthquake Survival Protocol (Drop, Cover, and Hold On):',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'DROP: Drop down to your hands and knees immediately to prevent being knocked over.',
          'COVER: Protect head and neck under a sturdy table or desk. If no shelter, curl against an interior wall away from windows.',
          'HOLD ON: Hold onto table legs until shaking completely stops. Protect your face and neck with arms.',
          'If outdoors: Move swiftly to an open area clear of power lines, masonry walls, glass windows, and chimneys.',
          'After shaking stops: Evacuate using stairs (NEVER elevators). Check for gas leaks (smell of sulfur) and turn off main valve.',
        ],
        warningNotice:
          'Expect strong aftershocks within minutes to hours. Do NOT stand in doorways—doorways in modern structures offer no extra protection.',
      );
    }

    // 5. Burn Treatment Triage Protocol
    if (lower.contains('burn') || lower.contains('scald') || lower.contains('fire burn') ||
        lower.contains('blister') || lower.contains('thermal')) {
      return _ChatMessage(
        text: 'Emergency Burn Treatment & Thermal Triage Protocol:',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'Cool with clean running water: Hold burned area under cool running water for 10 to 20 minutes immediately.',
          'Remove constrictive items: Gently take off rings, watches, belts, and tight clothing before swelling develops.',
          'Do NOT peel stuck clothing: If fabric is melted or adhered to burn, cut around it carefully; do not yank.',
          'Cover loosely: Cover area with a sterile non-adherent gauze or clean, smooth plastic cling film to block airborne infection.',
          'Prevent hypothermia: Keep the rest of patient\'s body warm with dry blankets, as severe burns cause rapid core heat loss.',
        ],
        warningNotice:
          'DO NOT apply ice, icy water, butter, oil, or toothpaste to burns. NEVER puncture or break burn blisters.',
      );
    }

    // 6. Hypothermia & Cold Shock Protocol
    if (lower.contains('hypotherm') || lower.contains('cold') || lower.contains('shiver') ||
        lower.contains('freez') || lower.contains('frostbite')) {
      return _ChatMessage(
        text: 'Hypothermia & Exposure Rewarming Protocol:',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'Insulate from cold ground & wind: Move person into shelter, out of wind and rain. Place blankets or sleeping pads under body.',
          'Carefully remove wet clothes: Strip off cold, wet clothing and replace with warm, dry layers, wool blankets, and hats.',
          'Rewarm the core torso first: Apply warm dry compresses or wrapped warm bottles to chest, neck, and groin. Do NOT rewarm arms/legs first.',
          'Offer warm, sweet fluids: If the person is alert and swallowing normally, provide warm sweet non-caffeinated drinks.',
          'Handle very gently: Sudden rough movements can trigger fatal ventricular fibrillation in deep hypothermia.',
        ],
        warningNotice:
          'DO NOT rub or massage frozen skin or limbs. DO NOT use direct boiling water or open flames to rewarm victims.',
      );
    }

    // 7. Water Purification Protocol
    if (lower.contains('water') || lower.contains('purif') || lower.contains('filter') ||
        lower.contains('boil') || lower.contains('drinkable')) {
      return _ChatMessage(
        text: 'Offline Water Purification Protocols:',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'Pre-filter sediment: Pour turbid water through layers of clean cotton cloth or sand to remove silt and dirt.',
          'Boiling (Gold Standard): Bring water to a full rolling boil for 1 minute (3 minutes at elevations above 2,000 m).',
          'Solar Disinfection (SODIS): Fill clean transparent PET plastic bottles 3/4 full, shake vigorously, top off, and leave in direct sunlight for 6 hours.',
          'Chlorine disinfection (Household bleach): Add 2 drops of unscented 6% household bleach per liter of clear water (4 drops if cloudy); let stand 30 min.',
          'Storage: Store purified water exclusively in sanitized, tightly covered containers.',
        ],
        warningNotice:
          'Purification kills microorganisms but does NOT remove industrial toxic chemicals or heavy metals. Use cleanest source available.',
      );
    }

    // 8. Food Storage & Safety Protocol
    if (lower.contains('food') || lower.contains('storage') || lower.contains('fridge') ||
        lower.contains('ration') || lower.contains('spoil')) {
      return _ChatMessage(
        text: 'Food Safety During Extended Power Outages:',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'Keep refrigerator sealed: An unopened fridge preserves food safely for 4 hours; a half-full freezer for 24 hours; full freezer for 48 hours.',
          'Prioritize perishables: Consume fresh milk, raw meat, poultry, and prepared leftovers first before they warm above 4°C (40°F).',
          'Transition to non-perishables: Utilize canned vegetables, pulses, rice, peanut butter, dried fruit, and biscuits.',
          'Inspect prior to eating: Discard any food that smells sour, feels slimy, shows mold, or has warmed above safe temperatures.',
        ],
        warningNotice:
          'When in doubt, throw it out. Acute food poisoning during a disaster causes severe dehydration and drains medical supplies.',
      );
    }

    // 9. Shelters & Relief
    if (lower.contains('shelter') || lower.contains('camp') || lower.contains('relief')) {
      return _ChatMessage(
        text: 'Nearby Emergency Relief Shelters (Offline Mesh Cache):',
        isUser: false,
        timestamp: timeStr,
        steps: [
          'Primary Community Hall: 1.2 km North (Capacity: 120, Food & Potable Water active).',
          'Government High School: 2.4 km East (Capacity: 250, Solar Charging & Triage available).',
          'District Red Cross Center: 3.8 km South (Medical triage, beds & emergency rations).',
          'Open "Shelters" tool in bottom navigation for live distance compass and occupancy status.',
        ],
        warningNotice:
          'Shelter records sync automatically as nearby mesh peers broadcast updated status packets.',
      );
    }

    // Default Fallback
    return _ChatMessage(
      text: 'RakshaNet Offline Emergency Guidance:',
      isUser: false,
      timestamp: timeStr,
      steps: [
        'Assess immediate life threats: Fire, structural collapse, rising water, or downed live power lines.',
        'Keep device in Low Power Mode: Enable true black OLED theme to maximize battery endurance during multi-day outages.',
        'Bluetooth Mesh Relay is active: Your device forwards and receives peer emergency beacons automatically.',
        'Hold the SOS Beacon for 1.5 seconds if you or someone nearby requires immediate rescue dispatch.',
      ],
      warningNotice:
        'All guidance is stored locally on this phone and compiled from verified NDMA, Red Cross, and AHA disaster protocols.',
    );
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
              'Offline Edge AI Engine',
              style: TextStyle(
                color: theme.text,
                fontSize: 18,
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
              'RakshaNet AI Assistant is completely self-contained on your mobile device.',
              style: TextStyle(color: theme.text, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              '• 0 KB Cellular data required\n• Instant response without cell towers\n• Pre-indexed offline disaster first aid protocols (CPR, Bleeding, Flood, Earthquake, Burns, Hypothermia)\n• Verified NDMA & Red Cross emergency knowledge base',
              style: TextStyle(
                color: theme.textMuted,
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
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Bar (Matches Mockup Screen 7)
            _buildHeaderBar(theme),

            // 2. Chat Stream Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: theme.text),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          // Yellow Beacon Circle with AI icon
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppTokens.signalYellow,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome,
                color: AppTokens.lightOnPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        size: 13, color: AppTokens.beaconTeal),
                    const SizedBox(width: 4),
                    Text(
                      'Offline on your device',
                      style: TextStyle(
                        color: theme.textMuted,
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
            icon: Icon(Icons.info_outline_rounded,
                color: theme.textMuted),
            tooltip: 'Offline Engine Status',
            onPressed: () => _showOfflineEngineInfo(theme),
          ),
          const ThemeToggleButton(compact: true),
          const ProfileAvatarButton(compact: true),
        ],
      ),
    );
  }

  Widget _buildUserMessage(_ChatMessage msg, ThemeProvider theme) {
    final bubbleColor = theme.isLightMode
        ? const Color(0xFFE8EEF5)
        : (theme.isLowPower ? const Color(0xFF161616) : AppTokens.darkSurfaceAlt);

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
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  msg.timestamp,
                  style: TextStyle(
                    color: theme.textMuted,
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
                color: cardBg,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: theme.border),
                boxShadow: theme.isLowPower
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: theme.isLightMode ? 0.06 : 0.25),
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
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
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
                              style: TextStyle(
                                color: theme.isLightMode ? AppTokens.lightPrimaryInk : AppTokens.signalYellow,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                stepText,
                                style: TextStyle(
                                  color: theme.text,
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
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              msg.warningNotice!,
                              style: TextStyle(
                                color: warningText,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
                            color: theme.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Offline Triage Rule Engine',
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        msg.timestamp,
                        style: TextStyle(
                          color: theme.textMuted,
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
                  'AI reasoning offline...',
                  style: TextStyle(
                    color: theme.textMuted,
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

  Widget _buildPromptSuggestions(ThemeProvider theme) {
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
                          size: 15,
                          color: theme.isLightMode ? AppTokens.lightPrimaryInk : AppTokens.signalYellow,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s.label,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 13,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
          // Input field container
          Expanded(
            child: Container(
              height: AppTokens.inputHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask anything...',
                    hintStyle: TextStyle(
                      color: theme.textMuted,
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
                    color: AppTokens.nightNavy,
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
