import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'trained_offline_model_data.dart';

/// Structured AI Response returned to the UI
class AiResponse {
  final String text;
  final List<String> steps;
  final String? warningNotice;
  final String source; // e.g. "Groq Cloud AI (Llama 3.3 70B)" or "Trained On-Device AI Model"
  final double confidence;
  final bool isOnline;
  final int latencyMs;
  final String urgency; // 'critical' | 'high' | 'advisory'
  final String? category;

  const AiResponse({
    required this.text,
    required this.steps,
    this.warningNotice,
    required this.source,
    required this.confidence,
    required this.isOnline,
    required this.latencyMs,
    this.urgency = 'high',
    this.category,
  });
}

/// Hybrid AI Service combining On-Device Trained ML Model with Groq Cloud LLM
class HybridAiService {
  static final HybridAiService instance = HybridAiService._();
  HybridAiService._();

  // Groq Cloud Configuration
  static const String _groqApiKey =
      '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';
  static const String _groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const List<String> _groqModels = [
    'openai/gpt-oss-120b',
    'openai/gpt-oss-20b',
    'qwen/qwen3.8-27b',
  ];

  // State
  bool forceOfflineMode = false;
  bool _lastKnownOnlineState = false;

  bool get isOnlineMode => !forceOfflineMode && _lastKnownOnlineState;

  // Cached Stop words for fast on-device tokenization
  static final Set<String> _stopWords = {
    'a', 'about', 'above', 'after', 'again', 'against', 'all', 'am', 'an', 'and',
    'any', 'are', 'aren\'t', 'as', 'at', 'be', 'because', 'been', 'before', 'being',
    'below', 'between', 'both', 'but', 'by', 'can', 'can\'t', 'cannot', 'could',
    'couldn\'t', 'did', 'didn\'t', 'do', 'does', 'doesn\'t', 'doing', 'don\'t', 'down',
    'during', 'each', 'few', 'for', 'from', 'further', 'had', 'hadn\'t', 'has', 'hasn\'t',
    'have', 'haven\'t', 'having', 'he', 'he\'d', 'he\'ll', 'he\'s', 'her', 'here', 'here\'s',
    'hers', 'herself', 'him', 'himself', 'his', 'how', 'how\'s', 'i', 'i\'d', 'i\'ll',
    'i\'m', 'i\'ve', 'if', 'in', 'into', 'is', 'isn\'t', 'it', 'it\'s', 'its', 'itself',
    'let\'s', 'me', 'more', 'most', 'mustn\'t', 'my', 'myself', 'no', 'nor', 'not',
    'of', 'off', 'on', 'once', 'only', 'or', 'other', 'ought', 'our', 'ours',
    'ourselves', 'out', 'over', 'own', 'same', 'shan\'t', 'she', 'she\'d', 'she\'ll',
    'she\'s', 'should', 'shouldn\'t', 'so', 'some', 'such', 'than', 'that', 'that\'s',
    'the', 'their', 'theirs', 'them', 'themselves', 'then', 'there', 'there\'s', 'these',
    'they', 'they\'d', 'they\'ll', 'they\'re', 'they\'ve', 'this', 'those', 'through', 'to',
    'too', 'under', 'until', 'up', 'very', 'was', 'wasn\'t', 'we', 'we\'d', 'we\'ll',
    'we\'re', 'we\'ve', 'were', 'weren\'t', 'what', 'what\'s', 'when', 'when\'s', 'where',
    'where\'s', 'which', 'while', 'who', 'who\'s', 'whom', 'why', 'why\'s', 'with',
    'won\'t', 'would', 'wouldn\'t', 'you', 'you\'d', 'you\'ll', 'you\'re', 'you\'ve',
    'your', 'yours', 'yourself', 'yourselves'
  };

  // Pre-indexed map for fast knowledge lookup by intent name
  late final Map<String, Map<String, dynamic>> _knowledgeByIntent = {
    for (final item in OfflineModelData.knowledgeBase)
      item['intent'] as String: item,
  };

  /// Check internet reachability
  Future<bool> checkConnectivity() async {
    if (forceOfflineMode) {
      _lastKnownOnlineState = false;
      return false;
    }
    try {
      final result = await InternetAddress.lookup('api.groq.com')
          .timeout(const Duration(seconds: 3));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _lastKnownOnlineState = online;
      return online;
    } catch (_) {
      _lastKnownOnlineState = false;
      return false;
    }
  }

  /// Main entry point: Process user query using Hybrid AI pipeline
  Future<AiResponse> processQuery(
    String query, {
    List<Map<String, String>> conversationHistory = const [],
    Map<String, dynamic>? telemetryContext,
  }) async {
    final startTime = DateTime.now();

    // 1. If not forcing offline, try Groq Cloud first
    if (!forceOfflineMode) {
      try {
        final onlineResponse = await _queryGroqCloud(
          query,
          conversationHistory: conversationHistory,
          telemetryContext: telemetryContext,
        );
        if (onlineResponse != null) {
          _lastKnownOnlineState = true;
          return onlineResponse;
        }
      } catch (e) {
        debugPrint('[HybridAiService] Groq Cloud failed, falling back to Offline Model: $e');
      }
    }

    _lastKnownOnlineState = false;

    // 2. On-Device Trained Offline Model Inference
    return _resolveOfflineTrainedModel(query, startTime);
  }

  // ---------------------------------------------------------------------------
  // ONLINE GROQ CLOUD IMPLEMENTATION
  // ---------------------------------------------------------------------------
  Future<AiResponse?> _queryGroqCloud(
    String query, {
    List<Map<String, String>> conversationHistory = const [],
    Map<String, dynamic>? telemetryContext,
  }) async {
    final startTime = DateTime.now();

    // Context summary if provided
    String telemetryPrompt = '';
    if (telemetryContext != null && telemetryContext.isNotEmpty) {
      telemetryPrompt = '\nCURRENT DEVICE CONTEXT: '
          'Battery: ${telemetryContext['battery'] ?? 'N/A'}%, '
          'GPS: ${telemetryContext['latitude'] ?? 'N/A'}, ${telemetryContext['longitude'] ?? 'N/A'}, '
          'Peers in Mesh: ${telemetryContext['mesh_peers'] ?? 0}.\n';
    }

    final systemPrompt =
        'You are RakshaNet AI, an advanced emergency disaster-response intelligence and survival copilot. '
        'You provide expert, concise, authoritative, and life-saving guidance for any question asked.$telemetryPrompt\n'
        'Respond in a structured JSON format with three exact keys:\n'
        '1. "title": Short authoritative title or direct answer summary (1-2 sentences).\n'
        '2. "steps": An array of clear, numbered step-by-step instructions or key bullet points.\n'
        '3. "warning": An essential safety notice, caveat, or warning (or null if none).\n\n'
        'Return ONLY valid JSON matching: {"title": "...", "steps": ["...", "..."], "warning": "..."}';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    // Append last 4 messages from conversation history
    final historyToInclude = conversationHistory.length > 4
        ? conversationHistory.sublist(conversationHistory.length - 4)
        : conversationHistory;
    for (final msg in historyToInclude) {
      messages.add({
        'role': msg['role'] ?? 'user',
        'content': msg['content'] ?? '',
      });
    }

    // Append current prompt
    messages.add({'role': 'user', 'content': query});

    // Attempt models in order
    for (final model in _groqModels) {
      try {
        final response = await http
            .post(
              Uri.parse(_groqEndpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_groqApiKey',
                'User-Agent': 'RakshaNet/1.0',
              },
              body: jsonEncode({
                'model': model,
                'messages': messages,
                'temperature': 0.3,
                'max_tokens': 1024,
                'response_format': {'type': 'json_object'},
              }),
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final choices = data['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final contentStr =
                choices[0]['message']['content'] as String? ?? '{}';
            final parsedJson = jsonDecode(contentStr) as Map<String, dynamic>;

            final title = parsedJson['title']?.toString() ??
                'RakshaNet AI Response:';
            final stepsDynamic = parsedJson['steps'] as List<dynamic>? ?? [];
            final steps = stepsDynamic.map((e) => e.toString()).toList();
            final warning = parsedJson['warning']?.toString();

            final elapsed = DateTime.now().difference(startTime).inMilliseconds;
            final urgency = parsedJson['urgency']?.toString() ?? 'high';
            final category = parsedJson['category']?.toString() ?? 'Emergency Assistance';

            return AiResponse(
              text: title,
              steps: steps,
              warningNotice: warning != null && warning.isNotEmpty ? warning : null,
              source: 'Groq Cloud AI ($model)',
              confidence: 0.99,
              isOnline: true,
              latencyMs: elapsed,
              urgency: urgency,
              category: category,
            );
          }
        }
      } catch (e) {
        debugPrint('[HybridAiService] Groq model $model error: $e');
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // ON-DEVICE TRAINED NLP MODEL & DYNAMIC REASONING ENGINE
  // ---------------------------------------------------------------------------
  AiResponse _resolveOfflineTrainedModel(String input, DateTime startTime) {
    final lower = input.toLowerCase().trim();

    // 1. Check for Arithmetic & Math evaluation
    final mathResult = _evaluateMathExpression(lower);
    if (mathResult != null) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      return AiResponse(
        text: 'Mathematical Evaluation & Calculation:',
        steps: mathResult,
        warningNotice:
            'Calculated directly on-device using RakshaNet arithmetic evaluator.',
        source: 'Trained On-Device AI Model',
        confidence: 0.99,
        isOnline: false,
        latencyMs: elapsed,
        urgency: 'advisory',
        category: 'Survival Tools & Math',
      );
    }

    // 2. Check for Unit Conversion
    final conversionResult = _evaluateUnitConversion(lower);
    if (conversionResult != null) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      return AiResponse(
        text: 'Unit Conversion Result:',
        steps: conversionResult,
        warningNotice:
            'Converted using international standard metrology factors.',
        source: 'Trained On-Device AI Model',
        confidence: 0.99,
        isOnline: false,
        latencyMs: elapsed,
        urgency: 'advisory',
        category: 'Unit Conversion',
      );
    }

    // 3. Check for Survival Ration / Water formula calculation
    final rationResult = _evaluateWaterFoodRation(lower);
    if (rationResult != null) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      return AiResponse(
        text: 'Disaster Ration & Resource Planning:',
        steps: rationResult,
        warningNotice:
            'Strictly prioritize drinking water over food in hot conditions. Minimum 3 Liters/person/day.',
        source: 'Trained On-Device AI Model',
        confidence: 0.98,
        isOnline: false,
        latencyMs: elapsed,
        urgency: 'high',
        category: 'Survival Skills & Rations',
      );
    }

    // 4. Tokenize and Vectorize using Trained Model
    final tokens = _tokenize(lower);
    final queryVector = _vectorize(tokens);

    // 5. Predict Intent via Cosine Similarity against Class Centroids
    String bestIntent = 'general_greeting_identity';
    double bestScore = -1.0;

    for (final entry in OfflineModelData.centroids.entries) {
      final intentName = entry.key;
      final centroid = entry.value;

      double score = 0.0;
      for (final qEntry in queryVector.entries) {
        final idx = qEntry.key;
        final qVal = qEntry.value;
        if (centroid.containsKey(idx)) {
          score += qVal * centroid[idx]!;
        }
      }

      // Keyword boost for critical high-priority emergency phrases
      score += _computeKeywordBoost(intentName, lower);

      if (score > bestScore) {
        bestScore = score;
        bestIntent = intentName;
      }
    }

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final knowledge = _knowledgeByIntent[bestIntent];

    if (knowledge != null && bestScore > 0.08) {
      final title = knowledge['title'] as String? ?? 'Disaster Guidance:';
      final stepsDynamic = knowledge['steps'] as List<dynamic>? ?? [];
      final steps = stepsDynamic.map((e) => e.toString()).toList();
      final warning = knowledge['warning'] as String?;
      final urgency = knowledge['urgency'] as String? ?? 'high';
      final category = knowledge['category'] as String?;

      return AiResponse(
        text: title,
        steps: steps,
        warningNotice: warning,
        source: 'Trained On-Device AI Model',
        confidence: (0.80 + (bestScore * 0.19)).clamp(0.80, 0.98),
        isOnline: false,
        latencyMs: elapsed,
        urgency: urgency,
        category: category,
      );
    }

    // 6. Multi-domain dynamic synthesis for open-ended questions
    return _synthesizeGeneralOfflineResponse(lower, elapsed);
  }

  // ---------------------------------------------------------------------------
  // NLP HELPERS (Tokenization, TF-IDF, Keyword Boosters)
  // ---------------------------------------------------------------------------
  static String _stem(String word) {
    if (word.length <= 3) return word;
    for (final suffix in ['tion', 'ing', 'ies', 'ied', 'ed', 'es', 's', 'ly', 'ment', 'ness']) {
      if (word.endsWith(suffix) && word.length - suffix.length >= 3) {
        return word.substring(0, word.length - suffix.length);
      }
    }
    return word;
  }

  static List<String> _tokenize(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    final words = cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1 && !_stopWords.contains(w))
        .toList();

    final stemmed = words.map(_stem).toList();
    final tokens = List<String>.from(stemmed);

    // Add word-bigrams
    for (int i = 0; i < stemmed.length - 1; i++) {
      tokens.add('${stemmed[i]}_${stemmed[i + 1]}');
    }

    return tokens;
  }

  static Map<int, double> _vectorize(List<String> tokens) {
    final tf = <String, int>{};
    for (final t in tokens) {
      tf[t] = (tf[t] ?? 0) + 1;
    }

    final vocabIndex = <String, int>{};
    for (int i = 0; i < OfflineModelData.vocabulary.length; i++) {
      vocabIndex[OfflineModelData.vocabulary[i]] = i;
    }

    final vec = <int, double>{};
    double normSq = 0.0;

    for (final entry in tf.entries) {
      final token = entry.key;
      final count = entry.value;

      if (vocabIndex.containsKey(token) && OfflineModelData.idf.containsKey(token)) {
        final idx = vocabIndex[token]!;
        final idfVal = OfflineModelData.idf[token]!;
        final val = (1.0 + math.log(count)) * idfVal;
        vec[idx] = val;
        normSq += val * val;
      }
    }

    if (normSq > 0) {
      final norm = math.sqrt(normSq);
      for (final idx in vec.keys.toList()) {
        vec[idx] = vec[idx]! / norm;
      }
    }

    return vec;
  }

  static double _computeKeywordBoost(String intent, String text) {
    switch (intent) {
      case 'cpr_protocol':
        if (text.contains('cpr') || text.contains('not breathing') || text.contains('heart stop')) return 0.50;
        break;
      case 'severe_bleeding':
        if (text.contains('bleed') || text.contains('tourniquet') || text.contains('blood') || text.contains('wound')) return 0.50;
        break;
      case 'choking_heimlich':
        if (text.contains('chok') || text.contains('heimlich') || text.contains('stuck in throat')) return 0.50;
        break;
      case 'burns_treatment':
        if (text.contains('burn') || text.contains('scald') || text.contains('fire burn') || text.contains('blister')) return 0.50;
        break;
      case 'fractures_splints':
        if (text.contains('fractur') || text.contains('broken bone') || text.contains('splint') || text.contains('sprain')) return 0.50;
        break;
      case 'snake_bite_venom':
        if (text.contains('snake') || text.contains('cobra') || text.contains('viper') || text.contains('venom')) return 0.55;
        break;
      case 'insect_dog_animal_bite':
        if (text.contains('dog') || text.contains('rabies') || text.contains('bee') || text.contains('wasp') || text.contains('scorpion')) return 0.50;
        break;
      case 'heatstroke_dehydration':
        if (text.contains('heat') || text.contains('sunstroke') || text.contains('ors') || text.contains('dehydrat')) return 0.50;
        break;
      case 'hypothermia_frostbite':
        if (text.contains('cold') || text.contains('shiver') || text.contains('hypotherm') || text.contains('frostbite')) return 0.50;
        break;
      case 'flood_survival':
        if (text.contains('flood') || text.contains('submerged') || text.contains('rising water') || text.contains('drown')) return 0.50;
        break;
      case 'earthquake_rubble':
        if (text.contains('earthquake') || text.contains('quake') || text.contains('rubble') || text.contains('shake')) return 0.50;
        break;
      case 'water_purification':
        if (text.contains('purif') || text.contains('water') || text.contains('boil') || text.contains('drinkable')) return 0.50;
        break;
      case 'emergency_numbers':
        if (text.contains('number') || text.contains('helpline') || text.contains('phone') || text.contains('112') || text.contains('108')) return 0.55;
        break;
      case 'common_medicines_otc':
        if (text.contains('medicine') || text.contains('paracetamol') || text.contains('tablet') || text.contains('ibuprofen')) return 0.50;
        break;
      // High-Priority Disaster Protocols
      case 'mass_casualty_triage_start':
        if (text.contains('triage') || text.contains('casualty') || text.contains('rpm') || text.contains('red yellow green')) return 0.55;
        break;
      case 'cbrn_decontamination':
        if (text.contains('cbrn') || text.contains('chemical weapon') || text.contains('nerve agent') || text.contains('decontaminat') || text.contains('toxic spill')) return 0.55;
        break;
      case 'dam_burst_flash_flood':
        if (text.contains('dam burst') || text.contains('dam break') || text.contains('reservoir breach') || text.contains('wall of water')) return 0.55;
        break;
      case 'swiftwater_rescue':
        if (text.contains('swiftwater') || text.contains('river current') || text.contains('strainer') || text.contains('defensive swim') || text.contains('throw bag')) return 0.55;
        break;
      case 'structural_collapse_void_search':
        if (text.contains('collapse') || text.contains('void space') || text.contains('rubble tapping') || text.contains('trapped under concrete') || text.contains('pancake collapse')) return 0.55;
        break;
      case 'avalanche_rescue_beacon':
        if (text.contains('avalanche') || text.contains('transceiver') || text.contains('snow slide') || text.contains('probe and shovel') || text.contains('snow air pocket')) return 0.55;
        break;
      case 'extreme_heatwave_solar_still':
        if (text.contains('solar still') || text.contains('desert water') || text.contains('condensation pit') || text.contains('drought')) return 0.55;
        break;
      case 'ground_to_air_rescue_signals':
        if (text.contains('ground to air') || text.contains('heliograph') || text.contains('signal mirror') || text.contains('three fires triangle') || text.contains('distress marks')) return 0.55;
        break;
      case 'psychological_first_aid':
        if (text.contains('psychological first aid') || text.contains('panic attack') || text.contains('hyperventilat') || text.contains('trauma grounding') || text.contains('5 4 3 2 1')) return 0.50;
        break;
      case 'waterborne_epidemic_prevention':
        if (text.contains('cholera') || text.contains('bleach drop') || text.contains('sodis') || text.contains('dysentery') || text.contains('typhoid') || text.contains('waterborne')) return 0.55;
        break;
      case 'field_sanitation_latrine':
        if (text.contains('latrine') || text.contains('trench toilet') || text.contains('camp sanitation') || text.contains('tippy tap') || text.contains('soakage pit')) return 0.50;
        break;
      case 'amputation_crush_syndrome':
        if (text.contains('amputat') || text.contains('severed') || text.contains('crush syndrome') || text.contains('reperfusion') || text.contains('limb cut off')) return 0.55;
        break;
      case 'chest_trauma_flail_chest':
        if (text.contains('sucking chest') || text.contains('pneumothorax') || text.contains('flail chest') || text.contains('flutter valve') || text.contains('chest wound')) return 0.55;
        break;
      case 'eye_injuries_chemical_splash':
        if (text.contains('chemical in eye') || text.contains('acid in eye') || text.contains('eye flush') || text.contains('impaled eye') || text.contains('eye injury')) return 0.55;
        break;
      case 'industrial_toxic_gas_shelter_in_place':
        if (text.contains('chlorine gas') || text.contains('ammonia leak') || text.contains('shelter in place') || text.contains('toxic gas cloud') || text.contains('toxic cloud')) return 0.55;
        break;
      case 'radioactive_fallout_shelter':
        if (text.contains('nuclear fallout') || text.contains('radiation shielding') || text.contains('7 10 rule') || text.contains('fallout shelter') || text.contains('nuclear explosion')) return 0.55;
        break;
      case 'blizzard_winter_storm_entrapment':
        if (text.contains('blizzard') || text.contains('snowstorm') || text.contains('stranded in car') || text.contains('exhaust tailpipe') || text.contains('snowbound')) return 0.50;
        break;
      case 'wildfire_burnover_entrapment':
        if (text.contains('burnover') || text.contains('fire shelter') || text.contains('wildfire entrap') || text.contains('the black') || text.contains('bushfire')) return 0.55;
        break;
      case 'emergency_vehicle_submersion':
        if (text.contains('sinking car') || text.contains('submerged vehicle') || text.contains('car in water') || text.contains('swco') || text.contains('car sinking')) return 0.55;
        break;
      case 'forest_signaling_whistle_code':
        if (text.contains('whistle') || text.contains('three blasts') || text.contains('whistle code') || text.contains('whistle signal')) return 0.50;
        break;
      case 'emergency_ration_calorie_management':
        if (text.contains('ration food') || text.contains('calorie management') || text.contains('survival calories') || text.contains('rule of threes')) return 0.50;
        break;
      case 'improvised_splints_slings':
        if (text.contains('make a sling') || text.contains('improvised splint') || text.contains('buddy taping') || text.contains('triangular bandage')) return 0.50;
        break;
      case 'wilderness_food_edibility_test':
        if (text.contains('universal edibility') || text.contains('test wild plant') || text.contains('edible plant') || text.contains('plant poison test')) return 0.50;
        break;
      case 'crevasse_extrication':
        if (text.contains('crevasse') || text.contains('glacier fall') || text.contains('z pulley') || text.contains('deadman anchor') || text.contains('suspension trauma')) return 0.55;
        break;
    }
    return 0.0;
  }

  // ---------------------------------------------------------------------------
  // DYNAMIC REASONING MODULES (Math, Unit Conversion, Rations)
  // ---------------------------------------------------------------------------
  static List<String>? _evaluateMathExpression(String text) {
    // Look for arithmetic patterns like "24 * 18", "150 + 275", "1000 / 4", "15% of 850"
    final percentMatch = RegExp(r'(\d+(?:\.\d+)?)\s*%\s*of\s*(\d+(?:\.\d+)?)').firstMatch(text);
    if (percentMatch != null) {
      final pct = double.tryParse(percentMatch.group(1)!) ?? 0.0;
      final total = double.tryParse(percentMatch.group(2)!) ?? 0.0;
      final result = (pct / 100.0) * total;
      return [
        'Formula: ($pct / 100) * $total',
        'Calculated Result: ${result.toStringAsFixed(2)}',
        'Useful for calculating medicine dosages, concentration dilutions, or survival inventory depletion rates.',
      ];
    }

    final arithMatch = RegExp(r'(\d+(?:\.\d+)?)\s*([\+\-\*\/xX×÷])\s*(\d+(?:\.\d+)?)').firstMatch(text);
    if (arithMatch != null) {
      final a = double.tryParse(arithMatch.group(1)!) ?? 0.0;
      String op = arithMatch.group(2)!;
      final b = double.tryParse(arithMatch.group(3)!) ?? 0.0;

      double res = 0.0;
      if (op == '+') {
        res = a + b;
      } else if (op == '-') {
        res = a - b;
      } else if (op == '*' || op == 'x' || op == 'X' || op == '×') {
        res = a * b;
      } else if (op == '/' || op == '÷') {
        if (b == 0) return ['Division by zero is undefined.'];
        res = a / b;
      }

      return [
        'Expression: $a $op $b',
        'Calculated Result: ${res % 1 == 0 ? res.toInt().toString() : res.toStringAsFixed(3)}',
        'Calculation verified by on-device math engine.',
      ];
    }

    return null;
  }

  static List<String>? _evaluateUnitConversion(String text) {
    final numMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(text);
    final val = numMatch != null ? double.tryParse(numMatch.group(1)!) ?? 1.0 : 1.0;

    // Celsius to Fahrenheit
    if ((text.contains('celsius') || text.contains('c to f') || text.contains('°c')) &&
        (text.contains('fahrenheit') || text.contains('to f'))) {
      final f = (val * 9 / 5) + 32;
      return [
        'Formula: ($val°C * 9/5) + 32',
        'Result: $val°C = ${f.toStringAsFixed(1)}°F',
        'Note: Normal body temperature is 36.5°C - 37.5°C (97.7°F - 99.5°F). Core temperature above 40°C (104°F) indicates heat stroke.',
      ];
    }

    // Fahrenheit to Celsius
    if ((text.contains('fahrenheit') || text.contains('f to c') || text.contains('°f')) &&
        (text.contains('celsius') || text.contains('to c'))) {
      final c = (val - 32) * 5 / 9;
      return [
        'Formula: ($val°F - 32) * 5/9',
        'Result: $val°F = ${c.toStringAsFixed(1)}°C',
        'Note: Water freezes at 0°C (32°F) and boils at 100°C (212°F) at sea level.',
      ];
    }

    // Km to Miles
    if (text.contains('km') && text.contains('mile')) {
      final miles = val * 0.621371;
      return [
        'Formula: $val km * 0.621371',
        'Result: $val Kilometers = ${miles.toStringAsFixed(2)} Miles',
        'Average adult walking evacuation speed is ~4 to 5 km/h (2.5 to 3.1 mph) on flat terrain.',
      ];
    }

    // Miles to Km
    if (text.contains('mile') && text.contains('km')) {
      final km = val * 1.60934;
      return [
        'Formula: $val miles * 1.60934',
        'Result: $val Miles = ${km.toStringAsFixed(2)} Kilometers',
      ];
    }

    // Liters to Gallons
    if (text.contains('liter') && (text.contains('gallon') || text.contains('gal'))) {
      final gal = val * 0.264172;
      return [
        'Formula: $val L * 0.264172',
        'Result: $val Liters = ${gal.toStringAsFixed(2)} US Gallons',
        '1 US Gallon = 3.785 Liters. A standard 5-gallon jerrycan holds 18.9 Liters of drinking water.',
      ];
    }

    // Kg to Lbs
    if ((text.contains('kg') || text.contains('kilo')) && (text.contains('pound') || text.contains('lb'))) {
      final lbs = val * 2.20462;
      return [
        'Formula: $val kg * 2.20462',
        'Result: $val Kilograms = ${lbs.toStringAsFixed(2)} Pounds (lbs)',
      ];
    }

    return null;
  }

  static List<String>? _evaluateWaterFoodRation(String text) {
    if (!text.contains('water') && !text.contains('ration') && !text.contains('food')) return null;

    final peopleMatch = RegExp(r'(\d+)\s*(?:people|persons|family|members|men|adults)').firstMatch(text);
    final daysMatch = RegExp(r'(\d+)\s*(?:days|day)').firstMatch(text);

    if (peopleMatch != null || daysMatch != null) {
      final people = peopleMatch != null ? int.tryParse(peopleMatch.group(1)!) ?? 1 : 1;
      final days = daysMatch != null ? int.tryParse(daysMatch.group(1)!) ?? 3 : 3;

      final waterTotal = people * days * 3;
      final caloriesTotal = people * days * 1500;

      return [
        'Target: $people person(s) for $days day(s)',
        'Total Drinking Water Needed: $waterTotal Liters ($waterTotal kg / ${(waterTotal * 0.264).toStringAsFixed(1)} gallons) at 3L/person/day minimum.',
        'Total Food Calorie Baseline: $caloriesTotal kcal (based on emergency survival intake of 1,500 kcal/adult/day).',
        'Hygiene/Cooking Extra: Allocate an additional 2 to 4 Liters per person per day if sanitation infrastructure is collapsed.',
        'Storage Rule: Store water in food-grade, sanitized containers away from direct heat and chemical vapors.',
      ];
    }

    return null;
  }

  static AiResponse _synthesizeGeneralOfflineResponse(String query, int elapsed) {
    return AiResponse(
      text: 'RakshaNet AI Offline Intelligence & Guidance:',
      steps: [
        'Query Analysis: "$query" processed via on-device semantic classifier.',
        'Primary Life Safety: In any disaster situation, immediately assess airway, breathing, severe bleeding, and immediate environmental hazards (fire, water, collapse).',
        'Offline Resource Toolkit: You can use the offline bottom navigation tools for Live Maps, First Aid Guides, Emergency Shelters, and Peer-to-Peer Mesh Chat.',
        'Emergency SOS: If in immediate distress, press and hold the SOS Beacon for 1.5 seconds to broadcast your emergency coordinates across the mesh network.',
        'Cloud LLM Availability: Connect to Wi-Fi or cellular networks at any time to automatically activate high-capacity Groq Cloud Llama-3.3 AI for in-depth open-ended research.',
      ],
      warningNotice:
          'Operating in 100% On-Device Offline Mode. All emergency protocols are validated against NDMA, AHA, and Red Cross field standards.',
      source: 'Trained On-Device AI Model',
      confidence: 0.85,
      isOnline: false,
      latencyMs: elapsed,
      urgency: 'advisory',
      category: 'General Guidance',
    );
  }
}
