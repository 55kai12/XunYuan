/// 添加 / 编辑成员页
/// 阶段 3：成员表单（基本信息、生卒婚葬、职业功名、简介、头像）
/// 支持新增与编辑两种模式，表单校验 + 日期选择器 + 头像选择
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/hint_text_field.dart';
import '../../../shared/widgets/notepad_editor.dart';
import '../../family/domain/family_providers.dart';
import '../../media/domain/media_providers.dart';
import '../domain/person_providers.dart';

import '../../../core/i18n/i18n.dart';
/// 成员编辑页
class PersonEditPage extends ConsumerStatefulWidget {
  const PersonEditPage({super.key, this.editId, this.initialTreeId});

  /// 编辑模式下的成员 ID
  final int? editId;

  /// 新建时预设的家族 ID（从家族首页进入时传入）
  final int? initialTreeId;

  @override
  ConsumerState<PersonEditPage> createState() => _PersonEditPageState();
}

class _PersonEditPageState extends ConsumerState<PersonEditPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // 表单控制器
  late final TextEditingController _surnameController;
  late final TextEditingController _givenNameController;
  late final TextEditingController _courtesyNameController;
  late final TextEditingController _artNameController;
  late final TextEditingController _generationController;
  late final TextEditingController _generationWordController;
  late final TextEditingController _branchController;
  late final TextEditingController _rankController;
  late final TextEditingController _birthPlaceController;
  late final TextEditingController _deathPlaceController;
  late final TextEditingController _burialPlaceController;
  late final TextEditingController _occupationController;
  late final TextEditingController _titleController;
  late final NotepadController _biographyController;

  // 表单状态
  int? _selectedTreeId;
  Gender _gender = Gender.male;
  DateTime? _birthDate;
  DateTime? _deathDate;
  bool _isAlive = true;
  int? _avatarMediaId;
  int? _originalAvatarMediaId; // 编辑模式加载时的原头像（保存成功后按需清理）
  File? _avatarPreview; // 本地预览文件

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _surnameController = TextEditingController();
    _givenNameController = TextEditingController();
    _courtesyNameController = TextEditingController();
    _artNameController = TextEditingController();
    _generationController = TextEditingController();
    _generationWordController = TextEditingController();
    _branchController = TextEditingController();
    _rankController = TextEditingController();
    _birthPlaceController = TextEditingController();
    _deathPlaceController = TextEditingController();
    _burialPlaceController = TextEditingController();
    _occupationController = TextEditingController();
    _titleController = TextEditingController();
    _biographyController = NotepadController();

    _selectedTreeId = widget.initialTreeId;

    if (widget.editId != null) {
      _loadPerson();
    } else {
      _isLoading = false;
    }
  }

  /// 加载成员数据到表单
  Future<void> _loadPerson() async {
    try {
      final repo = ref.read(personRepositoryProvider);
      final person = await repo.getById(widget.editId!);
      if (!mounted) return;
      if (person == null) {
        _showError('成员不存在或已被删除'.tr);
        context.pop();
        return;
      }
      _selectedTreeId = person.treeId;
      _surnameController.text = person.surname;
      _givenNameController.text = person.givenName;
      _courtesyNameController.text = person.courtesyName ?? '';
      _artNameController.text = person.artName ?? '';
      _generationController.text =
          person.generation != null ? '${person.generation}' : '';
      _generationWordController.text = person.generationWord ?? '';
      _branchController.text = person.branch ?? '';
      _rankController.text = person.rank != null ? '${person.rank}' : '';
      _birthDate = person.birthDate;
      _deathDate = person.deathDate;
      _isAlive = person.isAlive;
      _birthPlaceController.text = person.birthPlace ?? '';
      _deathPlaceController.text = person.deathPlace ?? '';
      _burialPlaceController.text = person.burialPlace ?? '';
      _occupationController.text = person.occupation ?? '';
      _titleController.text = person.title ?? '';
      _biographyController.load(person.biography);
      _avatarMediaId = person.avatarMediaId;
      _originalAvatarMediaId = person.avatarMediaId;

      // 加载头像预览
      if (person.avatarMediaId != null) {
        final media = await repo.getMediaById(person.avatarMediaId!);
        if (media != null && File(media.path).existsSync()) {
          _avatarPreview = File(media.path);
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      _showError('加载成员失败：$e'.tr);
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _surnameController.dispose();
    _givenNameController.dispose();
    _courtesyNameController.dispose();
    _artNameController.dispose();
    _generationController.dispose();
    _generationWordController.dispose();
    _branchController.dispose();
    _rankController.dispose();
    _birthPlaceController.dispose();
    _deathPlaceController.dispose();
    _burialPlaceController.dispose();
    _occupationController.dispose();
    _titleController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  /// 根据家族字辈序列和世代自动填充字辈
  /// 仅当字辈字段为空时自动填充，避免覆盖用户已输入内容
  void _autoFillGenerationWord() {
    // 字辈字段已有内容则不覆盖
    if (_generationWordController.text.trim().isNotEmpty) return;

    final generation = int.tryParse(_generationController.text.trim());
    if (generation == null || _selectedTreeId == null) return;

    // 从家族列表中找到当前家族的字辈序列
    final families = ref.read(watchFamiliesProvider).valueOrNull ?? [];
    final family = families.where((f) => f.id == _selectedTreeId).firstOrNull;
    if (family == null ||
        family.generationWords == null ||
        family.generationWords!.isEmpty) return;

    // 解析字辈序列：支持顿号、逗号、空格分隔
    final words = family.generationWords!
        .split(RegExp(r'[、，,\s]+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // 世代从 1 开始，索引为 generation - 1
    if (generation - 1 >= 0 && generation - 1 < words.length) {
      _generationWordController.text = words[generation - 1];
    }
  }

  /// 选择头像
  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (image == null || _selectedTreeId == null) return;

      // 保存到应用目录并插入 Media 记录
      final repo = ref.read(personRepositoryProvider);
      final mediaId = await repo.saveAvatar(
        treeId: _selectedTreeId!,
        sourcePath: image.path,
        caption: '${_surnameController.text}${_givenNameController.text}的头像'.tr,
      );
      if (!mounted) return;
      setState(() {
        _avatarMediaId = mediaId;
        _avatarPreview = File(image.path);
      });
    } catch (e) {
      if (!mounted) return;
      _showError('选择头像失败：$e'.tr);
    }
  }

  /// 选择日期
  Future<void> _pickDate({
    required bool isBirth,
    required DateTime? initialDate,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime(now.year - 30),
      firstDate: DateTime(1200),
      lastDate: now,
      helpText: isBirth ? '选择出生日期'.tr : '选择忌日'.tr,
    );
    if (picked != null) {
      setState(() {
        if (isBirth) {
          _birthDate = picked;
        } else {
          _deathDate = picked;
        }
      });
    }
  }

  /// 保存表单
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(personRepositoryProvider);
      final generation = int.tryParse(_generationController.text.trim());
      final rank = int.tryParse(_rankController.text.trim());

      if (widget.editId == null) {
        // 新增
        final newId = await repo.insert(
          treeId: _selectedTreeId!,
          surname: _surnameController.text.trim(),
          givenName: _givenNameController.text.trim(),
          gender: _gender,
          courtesyName: _trimOrNull(_courtesyNameController.text),
          artName: _trimOrNull(_artNameController.text),
          generation: generation,
          generationWord: _trimOrNull(_generationWordController.text),
          branch: _trimOrNull(_branchController.text),
          rank: rank,
          birthDate: _birthDate,
          deathDate: _isAlive ? null : _deathDate,
          isAlive: _isAlive,
          birthPlace: _trimOrNull(_birthPlaceController.text),
          deathPlace: _trimOrNull(_deathPlaceController.text),
          burialPlace: _trimOrNull(_burialPlaceController.text),
          occupation: _trimOrNull(_occupationController.text),
          title: _trimOrNull(_titleController.text),
          biography: _trimOrNull(_biographyController.text),
          avatarMediaId: _avatarMediaId,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成员添加成功'.tr)),
        );
        // 用 pushReplacement 而非 go：保留来路导航栈，返回键可回列表
        context.pushReplacement('/person/$newId');
      } else {
        // 更新
        final success = await repo.update(
          id: widget.editId!,
          treeId: _selectedTreeId,
          surname: _surnameController.text.trim(),
          givenName: _givenNameController.text.trim(),
          gender: _gender,
          courtesyName: _trimOrNull(_courtesyNameController.text),
          artName: _trimOrNull(_artNameController.text),
          generation: generation,
          generationWord: _trimOrNull(_generationWordController.text),
          branch: _trimOrNull(_branchController.text),
          rank: rank,
          birthDate: _birthDate,
          deathDate: _isAlive ? null : _deathDate,
          isAlive: _isAlive,
          birthPlace: _trimOrNull(_birthPlaceController.text),
          deathPlace: _trimOrNull(_deathPlaceController.text),
          burialPlace: _trimOrNull(_burialPlaceController.text),
          occupation: _trimOrNull(_occupationController.text),
          title: _trimOrNull(_titleController.text),
          biography: _trimOrNull(_biographyController.text),
          avatarMediaId: _avatarMediaId,
        );
        if (!mounted) return;
        if (success) {
          // 保存成功，此时正文里已不再引用的配图可以安全删盘。
          // 不 await：删盘结果不影响界面，避免在 context 使用前插入异步间隙。
          unawaited(_biographyController.commitPendingDeletions());
          // 换了头像：旧头像媒体记录和文件已无引用，清理掉
          final oldAvatarId = _originalAvatarMediaId;
          if (oldAvatarId != null && oldAvatarId != _avatarMediaId) {
            try {
              await ref.read(mediaRepositoryProvider).deleteMedia(oldAvatarId);
            } catch (_) {
              // 清理失败不影响保存结果
            }
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成员信息已保存'.tr)),
          );
          context.pop();
        } else {
          _showError('保存失败：成员不存在或已被删除'.tr);
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

  String? _trimOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

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
    final familiesAsync = ref.watch(watchFamiliesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editId == null ? '添加成员'.tr : '编辑成员'.tr),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 头像 + 家族选择
                  _buildAvatarAndFamily(familiesAsync),
                  const SizedBox(height: 20),

                  // 基本信息
                  _buildSectionTitle('基本信息'.tr),
                  Row(
                    children: [
                      Expanded(
                        child: HintTextField(
                          controller: _surnameController,
                          maxLength: 50,
                          label: '姓 *'.tr,
                          hint: '例如：陈'.tr,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? '请输入姓'.tr : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HintTextField(
                          controller: _givenNameController,
                          maxLength: 50,
                          label: '名 *'.tr,
                          hint: '例如：三'.tr,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? '请输入名'.tr : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: HintTextField(
                          controller: _courtesyNameController,
                          maxLength: 50,
                          label: '字'.tr,
                          hint: '例如：子安'.tr,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HintTextField(
                          controller: _artNameController,
                          maxLength: 50,
                          label: '号'.tr,
                          hint: '例如：东坡居士'.tr,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 性别选择
                  _buildGenderSelector(),
                  const SizedBox(height: 16),

                  // 世代字辈房支排行
                  Row(
                    children: [
                      Expanded(
                        child: HintTextField(
                          controller: _generationController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          label: '世代'.tr,
                          hint: '第几世'.tr,
                          onChanged: (_) => _autoFillGenerationWord(),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            return int.tryParse(v.trim()) == null
                                ? '请输入数字'.tr
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HintTextField(
                          controller: _generationWordController,
                          maxLength: 50,
                          label: '字辈'.tr,
                          hint: '例如：忠'.tr,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: HintTextField(
                          controller: _branchController,
                          maxLength: 50,
                          label: '房支'.tr,
                          hint: '例如：长房'.tr,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HintTextField(
                          controller: _rankController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          label: '排行'.tr,
                          hint: '第几'.tr,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            return int.tryParse(v.trim()) == null
                                ? '请输入数字'.tr
                                : null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 生卒婚葬
                  _buildSectionTitle('生卒婚葬'.tr),
                  // 在世开关
                  SwitchListTile(
                    title: Text('是否在世'.tr),
                    value: _isAlive,
                    activeColor: AppColors.inkGreen,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _isAlive = v),
                  ),
                  const SizedBox(height: 8),
                  // 生日
                  _buildDateField(
                    label: '生日'.tr,
                    date: _birthDate,
                    onTap: () => _pickDate(isBirth: true, initialDate: _birthDate),
                  ),
                  const SizedBox(height: 12),
                  // 忌日（仅已故时显示）
                  if (!_isAlive)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDateField(
                        label: '忌日'.tr,
                        date: _deathDate,
                        onTap: () => _pickDate(
                            isBirth: false, initialDate: _deathDate),
                      ),
                    ),
                  HintTextField(
                    controller: _birthPlaceController,
                    maxLength: 200,
                    label: '出生地'.tr,
                    prefixIcon: const Icon(Icons.place_outlined),
                  ),
                  const SizedBox(height: 12),
                  if (!_isAlive) ...[
                    HintTextField(
                      controller: _deathPlaceController,
                      maxLength: 200,
                      label: '去世地'.tr,
                      prefixIcon: const Icon(Icons.place_outlined),
                    ),
                    const SizedBox(height: 12),
                    HintTextField(
                      controller: _burialPlaceController,
                      maxLength: 200,
                      label: '葬地'.tr,
                      prefixIcon: const Icon(Icons.location_city_outlined),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 职业功名
                  _buildSectionTitle('职业功名'.tr),
                  HintTextField(
                    controller: _occupationController,
                    maxLength: 200,
                    label: '职业'.tr,
                    prefixIcon: const Icon(Icons.work_outline),
                  ),
                  const SizedBox(height: 12),
                  HintTextField(
                    controller: _titleController,
                    maxLength: 200,
                    label: '功名 / 头衔'.tr,
                    prefixIcon: const Icon(Icons.military_tech_outlined),
                  ),
                  const SizedBox(height: 20),

                  // 简介（记事本式图文编辑）
                  _buildSectionTitle('人物简介'.tr),
                  NotepadEditor(
                    controller: _biographyController,
                    hintText: '记录这位先人的生平事迹、家族故事等'.tr,
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
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(widget.editId == null ? '添加成员'.tr : '保存修改'.tr),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => context.pop(),
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

  /// 头像 + 家族选择
  Widget _buildAvatarAndFamily(AsyncValue<List<FamilyTree>> familiesAsync) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头像
        GestureDetector(
          onTap: _pickAvatar,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.inkGreen.withOpacity(0.1),
                backgroundImage: _avatarPreview != null
                    ? FileImage(_avatarPreview!)
                    : null,
                child: _avatarPreview == null
                    ? const Icon(Icons.person,
                        size: 36, color: AppColors.inkGreen)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.inkGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt,
                      size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // 家族选择
        Expanded(
          child: familiesAsync.when(
            data: (families) {
              if (families.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '暂无家族，请先创建家族'.tr,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                );
              }
              return DropdownButtonFormField<int>(
                value: _selectedTreeId,
                decoration: InputDecoration(
                  labelText: '所属家族 *'.tr,
                  prefixIcon: const Icon(Icons.home_work_outlined),
                ),
                items: families
                    .map((f) => DropdownMenuItem<int>(
                          value: f.id,
                          child: Text(f.name,
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) {
                        setState(() => _selectedTreeId = v);
                        _autoFillGenerationWord();
                      },
                validator: (v) => v == null ? '请选择所属家族'.tr : null,
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => Text('加载家族失败：$e'.tr),
          ),
        ),
      ],
    );
  }

  /// 性别选择器
  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('性别'.tr,
            style: const TextStyle(fontSize: 13, color: AppColors.inkGray)),
        const SizedBox(height: 8),
        SegmentedButton<Gender>(
          segments: [
            ButtonSegment(
                value: Gender.male,
                label: Text('男'.tr),
                icon: const Icon(Icons.male)),
            ButtonSegment(
                value: Gender.female,
                label: Text('女'.tr),
                icon: const Icon(Icons.female)),
            ButtonSegment(
                value: Gender.other,
                label: Text('其他'.tr),
                icon: const Icon(Icons.transgender)),
          ],
          selected: {_gender},
          onSelectionChanged: (s) =>
              setState(() => _gender = s.first),
        ),
      ],
    );
  }

  /// 日期字段
  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: const Icon(Icons.edit_calendar_outlined, size: 18),
        ),
        child: Text(
          date != null ? '${date.year}年${date.month}月${date.day}日'.tr : '未选择'.tr,
          style: TextStyle(
            fontSize: 14,
            color: date != null ? AppColors.inkBlack : AppColors.inkGray,
          ),
        ),
      ),
    );
  }

  /// 分区标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.inkGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.inkBlack,
            ),
          ),
        ],
      ),
    );
  }
}
