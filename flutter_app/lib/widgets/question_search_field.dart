import 'package:flutter/material.dart';

class QuestionSearchField extends StatelessWidget {
  const QuestionSearchField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: '题干关键词、知识点名称或题号',
        filled: true,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          tooltip: '搜索',
          onPressed: () => onSubmitted(controller.text),
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ),
    );
  }
}
