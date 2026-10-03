/// 媒体相册页
/// 按家族展示所有照片，支持查看大图和删除
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../family/domain/family_providers.dart';
import '../domain/media_providers.dart';

import '../../../core/i18n/i18n.dart';
/// 媒体相册页
class MediaGalleryPage extends ConsumerStatefulWidget {
  const MediaGalleryPage({super.key, this.initialTreeId});

  /// 初始选中的家族 ID（可选）
  final int? initialTreeId;

  @override
  ConsumerState<MediaGalleryPage> createState() => _MediaGalleryPageState();
}

class _MediaGalleryPageState extends ConsumerState<MediaGalleryPage> {
  int? _selectedTreeId;

  @override
  void initState() {
    super.initState();
    _selectedTreeId = widget.initialTreeId;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final familiesAsync = ref.watch(watchFamiliesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('家族相册'.tr),
        actions: [
          // 家族筛选（多家族时显示）
          familiesAsync.when(
            data: (families) {
              if (families.length <= 1) return const SizedBox.shrink();
              return PopupMenuButton<int?>(
                icon: const Icon(Icons.filter_list),
                tooltip: '按家族筛选'.tr,
                initialValue: _selectedTreeId,
                onSelected: (v) => setState(() => _selectedTreeId = v),
                itemBuilder: (context) => [
                  PopupMenuItem<int?>(
                    value: null,
                    child: Text('全部家族'.tr),
                  ),
                  ...families.map((f) => PopupMenuItem<int?>(
                        value: f.id,
                        child: Text(f.name),
                      )),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: _selectedTreeId != null
          ? _buildGallery(_selectedTreeId!, isDark)
          : _buildAllFamiliesGallery(isDark),
    );
  }

  /// 单个家族的相册
  Widget _buildGallery(int treeId, bool isDark) {
    final mediaAsync = ref.watch(mediaByTreeProvider(treeId));

    return mediaAsync.when(
      data: (mediaList) {
        if (mediaList.isEmpty) {
          return _buildEmptyState(isDark);
        }
        return _buildGrid(mediaList, isDark);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('加载失败：$error'.tr, style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  /// 全部家族的相册（合并显示）
  Widget _buildAllFamiliesGallery(bool isDark) {
    final familiesAsync = ref.watch(watchFamiliesProvider);

    return familiesAsync.when(
      data: (families) {
        if (families.isEmpty) {
          return _buildEmptyState(isDark);
        }
        // 合并所有家族的媒体
        return FutureBuilder<List<MediaTableData>>(
          future: _loadAllMedia(families.map((f) => f.id).toList()),
          builder: (context, snapshot) {
            // 必须先判 error：只判 !hasData 会让 future 抛错时永远转圈
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '相册加载失败：${snapshot.error}'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final mediaList = snapshot.data!;
            if (mediaList.isEmpty) {
              return _buildEmptyState(isDark);
            }
            return _buildGrid(mediaList, isDark);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('加载失败：$error'.tr, style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  /// 加载所有家族的媒体
  Future<List<MediaTableData>> _loadAllMedia(List<int> treeIds) async {
    final repo = ref.read(mediaRepositoryProvider);
    final allMedia = <MediaTableData>[];
    for (final treeId in treeIds) {
      final media = await repo.watchMediaByTree(treeId).first;
      allMedia.addAll(media);
    }
    // 按创建时间倒序
    allMedia.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allMedia;
  }

  /// 网格布局
  Widget _buildGrid(List<MediaTableData> mediaList, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: mediaList.length,
      itemBuilder: (context, index) {
        final media = mediaList[index];
        return _MediaThumbnail(
          media: media,
          onTap: () => _viewImage(media),
          onLongPress: () => _confirmDelete(media),
        );
      },
    );
  }

  /// 查看大图
  void _viewImage(MediaTableData media) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图片
            InteractiveViewer(
              child: Image.file(
                File(media.path),
                fit: BoxFit.contain,
              ),
            ),
            // 说明文字
            if (media.caption != null && media.caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  media.caption!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            // 操作按钮
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(media);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text('删除'.tr, style: const TextStyle(color: Colors.red)),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: Text('关闭'.tr, style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 确认删除
  Future<void> _confirmDelete(MediaTableData media) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除照片'.tr),
        content: Text('确定要删除这张照片吗？此操作不可恢复。'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text('删除'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(mediaRepositoryProvider).deleteMedia(media.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('照片已删除'.tr)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败：$e'.tr), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  /// 空状态
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: isDark ? Colors.grey : AppColors.inkLightGray,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无照片'.tr,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey : AppColors.inkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在成员详情页添加头像或照片'.tr,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey : AppColors.inkGray,
            ),
          ),
        ],
      ),
    );
  }
}

/// 媒体缩略图
class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({
    required this.media,
    required this.onTap,
    required this.onLongPress,
  });

  final MediaTableData media;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(media.path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
            // 说明文字渐变遮罩
            if (media.caption != null && media.caption!.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    ),
                  ),
                  child: Text(
                    media.caption!,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
