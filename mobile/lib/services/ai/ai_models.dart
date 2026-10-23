
/// Active Lifecycle States of the AI Assistant Orchestrator
enum AiOrchestratorState {
  onlineReady, // ONLINE · GROQ
  onlineRequest, // Generating via Groq Cloud
  onlineDegraded, // ONLINE · DEGRADED (cloud timed out, falling back)
  offlineReady, // OFFLINE · LOCAL AI
  offlineModelLoading, // Local model downloading or initializing
  offlineKnowledgeOnly, // OFFLINE · KNOWLEDGE BASE
  aiUnavailable, // Neither cloud nor local knowledge available
}

/// Active Inference Engine Identity
enum AiEngineType {
  groqCloud, // Cloud LLM via Backend proxy
  localModel, // On-Device NLP / SLM model
  localKnowledge, // Local Deterministic Verified Knowledge Base
  systemGateway, // Gateway Fallback
}

/// Verified Knowledge Source Metadata
class AiSource {
  final String id;
  final String title;
  final String organization;
  final String? url;
  final String jurisdiction;
  final String? verifiedDate;

  const AiSource({
    required this.id,
    required this.title,
    required this.organization,
    this.url,
    required this.jurisdiction,
    this.verifiedDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'organization': organization,
        'url': url,
        'jurisdiction': jurisdiction,
        'verified_date': verifiedDate,
      };

  factory AiSource.fromJson(Map<String, dynamic> json) => AiSource(
        id: json['id']?.toString() ?? 'SRC-OFFICIAL',
        title: json['title']?.toString() ?? 'Official Disaster Management Protocol',
        organization: json['organization']?.toString() ?? 'NDMA / WHO',
        url: json['url']?.toString(),
        jurisdiction: json['jurisdiction']?.toString() ?? 'India / Global',
        verifiedDate: json['verified_date']?.toString(),
      );
}

/// Standardized Typed AI Response across both Online and Offline Engines
class AiResponse {
  final String text;
  final List<String> steps;
  final String? warningNotice;
  final String source;
  final double confidence;
  final bool isOnline;
  final int latencyMs;
  final String urgency; // 'critical' | 'high' | 'advisory'
  final String? category;
  final AiEngineType engineType;
  final List<AiSource> sources;
  final String requestId;
  final int createdAt;
  final bool isDegraded;

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
    this.engineType = AiEngineType.localKnowledge,
    this.sources = const [],
    this.requestId = '',
    this.createdAt = 0,
    this.isDegraded = false,
  });

  String get answer => text;
  String get status => isDegraded
      ? 'ONLINE_DEGRADED'
      : (isOnline ? 'SUCCESS' : 'OFFLINE_READY');
}

/// UI Chat Message Representation with Feedback and Markdown support
class AiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final String timestamp;
  final List<String> steps;
  final String? warningNotice;
  final String source;
  final AiEngineType engineType;
  final List<AiSource> sources;
  final String urgency;
  final String? category;
  final int? latencyMs;
  final double? confidence;
  final String requestId;
  bool? feedbackPositive; // null: unrated, true: helpful, false: unhelpful

  AiChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.steps = const [],
    this.warningNotice,
    this.source = 'RakshaNet AI',
    this.engineType = AiEngineType.localKnowledge,
    this.sources = const [],
    this.urgency = 'high',
    this.category,
    this.latencyMs,
    this.confidence,
    this.requestId = '',
    this.feedbackPositive,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();
}
