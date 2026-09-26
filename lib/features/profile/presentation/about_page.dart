/// 关于寻渊页
/// 展示应用信息、版本、功能介绍、开源声明
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

import '../../../core/i18n/i18n.dart';
/// 关于寻渊页
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('关于寻渊'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 32),
          // 应用图标
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.inkGreen, AppColors.inkGreenDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.inkGreen.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '渊'.tr,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    letterSpacing: 4,
                    color: isDark
                        ? AppColors.darkOnSurface
                        : AppColors.inkBlack,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '版本 ${AppConstants.version} (${AppConstants.buildNumber})'.tr,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey : AppColors.inkGray,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              AppConstants.slogan,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey : AppColors.inkGray,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 应用简介
          _buildSection(
            context,
            title: '应用简介'.tr,
            child: Text(
              '寻渊是一款本地优先的中文族谱工具，'.tr +
              '帮助您记录家族成员、世系关系、字辈堂号、'.tr +
              '生卒婚葬与家族故事。所有数据存储在本地设备，'.tr +
              '无需联网，保护隐私。'.tr,
              style: const TextStyle(fontSize: 14, height: 1.7),
            ),
          ),

          // 核心功能
          _buildSection(
            context,
            title: '核心功能'.tr,
            child: Column(
              children: [
                _FeatureRow(icon: Icons.family_restroom, text: '家族管理：创建多个家族，记录堂号郡望字辈'.tr),
                _FeatureRow(icon: Icons.person, text: '成员管理：完整记录姓名字号、生卒婚葬、生平简介'.tr),
                _FeatureRow(icon: Icons.account_tree, text: '族谱树：可视化世系关系，支持缩放平移'.tr),
                _FeatureRow(icon: Icons.timeline, text: '事件时间线：记录出生、结婚、迁徙、功名等大事'.tr),
                _FeatureRow(icon: Icons.backup, text: '备份恢复：JSON 全量备份，数据安全可控'.tr),
                _FeatureRow(icon: Icons.picture_as_pdf, text: '导出分享：族谱 PNG 截图、家族 PDF 名册'.tr),
              ],
            ),
          ),

          // 技术信息
          _buildSection(
            context,
            title: '技术信息'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: '包名'.tr, value: AppConstants.packageName),
                _InfoRow(label: '英文名'.tr, value: AppConstants.appNameEn),
                _InfoRow(label: '技术栈'.tr, value: 'Flutter + Dart'),
                _InfoRow(label: '数据库'.tr, value: 'SQLite (Drift)'),
                _InfoRow(label: '数据存储'.tr, value: '本地优先，离线可用'.tr),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              '© 2024 ${AppConstants.appName}\n本地优先 · 离线可用 · 隐私保护'.tr,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey : AppColors.inkGray,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.inkGreen,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.inkGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey : AppColors.inkGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
