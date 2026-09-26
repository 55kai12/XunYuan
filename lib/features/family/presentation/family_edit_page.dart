/// 创建 / 编辑家族页
/// 阶段 2：家族表单（名称、姓氏、堂号、郡望、字辈、简介）
/// 支持新增与编辑两种模式，表单校验 + 友好错误提示
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/hint_text_field.dart';
import '../../../shared/widgets/notepad_editor.dart';
import '../../person/domain/person_providers.dart';
import '../domain/family_providers.dart';

import '../../../core/i18n/i18n.dart';
/// 家族编辑页
/// 通过路由参数 [editId] 区分模式：
/// - 无 editId：新建家族
/// - 有 editId：编辑现有家族
class FamilyEditPage extends ConsumerStatefulWidget {
  const FamilyEditPage({super.key, this.editId});

  /// 编辑模式下的家族 ID（新建模式为 null）
  final int? editId;

  @override
  ConsumerState<FamilyEditPage> createState() => _FamilyEditPageState();
}

class _FamilyEditPageState extends ConsumerState<FamilyEditPage> {
  final _formKey = GlobalKey<FormState>();

  // 表单控制器
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _hallNameController;
  late final TextEditingController _originController;
  late final TextEditingController _generationWordsController;
  late final NotepadController _descriptionController;

  bool _isLoading = true; // 编辑模式加载中
  bool _isSaving = false; // 保存中

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _surnameController = TextEditingController();
    _hallNameController = TextEditingController();
    _originController = TextEditingController();
    _generationWordsController = TextEditingController();
    _descriptionController = NotepadController();

    // 编辑模式：加载家族数据填充表单
    if (widget.editId != null) {
      _loadFamily();
    } else {
      _isLoading = false;
    }
  }

  /// 加载家族数据到表单
  Future<void> _loadFamily() async {
    try {
      final repo = ref.read(familyRepositoryProvider);
      final family = await repo.getById(widget.editId!);
      if (!mounted) return;
      if (family == null) {
        _showError('家族不存在或已被删除'.tr);
        context.pop();
        return;
      }
      _nameController.text = family.name;
      _surnameController.text = family.surname;
      _hallNameController.text = family.hallName ?? '';
      _originController.text = family.origin ?? '';
      _generationWordsController.text = family.generationWords ?? '';
      _descriptionController.load(family.description);
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      _showError('加载家族失败：$e'.tr);
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _hallNameController.dispose();
    _originController.dispose();
    _generationWordsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 表单校验并保存
  Future<void> _save() async {
    // 校验表单
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(familyRepositoryProvider);
      final name = _nameController.text.trim();
      final surname = _surnameController.text.trim();
      final hallName = _trimOrNull(_hallNameController.text);
      final origin = _trimOrNull(_originController.text);
      final generationWords = _trimOrNull(_generationWordsController.text);
      final description = _trimOrNull(_descriptionController.text);

      if (widget.editId == null) {
        // 新建家族
        final newId = await repo.insert(
          name: name,
          surname: surname,
          hallName: hallName,
          origin: origin,
          generationWords: generationWords,
          description: description,
        );
        if (!mounted) return;

        // 自动创建始迁祖（第一位成员）
        try {
          final personRepo = ref.read(personRepositoryProvider);
          await personRepo.insert(
            treeId: newId,
            surname: surname,
            givenName: '始迁祖'.tr,
            gender: Gender.male,
            generation: 1,
            isAlive: true,
          );
        } catch (_) {
          // 始迁祖创建失败不阻塞流程
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('家族创建成功，已自动添加始迁祖'.tr)),
        );
        // 进入家族首页（pushReplacement 保留来路导航栈，返回键可回）
        context.pushReplacement('/family/$newId');
      } else {
        // 更新家族
        final success = await repo.update(
          id: widget.editId!,
          name: name,
          surname: surname,
          hallName: hallName,
          origin: origin,
          generationWords: generationWords,
          description: description,
        );
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('家族信息已保存'.tr)),
          );
          context.pop();
        } else {
          _showError('保存失败：家族不存在或已被删除'.tr);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError('保存失败：$e'.tr);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// 空字符串转为 null
  String? _trimOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// 友好错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editId == null ? '创建家族'.tr : '编辑家族'.tr),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 名称 + 姓氏
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: HintTextField(
                          controller: _nameController,
                          maxLength: 100,
                          label: '家族名称 *'.tr,
                          hint: '例如：颍川陈氏宗族'.tr,
                          prefixIcon: const Icon(Icons.home_work_outlined),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入家族名称'.tr;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: HintTextField(
                          controller: _surnameController,
                          maxLength: 50,
                          label: '姓氏 *'.tr,
                          hint: '例如：陈'.tr,
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入姓氏'.tr;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 堂号 + 郡望
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: HintTextField(
                          controller: _hallNameController,
                          maxLength: 50,
                          label: '堂号'.tr,
                          hint: '例如：三槐堂'.tr,
                          prefixIcon: const Icon(Icons.museum_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HintTextField(
                          controller: _originController,
                          maxLength: 100,
                          label: '郡望'.tr,
                          hint: '例如：颍川'.tr,
                          prefixIcon: const Icon(Icons.place_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 字辈
                  HintTextField(
                    controller: _generationWordsController,
                    maxLength: 500,
                    maxLines: 2,
                    label: '字辈'.tr,
                    hint: '用顿号或空格分隔，例如：忠、孝、传、家'.tr,
                    prefixIcon: const Icon(Icons.format_list_numbered),
                  ),
                  const SizedBox(height: 16),

                  // 简介（记事本式图文编辑）
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '家族简介'.tr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkBlack,
                      ),
                    ),
                  ),
                  NotepadEditor(
                    controller: _descriptionController,
                    hintText: '介绍家族的历史渊源、迁徙历程、重要人物等'.tr,
                  ),
                  const SizedBox(height: 24),

                  // 保存按钮
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.editId == null ? '创建家族'.tr : '保存修改'.tr),
                  ),
                  const SizedBox(height: 16),

                  // 取消按钮
                  OutlinedButton(
                    onPressed:
                        _isSaving ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text('取消'.tr),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
