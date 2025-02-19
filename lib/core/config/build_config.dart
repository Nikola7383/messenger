import 'package:flutter/foundation.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';

enum BuildType {
  regular,  // Običan korisnik
  network,  // Master Admin, Seed, Glasnik
  secret,   // Secret Master
}

class BuildConfig {
  static const _buildType = String.fromEnvironment(
    'BUILD_TYPE',
    defaultValue: 'regular',
  );

  static const _securityLevel = int.fromEnvironment(
    'SECURITY_LEVEL',
    defaultValue: 1,
  );

  static BuildType get buildType {
    switch (_buildType) {
      case 'network':
        return BuildType.network;
      case 'secret':
        return BuildType.secret;
      default:
        return BuildType.regular;
    }
  }

  static bool get isRegularBuild => buildType == BuildType.regular;
  static bool get isNetworkBuild => buildType == BuildType.network;
  static bool get isSecretBuild => buildType == BuildType.secret;

  // Funkcionalnosti po build tipu
  static bool get enableMeshNetwork => !isRegularBuild;
  static bool get enableAdmin => !isRegularBuild;
  static bool get enableFullMenu => !isRegularBuild;
  static bool get enableSecurityFeatures => !isRegularBuild;
  static bool get enableAdvancedAnalytics => !isRegularBuild;

  // Security level kontrole
  static bool get requirePhoneVerification => isRegularBuild;
  static bool get requireChainVerification => !isRegularBuild;
  static bool get enableAntiTampering => !isRegularBuild;
  static bool get enableAntiDebugging => !isRegularBuild;
  static bool get enableRootDetection => !isRegularBuild;

  // Dozvoljene uloge po build tipu
  static bool isRoleAllowed(UserRole role) {
    switch (buildType) {
      case BuildType.regular:
        return role == UserRole.regular || role == UserRole.guest;
      case BuildType.network:
        return role == UserRole.masterAdmin || 
               role == UserRole.seed || 
               role == UserRole.glasnik;
      case BuildType.secret:
        return role == UserRole.secretMaster;
    }
  }

  // Security provere
  static bool get isDebugMode => kDebugMode;
  static bool get isProfileMode => kProfileMode;
  static bool get isReleaseMode => kReleaseMode;

  // Obfuskacija
  static const bool enableObfuscation = true;
  static const bool enableStringEncryption = true;
  static const bool enableCodeSigning = true;

  // Dodatne security mere za network i secret buildove
  static bool get enableExtraSecurityMeasures => 
    isNetworkBuild || isSecretBuild;

  static bool get enableMaximumSecurity => isSecretBuild;

  // Validacija build integriteta
  static bool validateBuildIntegrity() {
    if (isDebugMode && (isNetworkBuild || isSecretBuild)) {
      // Ne dozvoli debug mode za network i secret buildove
      return false;
    }

    if (!isRoleAllowed(UserRole.regular) && isRegularBuild) {
      // Ne dozvoli admin uloge u regular buildu
      return false;
    }

    if (isSecretBuild && _securityLevel < 3) {
      // Secret build mora imati najviši security level
      return false;
    }

    return true;
  }

  // Runtime provere
  static bool validateRuntime() {
    if (enableAntiDebugging && isDebuggerAttached()) {
      return false;
    }

    if (enableRootDetection && isDeviceRooted()) {
      return false;
    }

    if (enableAntiTampering && isAppTampered()) {
      return false;
    }

    return true;
  }

  // Security helper metode
  static bool isDebuggerAttached() {
    // TODO: Implementirati stvarnu detekciju debugger-a
    return false;
  }

  static bool isDeviceRooted() {
    // TODO: Implementirati stvarnu detekciju root-a
    return false;
  }

  static bool isAppTampered() {
    // TODO: Implementirati stvarnu detekciju tampering-a
    return false;
  }
} 