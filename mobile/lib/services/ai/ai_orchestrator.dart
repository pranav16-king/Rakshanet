import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ai_models.dart';
import 'online_groq_service.dart';
import 'offline_inference_service.dart';
import 'local_knowledge_retriever.dart';

/// Centralized AI Orchestrator
/// Manages automatic routing between Online Groq Cloud and Offline On-Device Inference.
class AiOrchestrator extends ChangeNotifier {
  static final AiOrchestrator instance = AiOrchestrator._();
  AiOrchestrator._() {
    // Default to offlineReady; network probe occurs on-demand without background timer leaks
    _state = AiOrchestratorState.offlineReady;
  }

  // Active State
  AiOrchestratorState _state = AiOrchestratorState.offlineReady;
  AiOrchestratorState get state => _state;

  bool _forceOfflineMode = false;
  bool get forceOfflineMode => _forceOfflineMode;
  set forceOfflineMode(bool value) {
    if (_forceOfflineMode != value) {
      _forceOfflineMode = value;
      _updateEffectiveState();
      notifyListeners();
    }
  }

  bool _lastKnownNetworkOnline = false;
  bool get isNetworkOnline => _lastKnownNetworkOnline;

  // Active cancellation token
  Completer<void>? _activeRequestCompleter;
  bool _isRequestCancelled = false;

  bool get isGenerating => _state == AiOrchestratorState.onlineRequest || _activeRequestCompleter != null;

  /// Human-readable Header Status Label
  String get statusLabel {
    if (_forceOfflineMode) {
      return 'OFFLINE · LOCAL AI (MANUAL)';
    }
    switch (_state) {
      case AiOrchestratorState.onlineReady:
        return 'ONLINE · GROQ';
      case AiOrchestratorState.onlineRequest:
        return 'ONLINE · GROQ (GENERATING)';
      case AiOrchestratorState.onlineDegraded:
        return 'ONLINE · DEGRADED (FALLBACK)';
      case AiOrchestratorState.offlineReady:
        return 'OFFLINE · LOCAL AI';
      case AiOrchestratorState.offlineModelLoading:
        return 'OFFLINE · MODEL INITIALIZING';
      case AiOrchestratorState.offlineKnowledgeOnly:
        return 'OFFLINE · KNOWLEDGE BASE';
      case AiOrchestratorState.aiUnavailable:
        return 'AI UNAVAILABLE';
    }
  }

  /// Check connectivity to backend / internet
  Future<bool> checkConnectivity() async {
    if (_forceOfflineMode) {
      _lastKnownNetworkOnline = false;
      _state = AiOrchestratorState.offlineReady;
      notifyListeners();
      return false;
    }

    try {
      final result = await InternetAddress.lookup('1.1.1.1')
          .timeout(const Duration(milliseconds: 1500));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _lastKnownNetworkOnline = online;

      if (online) {
        _state = AiOrchestratorState.onlineReady;
      } else {
        _state = AiOrchestratorState.offlineReady;
      }
      notifyListeners();
      return online;
    } catch (_) {
      _lastKnownNetworkOnline = false;
      _state = AiOrchestratorState.offlineReady;
      notifyListeners();
      return false;
    }
  }

  void _updateEffectiveState() {
    if (_forceOfflineMode) {
      _state = AiOrchestratorState.offlineReady;
    } else if (_lastKnownNetworkOnline) {
      _state = AiOrchestratorState.onlineReady;
    } else {
      _state = AiOrchestratorState.offlineReady;
    }
  }

  /// Cancels any currently executing generation request
  void cancelCurrentRequest() {
    if (_activeRequestCompleter != null && !_activeRequestCompleter!.isCompleted) {
      _isRequestCancelled = true;
      _activeRequestCompleter!.complete();
      _activeRequestCompleter = null;
      _updateEffectiveState();
      notifyListeners();
    }
  }

  /// Central Routing Pipeline: Process query through Online Groq with graceful Offline fallback
  Future<AiResponse> processQuery(
    String query, {
    List<Map<String, String>> conversationHistory = const [],
    Map<String, dynamic>? telemetryContext,
    String? category,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return LocalKnowledgeRetriever.instance.retrieve('emergency general');
    }

    // Set up concurrency / cancellation guard
    cancelCurrentRequest();
    final completer = Completer<void>();
    _activeRequestCompleter = completer;
    _isRequestCancelled = false;

    // 1. If Online & NOT forcing offline, attempt Groq Cloud via Backend Proxy
    if (!_forceOfflineMode) {
      _state = AiOrchestratorState.onlineRequest;
      notifyListeners();

      try {
        final onlineResponse = await OnlineGroqService.instance.queryBackend(
          trimmed,
          conversationHistory: conversationHistory,
          telemetryContext: telemetryContext,
          category: category,
          timeout: const Duration(seconds: 5),
        );

        if (_isRequestCancelled) {
          throw Exception('Request cancelled by user');
        }

        if (onlineResponse != null && !onlineResponse.isDegraded) {
          _state = AiOrchestratorState.onlineReady;
          _activeRequestCompleter = null;
          notifyListeners();
          return onlineResponse;
        }

        if (onlineResponse != null && onlineResponse.isDegraded) {
          _state = AiOrchestratorState.onlineDegraded;
          notifyListeners();
          // Fall through to offline inference for richer immediate local guidance
        }
      } catch (e) {
        debugPrint('[AiOrchestrator] Online query error ($e), transitioning to offline inference.');
        _state = AiOrchestratorState.onlineDegraded;
        notifyListeners();
      }
    }

    if (_isRequestCancelled) {
      _activeRequestCompleter = null;
      throw Exception('Request was cancelled.');
    }

    // 2. Offline Inference Engine (On-Device Model + Local Knowledge Base)
    try {
      final offlineResponse = OfflineInferenceService.instance.infer(trimmed);
      _activeRequestCompleter = null;
      _updateEffectiveState();
      notifyListeners();
      return offlineResponse;
    } catch (e) {
      debugPrint('[AiOrchestrator] On-Device Model failed ($e), falling back to Local Knowledge Base.');
      _state = AiOrchestratorState.offlineKnowledgeOnly;
      notifyListeners();
      final knowledgeResponse = LocalKnowledgeRetriever.instance.retrieve(trimmed);
      _activeRequestCompleter = null;
      _updateEffectiveState();
      notifyListeners();
      return knowledgeResponse;
    }
  }
}
