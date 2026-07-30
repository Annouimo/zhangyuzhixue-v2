import 'package:flutter/material.dart';
import '../../../domain/preference_repository.dart';
import 'package:shared/widgets/filter_panel.dart';
import 'package:shared/widgets/app_dialog.dart';
import 'package:shared/widgets/app_toast.dart';

/// 保存筛选条件为筛选方案的弹窗
Future<String?> showSavePreferenceDialog(BuildContext context) async {
  return AppDialog.prompt(
    context,
    title: '保存筛选方案',
    label: '方案名称（如“北京高考模拟”）',
    confirmLabel: '保存',
    validator: (value) => value.isEmpty ? '请输入方案名称' : null,
  );
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

/// 选择已保存的筛选方案弹窗
Future<int?> showLoadPreferenceDialog(
  BuildContext context,
  List<PreferenceSummary> presets,
) async {
  if (presets.isEmpty) {
    if (context.mounted) {
      AppToast.info(context, '暂无保存的筛选方案');
    }
    return null;
  }
  final selected = await AppDialog.select<int>(
    context,
    title: '应用筛选方案',
    options: presets
        .map(
          (preset) => AppDialogOption(
            value: preset.id,
            label: preset.name,
            detail: preset.summary.isEmpty ? null : preset.summary,
          ),
        )
        .toList(),
  );
  return selected;
}
