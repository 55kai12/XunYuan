/// 隐私锁屏组件
/// 当隐私锁启用时包裹整个应用，需要生物识别或密码验证才能进入
/// 应用从后台恢复时自动重新锁定
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../privacy_lock_service.dart';

import '../../../core/i18n/i18n.dart';
/// 隐私锁服务 Provider
final privacyLockServiceProvider = Provider<PrivacyLockService>((ref) {
  return PrivacyLockService();
});

/// 锁屏组件
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with WidgetsBindingObserver {
  bool _isLocked = true;
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 启动时自动尝试验证
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 应用从后台恢复时重新锁定
    if (state == AppLifecycleState.resumed && !_isLocked) {
      setState(() {
        _isLocked = true;
        _errorMessage = null;
      });
    }
  }

  /// 发起身份验证
  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final service = ref.read(privacyLockServiceProvider);
    final success = await service.authenticate();

    if (!mounted) return;
    setState(() {
      _isAuthenticating = false;
      if (success) {
        _isLocked = false;
      } else {
        _errorMessage = '验证失败，请重试'.tr;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A2E28), const Color(0xFF0D1A17)]
                : [const Color(0xFFE8E0D0), const Color(0xFFD4C9B5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 应用图标
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.inkGreen, AppColors.inkGreenDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.inkGreen.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '渊'.tr,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: isDark ? Colors.white : AppColors.inkBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.slogan,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey : AppColors.inkGray,
                  ),
                ),
                const SizedBox(height: 48),
                // 锁图标
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: isDark ? Colors.grey : AppColors.inkGray,
                ),
                const SizedBox(height: 16),
                Text(
                  '应用已锁定'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey : AppColors.inkGray,
                  ),
                ),
                const SizedBox(height: 32),
                // 解锁按钮
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    icon: _isAuthenticating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.fingerprint, size: 22),
                    label: Text(_isAuthenticating ? '验证中…'.tr : '点击解锁'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.inkGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
