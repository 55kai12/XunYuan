/// 聚焦提示输入框
/// 提示文字（hint）显示在输入框下方，仅在获得焦点时显示
/// 解决标准 TextField 的 hintText 显示在输入框内部的问题
library;

import 'package:flutter/material.dart';

/// 带下方聚焦提示的文本输入框
class HintTextField extends StatefulWidget {
  const HintTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.maxLength,
    this.keyboardType,
    this.maxLines = 1,
    this.obscureText = false,
    this.enabled = true,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.suffixIcon,
    this.prefixIcon,
  });

  /// 标签文字（显示在输入框上方/内部）
  final String label;

  /// 提示文字（聚焦时显示在输入框下方）
  final String? hint;

  /// 控制器
  final TextEditingController? controller;

  /// 验证器
  final String? Function(String?)? validator;

  /// 最大长度
  final int? maxLength;

  /// 键盘类型
  final TextInputType? keyboardType;

  /// 最大行数
  final int maxLines;

  /// 是否隐藏文字（密码）
  final bool obscureText;

  /// 是否启用
  final bool enabled;

  /// 内容变化回调
  final ValueChanged<String>? onChanged;

  /// 点击回调
  final VoidCallback? onTap;

  /// 是否只读
  final bool readOnly;

  /// 后缀图标
  final Widget? suffixIcon;

  /// 前缀图标
  final Widget? prefixIcon;

  @override
  State<HintTextField> createState() => _HintTextFieldState();
}

class _HintTextFieldState extends State<HintTextField> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      focusNode: _focusNode,
      controller: widget.controller,
      validator: widget.validator,
      maxLength: widget.maxLength,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      readOnly: widget.readOnly,
      decoration: InputDecoration(
        labelText: widget.label,
        // 聚焦时显示提示文字在下方，非聚焦时隐藏
        helperText: _hasFocus ? widget.hint : null,
        helperStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          fontSize: 12,
        ),
        // 移除内部 hintText，避免重复
        hintText: null,
        suffixIcon: widget.suffixIcon,
        prefixIcon: widget.prefixIcon,
        // 错误时显示错误文字，覆盖 helperText
        errorMaxLines: 2,
      ),
    );
  }
}
