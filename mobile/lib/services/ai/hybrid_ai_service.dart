import 'ai_models.dart';
import 'ai_orchestrator.dart';

export 'ai_models.dart';
export 'ai_orchestrator.dart';
export 'offline_inference_service.dart';
export 'local_knowledge_retriever.dart';
export 'online_groq_service.dart';

/// Hybrid AI Service Adapter
/// Exposes backward-compatible API while delegating entirely to the centralized
/// AiOrchestrator and OfflineInferenceService.
/// ZERO API keys are embedded or exposed in this service.
class HybridAiService {
  static final HybridAiService instance = HybridAiService._();
  HybridAiService._();

  bool get forceOfflineMode => AiOrchestrator.instance.forceOfflineMode;
  set forceOfflineMode(bool value) {
    AiOrchestrator.instance.forceOfflineMode = value;
  }

  bool get isOnlineMode =>
      !forceOfflineMode &&
      AiOrchestrator.instance.state == AiOrchestratorState.onlineReady;

  /// Check internet reachability
  Future<bool> checkConnectivity() async {
    return AiOrchestrator.instance.checkConnectivity();
  }

  /// Main entry point: Process user query using Hybrid AI pipeline
  Future<AiResponse> processQuery(
    String query, {
    List<Map<String, String>> conversationHistory = const [],
    Map<String, dynamic>? telemetryContext,
  }) async {
    return AiOrchestrator.instance.processQuery(
      query,
      conversationHistory: conversationHistory,
      telemetryContext: telemetryContext,
    );
  }
}
