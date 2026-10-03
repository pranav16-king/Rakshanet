class RadioScanProfile {
  final String mode; // 'NORMAL', 'LOW_POWER', 'CRITICAL'
  final int scanSec;
  final int intervalSec;
  final String dutyCycle;

  const RadioScanProfile({
    required this.mode,
    required this.scanSec,
    required this.intervalSec,
    required this.dutyCycle,
  });

  factory RadioScanProfile.fromBattery(int battery) {
    if (battery > 50) {
      return const RadioScanProfile(
        mode: 'NORMAL',
        scanSec: 5,
        intervalSec: 25,
        dutyCycle: '20%',
      );
    } else if (battery >= 20) {
      return const RadioScanProfile(
        mode: 'LOW_POWER',
        scanSec: 3,
        intervalSec: 60,
        dutyCycle: '5%',
      );
    } else {
      return const RadioScanProfile(
        mode: 'CRITICAL',
        scanSec: 2,
        intervalSec: 180,
        dutyCycle: '1.1%',
      );
    }
  }
}

class TelemetryModel {
  final int meshCount;
  final int batteryLevel;
  final bool isOnline;
  final bool hasGpsFix;
  final RadioScanProfile radioScanProfile;

  TelemetryModel({
    this.meshCount = 0,
    this.batteryLevel = 0,
    this.isOnline = false,
    this.hasGpsFix = false,
    RadioScanProfile? radioScanProfile,
  }) : radioScanProfile = radioScanProfile ?? RadioScanProfile.fromBattery(batteryLevel);

  TelemetryModel copyWith({
    int? meshCount,
    int? batteryLevel,
    bool? isOnline,
    bool? hasGpsFix,
    RadioScanProfile? radioScanProfile,
  }) {
    final newBattery = batteryLevel ?? this.batteryLevel;
    return TelemetryModel(
      meshCount: meshCount ?? this.meshCount,
      batteryLevel: newBattery,
      isOnline: isOnline ?? this.isOnline,
      hasGpsFix: hasGpsFix ?? this.hasGpsFix,
      radioScanProfile: radioScanProfile ?? RadioScanProfile.fromBattery(newBattery),
    );
  }
}
