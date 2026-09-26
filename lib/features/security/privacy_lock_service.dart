/// 隐私锁服务
/// 使用 local_auth 进行生物识别（指纹/面容）或设备密码验证
library;

import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

import '../../core/i18n/i18n.dart';
/// 隐私锁服务
class PrivacyLockService {
  PrivacyLockService();

  final LocalAuthentication _auth = LocalAuthentication();

  /// 检查设备是否支持生物识别
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// 获取可用的生物识别类型
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// 发起身份验证
  /// 返回 true 表示验证通过，false 表示验证失败或取消
  Future<bool> authenticate() async {
    try {
      final isAuthenticated = await _auth.authenticate(
        localizedReason: '请验证身份以解锁寻渊'.tr,
        options: const AuthenticationOptions(
          biometricOnly: false, // 允许使用设备密码/PIN
          useErrorDialogs: true,
          stickyAuth: true,
        ),
        authMessages: [
          AndroidAuthMessages(
            signInTitle: '解锁寻渊'.tr,
            biometricHint: '验证指纹或面容'.tr,
            biometricNotRecognized: '未识别，请重试'.tr,
            biometricSuccess: '验证成功'.tr,
            cancelButton: '取消'.tr,
            deviceCredentialsRequiredTitle: '需要设备凭据'.tr,
            deviceCredentialsSetupDescription: '请先设置设备锁屏密码'.tr,
            goToSettingsButton: '去设置'.tr,
            goToSettingsDescription: '请在系统设置中启用生物识别'.tr,
          ),
          IOSAuthMessages(
            lockOut: '验证次数过多，请稍后重试'.tr,
            cancelButton: '取消'.tr,
            goToSettingsButton: '去设置'.tr,
            goToSettingsDescription: '请在系统设置中启用 Face ID / Touch ID'.tr,
            localizedFallbackTitle: '使用密码'.tr,
          ),
        ],
      );
      return isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  /// 停止验证（取消当前验证会话）
  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {
      // 忽略
    }
  }
}
