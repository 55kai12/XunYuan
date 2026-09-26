/// 添加 / 编辑事件页
/// 阶段 5：事件表单（类型、标题、日期、地点、描述）
/// 支持从成员详情或时间线页进入
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/hint_text_field.dart';
import '../../../shared/widgets/notepad_editor.dart';
import '../../person/domain/person_providers.dart';
import '../../family/domain/family_providers.dart';
import '../domain/event_providers.dart';

import '../../../core/i18n/i18n.dart';
/// 事件类型配置
class _EventTypeConfig {
  const _EventTypeConfig(this.type, this.label, this.icon, this.color);

  final EventType type;
  final String label;
  final IconData icon;
  final Color color;
}

List<_EventTypeConfig> _eventTypes = [
  _EventTypeConfig(EventType.birth, '出生'.tr, Icons.child_care, AppColors.info),
  _EventTypeConfig(
      EventType.marriage, '结婚'.tr, Icons.favorite, AppColors.cinnabar),
  _EventTypeConfig(
      EventType.death, '去世'.tr, Icons.airline_seat_flat, AppColors.inkGray),
  _EventTypeConfig(
      EventType.migration, '迁徙'.tr, Icons.move_down, AppColors.warning),
  _EventTypeConfig(
      EventType.honor, '功名'.tr, Icons.emoji_events, AppColors.inkGreen),
  _EventTypeConfig(
      EventType.other, '其他'.tr, Icons.event_note, AppColors.inkLightGray),
];

/// 事件编辑页
class EventEditPage extends ConsumerStatefulWidget {
  const EventEditPage({
    super.key,
    this.editId,
    this.initialPersonId,
    this.initialTreeId,
  });

  /// 编辑模式下的事件 ID
  final int? editId;

  /// 新建时预设的成员 ID（从成员详情进入时传入）
  final int? initialPersonId;

  /// 新建时预设的家族 ID
  final int? initialTreeId;

  @override
  ConsumerState<EventEditPage> createState() => _EventEditPageState();
}

class _EventEditPageState extends ConsumerState<EventEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  final _descriptionController = NotepadController();

  EventType _selectedType = EventType.other;
  DateTime? _eventDate;
  int? _selectedPersonId;
  int? _selectedTreeId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPersonId = widget.initialPersonId;
    _selectedTreeId = widget.initialTreeId;

    if (widget.editId != null) {
      _loadEvent();
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 加载事件数据
  Future<void> _loadEvent() async {
    try {
      final repo = ref.read(eventRepositoryProvider);
      final event = await repo.getById(widget.editId!);
      if (!mounted) return;
      if (event == null) {
        _showError('事件不存在或已被删除'.tr);
        context.pop();
        return;
      }
      _selectedType = event.type;
      _titleController.text = event.title;
      _eventDate = event.date;
      _placeController.text = event.place ?? '';
      _descriptionController.load(event.description);
      _selectedPersonId = event.personId;
      _selectedTreeId = event.treeId;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      _showError('加载事件失败：$e'.tr);
      setState(() => _isLoading = false);
    }
  }

  /// 选择日期
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: DateTime(1200),
      lastDate: now,
      helpText: '选择事件日期'.tr,
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  /// 保存
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPersonId == null) {
      _showError('请选择关联成员'.tr);
      return;
    }
    if (_selectedTreeId == null) {
      _showError('请选择所属家族'.tr);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(eventRepositoryProvider);
      if (widget.editId == null) {
        await repo.insert(
          treeId: _selectedTreeId!,
          personId: _selectedPersonId!,
          type: _selectedType,
          title: _titleController.text.trim(),
          date: _eventDate,
          place: _trimOrNull(_placeController.text),
          description: _trimOrNull(_descriptionController.text),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('事件添加成功'.tr)),
        );
        context.pop();
      } else {
        final success = await repo.update(
          id: widget.editId!,
          type: _selectedType,
          title: _titleController.text.trim(),
          date: _eventDate,
          place: _trimOrNull(_placeController.text),
          description: _trimOrNull(_descriptionController.text),
        );
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('事件已保存'.tr)),
          );
          context.pop();
        } else {
          _showError('保存失败：事件不存在或已被删除'.tr);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError('保存失败：$e'.tr);
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    final personsAsync = ref.watch(watchPersonsProvider);
    final familiesAsync = ref.watch(watchFamiliesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editId == null ? '添加事件'.tr : '编辑事件'.tr),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 事件类型选择
                  _buildSectionTitle('事件类型'.tr),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _eventTypes.map((config) {
                      final selected = _selectedType == config.type;
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(config.icon,
                                size: 16,
                                color: selected
                                    ? config.color
                                    : AppColors.inkGray),
                            const SizedBox(width: 4),
                            Text(config.label),
                          ],
                        ),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedType = config.type),
                        selectedColor: config.color.withOpacity(0.15),
                        side: BorderSide(
                          color: selected
                              ? config.color
                              : AppColors.inkLightGray,
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? config.color
                              : AppColors.inkGray,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 关联成员
                  _buildSectionTitle('关联成员'.tr),
                  personsAsync.when(
                    data: (persons) {
                      final filtered = _selectedTreeId != null
                          ? persons
                              .where((p) => p.treeId == _selectedTreeId)
                              .toList()
                          : persons;
                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('暂无成员，请先添加成员'.tr,
                              style: const TextStyle(color: AppColors.error)),
                        );
                      }
                      return DropdownButtonFormField<int>(
                        value: _selectedPersonId,
                        decoration: InputDecoration(
                          labelText: '成员 *'.tr,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        items: filtered
                            .map((p) => DropdownMenuItem<int>(
                                  value: p.id,
                                  child: Text(
                                      '${p.surname}${p.givenName}',
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedPersonId = v;
                            // 自动同步家族
                            final p = persons
                                .where((p) => p.id == v)
                                .firstOrNull;
                            if (p != null) _selectedTreeId = p.treeId;
                          });
                        },
                        validator: (v) =>
                            v == null ? '请选择成员'.tr : null,
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (e, _) => Text('加载成员失败：$e'.tr),
                  ),
                  const SizedBox(height: 20),

                  // 所属家族（如果未预设则显示）
                  if (widget.initialTreeId == null &&
                      widget.editId == null) ...[
                    familiesAsync.when(
                      data: (families) {
                        if (families.length <= 1) {
                          _selectedTreeId ??= families.firstOrNull?.id;
                          return const SizedBox.shrink();
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
                                    child: Text(f.name),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedTreeId = v),
                          validator: (v) =>
                              v == null ? '请选择家族'.tr : null,
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 标题
                  _buildSectionTitle('事件信息'.tr),
                  HintTextField(
                    controller: _titleController,
                    maxLength: 200,
                    label: '事件标题 *'.tr,
                    hint: '例如：高中状元、迁居北京'.tr,
                    prefixIcon: const Icon(Icons.title),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '请输入标题'.tr : null,
                  ),
                  const SizedBox(height: 12),

                  // 日期
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: '日期'.tr,
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        suffixIcon:
                            const Icon(Icons.edit_calendar_outlined, size: 18),
                      ),
                      child: Text(
                        _eventDate != null
                            ? '${_eventDate!.year}年${_eventDate!.month}月${_eventDate!.day}日'.tr
                            : '未选择'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: _eventDate != null
                              ? AppColors.inkBlack
                              : AppColors.inkGray,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 地点
                  HintTextField(
                    controller: _placeController,
                    maxLength: 200,
                    label: '地点'.tr,
                    prefixIcon: const Icon(Icons.place_outlined),
                  ),
                  const SizedBox(height: 12),

                  // 描述（记事本式图文编辑）
                  NotepadEditor(
                    controller: _descriptionController,
                    hintText: '记录事件经过，可插入图片'.tr,
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
                        : Text(widget.editId == null ? '添加事件'.tr : '保存修改'.tr),
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

  Widget _buildSectionTitle(String title) {    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
