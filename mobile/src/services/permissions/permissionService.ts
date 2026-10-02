import { Platform, PermissionsAndroid } from 'react-native';

export interface PermissionStatusResult {
  granted: boolean;
  canAskAgain: boolean;
  rationaleRequired?: boolean;
}

export class PermissionService {
  /**
   * Request Bluetooth / Nearby Devices permissions progressively.
   * On Android 12+ (API 31+), requests BLUETOOTH_SCAN, BLUETOOTH_ADVERTISE, BLUETOOTH_CONNECT.
   * On Android 8-11, requests ACCESS_FINE_LOCATION as required by hardware BLE scanning.
   */
  public async requestNearbyDevicesPermission(): Promise<PermissionStatusResult> {
    if (Platform.OS !== 'android') {
      return { granted: true, canAskAgain: true };
    }

    try {
      if (Platform.Version >= 31) {
        const statuses = await PermissionsAndroid.requestMultiple([
          PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN,
          PermissionsAndroid.PERMISSIONS.BLUETOOTH_ADVERTISE,
          PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT,
        ]);

        const allGranted =
          statuses[PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN] === PermissionsAndroid.RESULTS.GRANTED &&
          statuses[PermissionsAndroid.PERMISSIONS.BLUETOOTH_ADVERTISE] === PermissionsAndroid.RESULTS.GRANTED &&
          statuses[PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT] === PermissionsAndroid.RESULTS.GRANTED;

        return {
          granted: allGranted,
          canAskAgain: true,
        };
      } else {
        const status = await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
          {
            title: 'Nearby Device Discovery',
            message: 'Android requires location permission to detect nearby Bluetooth devices when offline.',
            buttonPositive: 'Allow',
            buttonNegative: 'Not Now',
          }
        );

        return {
          granted: status === PermissionsAndroid.RESULTS.GRANTED,
          canAskAgain: status !== PermissionsAndroid.RESULTS.NEVER_ASK_AGAIN,
        };
      }
    } catch (err) {
      console.warn('[PermissionService] Failed to request permissions', err);
      return { granted: false, canAskAgain: true };
    }
  }

  public async checkNearbyDevicesPermission(): Promise<boolean> {
    if (Platform.OS !== 'android') return true;

    try {
      if (Platform.Version >= 31) {
        const scan = await PermissionsAndroid.check(PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN);
        const advertise = await PermissionsAndroid.check(PermissionsAndroid.PERMISSIONS.BLUETOOTH_ADVERTISE);
        const connect = await PermissionsAndroid.check(PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT);
        return scan && advertise && connect;
      } else {
        return await PermissionsAndroid.check(PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION);
      }
    } catch {
      return false;
    }
  }
}

export const permissionService = new PermissionService();
