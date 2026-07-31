import 'package:flutter/material.dart';

class QuestionSearchField extends StatelessWidget {
  const QuestionSearchField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.onChanged,
    this.trailing,
    this.hintText = '搜索题干、知识点或题号',
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: trailing,
        suffixIconConstraints: trailing == null
            ? null
            : const BoxConstraints(minWidth: 72),
      ),
    );
  }
}
