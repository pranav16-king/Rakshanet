import 'package:flutter_test/flutter_test.dart';
import 'package:rakshanet_mobile/models/mesh_device.dart';
import 'package:rakshanet_mobile/models/remote_user_profile.dart';

void main() {
  test('nearby profile retains a stable app device ID but does not expose it as display text', () {
    final profile = RemoteUserProfile.fromMeshDevice(
      MeshDevice(
        id: 'endpoint-7',
        deviceId: 'stable-peer-id',
        displayName: 'Asha Rao',
        signalStrength: -60,
        lastSeen: DateTime(2026, 1, 1),
      ),
    );

    expect(profile.userId, 'stable-peer-id');
    expect(profile.displayName, 'Asha Rao');
    expect(profile.initials, 'AR');
    expect(profile.source, 'Nearby mesh');
  });
}
