import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import '../../../domain/preference_repository.dart';
import 'package:shared/widgets/filter_panel.dart';

/// 保存筛选条件为学习偏好的弹窗
Future<String?> showSavePreferenceDialog(BuildContext context) async {
  final nameCtrl = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('保存为学习偏好'),
      content: TextField(
        controller: nameCtrl,
        decoration: const InputDecoration(
          hintText: '偏好名称（如"北京高考模拟"）',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ctx.mounted) Navigator.of(ctx).pop();
          }),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ctx.mounted) Navigator.of(ctx).pop(nameCtrl.text);
          }),
          child: const Text('保存'),
        ),
      ],
    ),
  );
  nameCtrl.dispose();
  return name;
}

/// 从筛选面板状态构建 PreferenceFilter
PreferenceFilter buildPreferenceFilter(FilterPanelState filterState) {
  return PreferenceFilter(
    years: filterState.selectedYears.toList(),
    regions: filterState.selectedRegions.toList(),
    conceptTags: filterState.selectedConceptTags.toList(),
    types: filterState.selectedExamTypes.toList(),
    knowledgeCards: filterState.selectedKnowledgeCards.toList(),
    questionTypes: filterState.selectedTypes.toList(),
    diffMin: filterState.diffMin,
    diffMax: filterState.diffMax,
    calcMin: filterState.calcMin,
    calcMax: filterState.calcMax,
  );
}

/// 选择已保存的学习偏好弹窗
Future<int?> showLoadPreferenceDialog(BuildContext context, List<PreferenceSummary> presets) async {
  if (presets.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无保存的学习偏好'), behavior: SnackBarBehavior.floating),
      );
    }
    return null;
  }
  final selected = await showDialog<int>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('选择学习偏好'),
      children: presets.map((p) => SimpleDialogOption(
          onPressed: () => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ctx.mounted) Navigator.of(ctx).pop(p.id);
          }),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500)),
              if (p.summary.isNotEmpty)
                Text(p.summary, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        )).toList(),
    ),
  );
  return selected;
}
