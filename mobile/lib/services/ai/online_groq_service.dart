import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import 'ai_models.dart';

/// Client Service for Backend Groq Cloud Proxy
/// Communicates ONLY with RakshaNet backend `/api/v1/ai/chat`.
/// NEVER stores or exposes Groq API keys on mobile devices.
class OnlineGroqService {
  static final OnlineGroqService instance = OnlineGroqService._();
  OnlineGroqService._();

  // Backend host fallback addresses
  static const String _defaultLocalhost = 'http://127.0.0.1:8000';
  static const String _androidEmulatorHost = 'http://10.0.2.2:8000';

  String get _backendBaseUrl {
    if (AppConfig.backendBaseUrl.isNotEmpty) {
      return AppConfig.backendBaseUrl;
    }
    if (kIsWeb) return _defaultLocalhost;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidEmulatorHost;
    }
    return _defaultLocalhost;
  }

  /// Sends query to backend Groq AI Gateway
  Future<AiResponse?> queryBackend(
    String query, {
    List<Map<String, String>> conversationHistory = const [],
    Map<String, dynamic>? telemetryContext,
    String? category,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final startTime = DateTime.now();

    final urlsToTry = [
      '$_backendBaseUrl/api/v1/ai/chat',
      '$_defaultLocalhost/api/v1/ai/chat',
      '$_androidEmulatorHost/api/v1/ai/chat',
    ];

    for (final url in urlsToTry) {
      try {
        final uri = Uri.parse(url);
        final payload = {
          'query': query,
          'conversation_history': conversationHistory,
          'category': category,
          'telemetry': telemetryContext,
        };

        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'User-Agent': 'RakshaNet-Mobile-AI/2.0',
              },
              body: jsonEncode(payload),
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;

          final rawSources = data['sources'] as List<dynamic>? ?? [];
          final sourcesList = rawSources.map((s) {
            if (s is Map<String, dynamic>) {
              return AiSource.fromJson(s);
            }
            return const AiSource(
              id: 'SRC-CLOUD',
              title: 'Official Disaster Guidelines',
              organization: 'NDMA / WHO',
              jurisdiction: 'National',
            );
          }).toList();

          final rawSteps = data['steps'] as List<dynamic>? ?? [];
          final stepsList = rawSteps.map((e) => e.toString()).toList();
          final status = data['status']?.toString() ?? 'SUCCESS';
          final isDegraded = status == 'ONLINE_DEGRADED';

          return AiResponse(
            text: data['answer']?.toString() ?? 'Emergency Response Guidance:',
            steps: stepsList,
            warningNotice: data['warnings']?.toString(),
            source: data['engine']?.toString() ?? 'Groq Cloud LLM (Llama 3.3 70B)',
            confidence: 0.98,
            isOnline: !isDegraded,
            latencyMs: elapsed,
            urgency: data['urgency']?.toString() ?? 'high',
            category: data['category']?.toString() ?? category,
            engineType: isDegraded ? AiEngineType.systemGateway : AiEngineType.groqCloud,
            sources: sourcesList,
            requestId: data['request_id']?.toString() ?? '',
            createdAt: data['created_at'] is int
                ? data['created_at'] as int
                : DateTime.now().millisecondsSinceEpoch,
            isDegraded: isDegraded,
          );
        }
      } catch (e) {
        debugPrint('[OnlineGroqService] Attempt to $url failed: $e');
      }
    }

    return null;
  }
}
