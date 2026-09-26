/// 首次启动引导页
/// 3 页介绍：品牌欢迎、核心功能、本地优先
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/settings/settings_providers.dart';

import '../../../core/i18n/i18n.dart';
/// 引导页
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 完成引导，进入主界面
  Future<void> _finishOnboarding() async {
    await ref.read(onboardingProvider.notifier).complete();
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A2E28), const Color(0xFF0D1A17)]
                : [const Color(0xFFF5F0E8), const Color(0xFFE8E0D0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 跳过按钮
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    '跳过'.tr,
                    style: TextStyle(
                      color: isDark ? Colors.grey : AppColors.inkGray,
                    ),
                  ),
                ),
              ),

              // 页面内容
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: [
                    _buildPage1(isDark),
                    _buildPage2(isDark),
                    _buildPage3(isDark),
                  ],
                ),
              ),

              // 指示器 + 按钮
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    // 页面指示器
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_totalPages, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColors.inkGreen
                                : AppColors.inkLightGray,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    // 下一页/开始使用按钮
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _totalPages - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _finishOnboarding();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.inkGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _currentPage < _totalPages - 1 ? '下一步'.tr : '开始使用'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 第 1 页：品牌欢迎
  Widget _buildPage1(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 应用图标
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.inkGreen, AppColors.inkGreenDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.inkGreen.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '渊'.tr,
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
            color: isDark ? Colors.white : AppColors.inkBlack,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppConstants.slogan,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey : AppColors.inkGray,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            '记录家族成员、世系关系、字辈堂号，\n让家族故事渊远流长。'.tr,
            style: TextStyle(
              fontSize: 14,
              height: 1.8,
              color: isDark ? Colors.grey : AppColors.inkGray,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// 第 2 页：核心功能
  Widget _buildPage2(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.account_tree,
          size: 80,
          color: AppColors.inkGreen,
        ),
        const SizedBox(height: 32),
        Text(
          '族谱可视化'.tr,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.inkBlack,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              _featureRow(Icons.family_restroom, '完整记录成员信息'.tr, isDark),
              const SizedBox(height: 12),
              _featureRow(Icons.zoom_out_map, '族谱树缩放平移'.tr, isDark),
              const SizedBox(height: 12),
              _featureRow(Icons.search, '多条件搜索筛选'.tr, isDark),
              const SizedBox(height: 12),
              _featureRow(Icons.timeline, '人生事件时间线'.tr, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _featureRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.inkGreen),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.grey : AppColors.inkBlack,
          ),
        ),
      ],
    );
  }

  /// 第 3 页：本地优先
  Widget _buildPage3(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.security,
          size: 80,
          color: AppColors.inkGreen,
        ),
        const SizedBox(height: 32),
        Text(
          '本地优先'.tr,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.inkBlack,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              _featureRow(Icons.cloud_off, '数据存储在本地，无需联网'.tr, isDark),
              const SizedBox(height: 12),
              _featureRow(Icons.lock, '隐私锁保护，指纹解锁'.tr, isDark),
              const SizedBox(height: 12),
              _featureRow(Icons.backup, 'JSON 备份与恢复'.tr, isDark),
              const SizedBox(height: 12),
              _featureRow(Icons.swap_horiz, 'GEDCOM 格式互导'.tr, isDark),
              const SizedBox(height: 12),
              _featureRow(Icons.picture_as_pdf, '导出 PNG / PDF'.tr, isDark),
            ],
          ),
        ),
      ],
    );
  }
}
