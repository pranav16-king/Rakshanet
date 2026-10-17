import 'package:flutter/foundation.dart';
import '../services/sos_alert_service.dart';

/// Provider for managing local emergency SOS triggers and reactive UI state
class SosProvider extends ChangeNotifier {
  static final SosProvider instance = SosProvider._internal();
  factory SosProvider() => instance;

  SosProvider._internal() {
    SosAlertService.instance.activeAlertNotifier.addListener(_onAlertChanged);
    SosAlertService.instance.isSirenPlayingNotifier.addListener(_onSirenChanged);
    SosAlertService.instance.isMutedNotifier.addListener(_onMuteChanged);
  }

  bool _isSosActive = false;
  bool get isSosActive => _isSosActive;

  EmergencyAlertEvent? get activeAlert => SosAlertService.instance.currentAlert;
  bool get isSirenPlaying => SosAlertService.instance.isSirenPlaying;
  bool get isMuted => SosAlertService.instance.isMuted;

  void _onAlertChanged() {
    final alert = SosAlertService.instance.currentAlert;
    _isSosActive = alert != null && alert.isLocal;
    notifyListeners();
  }

  void _onSirenChanged() {
    notifyListeners();
  }

  void _onMuteChanged() {
    notifyListeners();
  }

  /// Initiates a local SOS distress broadcast from this device
  void triggerLocalSos({
    required String category,
    int peopleCount = 1,
    double? latitude,
    double? longitude,
    String? notes,
    String? messageId,
  }) {
    _isSosActive = true;
    SosAlertService.instance.triggerLocalAlert(
      category: category,
      peopleCount: peopleCount,
      lat: latitude,
      lng: longitude,
      notes: notes,
      messageId: messageId,
    );
    notifyListeners();
  }

  /// Cancels or disarms the active local distress beacon
  void cancelLocalSos() {
    _isSosActive = false;
    SosAlertService.instance.dismissAlert();
    notifyListeners();
  }

  /// Mutes audio siren without dismissing the emergency banner
  void muteSiren() {
    SosAlertService.instance.muteSiren();
    notifyListeners();
  }

  /// Unmutes audio siren
  void unmuteSiren() {
    SosAlertService.instance.unmuteSiren();
    notifyListeners();
  }

  @override
  void dispose() {
    SosAlertService.instance.activeAlertNotifier.removeListener(_onAlertChanged);
    SosAlertService.instance.isSirenPlayingNotifier.removeListener(_onSirenChanged);
    SosAlertService.instance.isMutedNotifier.removeListener(_onMuteChanged);
    super.dispose();
  }
}
